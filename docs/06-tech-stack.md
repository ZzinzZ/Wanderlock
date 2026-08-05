# Ngăn xếp công nghệ (ĐÃ CHỐT cho MVP)

> Ngày chốt: 2026-08-04 · Phạm vi: MVP (TP.HCM pilot)
> Nguyên tắc chọn: **1 codebase · geospatial mạnh · dựng nhanh · dễ thoát (không khoá chặt)**

---

## 1. Bảng quyết định

| Lớp | **CHỐT** | Lý do | Đường thoát |
|-----|----------|-------|-------------|
| App | **Flutter (Dart)** | 1 codebase iOS+Android; render custom mượt → hợp fog of war vẽ tay | — |
| Bản đồ | **MapLibre GL** (`maplibre_gl`) | Mã nguồn mở, không phí bản quyền, API gần giống Mapbox | Đổi sang Mapbox chỉ tốn ít công (cùng gốc GL) |
| Tile / style | Nhà cung cấp tile bên thứ 3 (MapTiler / Protomaps) + style tối tự thiết kế | Không tự vận hành hạ tầng tile giai đoạn đầu | Self-host tile khi lượng dùng lớn |
| Fog of War | **Overlay tự vẽ trên MapLibre** (mask + geometry vùng đã sáng) | Client-side, không tốn backend | — |
| Định vị | **`geolocator`** + geofencing nền của OS | Đủ cho MVP, không phí license | Nâng lên `flutter_background_geolocation` (có phí) nếu cần chạy nền mạnh hơn |
| Backend | **Supabase** (Postgres + **PostGIS** + Auth + Realtime + Storage) | PostGIS xử lý truy vấn không gian rất mạnh; quan hệ hợp cho quest/tem; dựng nhanh | Postgres là chuẩn mở → tự host được |
| Local DB / offline | **Drift (SQLite)** đồng bộ 2 chiều với Supabase | Chơi được khi mất mạng | — |
| Nội dung truyện | **Định dạng JSON tự định nghĩa** (node + lựa chọn) | Đơn giản, không phụ thuộc runtime bên ngoài; đủ cho chương truyện chủ yếu tuyến tính | Chuyển sang **Ink** nếu phân nhánh phức tạp (xem Rủi ro) |
| Media | **Supabase Storage** | Ít thành phần rời rạc ở MVP | Cloudflare R2 khi chi phí egress thành vấn đề |
| CMS | **Chưa dùng** — nội dung là file JSON trong repo + script seed | Version-control được, không dựng thêm hệ thống | **Directus** trên chính Postgres ở Giai đoạn 3 |
| Soạn nội dung | **Claude API** (Opus/Sonnet 5) hỗ trợ viết nháp chương truyện | Tăng tốc khâu tốn công nhất | Biên tập người vẫn là bắt buộc |
| Push | FCM | Tiêu chuẩn | — |
| Analytics | PostHog | Đo giữ chân/phễu | — |

### Thay đổi so với đề xuất trước (và lý do)
- **Mapbox → MapLibre**: tránh phụ thuộc pricing thương mại ngay từ đầu; chi phí đổi ngược lại rất thấp.
- **Ink → JSON tự định nghĩa**: bản port Ink cho Dart/Flutter không phải hạng nhất; MVP chưa cần phân nhánh sâu. Giữ Ink làm phương án dự phòng.
- **Directus → hoãn**: MVP chỉ 5–10 checkpoint, dùng file + seed script nhanh và gọn hơn.
- **R2 → hoãn**: gộp về Supabase Storage cho bớt mảnh ghép.

---

## 2. Sơ đồ kiến trúc kỹ thuật

```
┌──────────────────────── FLUTTER APP ────────────────────────┐
│  UI: Map (MapLibre) + Lens Switcher + Story Player           │
│  ─────────────────────────────────────────────────────────   │
│  Lens Layer:  Fog │ Story │ Quest │ Collect │ Social          │
│                   ▲ (chỉ ĐỌC)                                │
│  Unlock Layer:  VisitState  ◄── Check-in Service             │
│                   ▲                    ▲                     │
│  Local: Drift/SQLite          geolocator + geofence + QR      │
└───────────────────────────┬─────────────────────────────────┘
                            │  đồng bộ khi có mạng
┌───────────────────────────▼─────────────────────────────────┐
│                        SUPABASE                              │
│  Auth │ Postgres + PostGIS │ Realtime │ Storage │ RLS         │
│  bảng: checkpoints · visit_state · stories · quests · stamps  │
│         quest_steps · quest_progress · itineraries            │
└──────────────────────────────────────────────────────────────┘
        ▲ seed từ file JSON (repo)   ▲ Claude API (soạn nháp, offline tool)
```

---

## 3. Schema (Postgres + PostGIS)

> Bản thi hành nằm ở [`supabase/migrations/`](../supabase/migrations/) — đó mới
> là nguồn đúng. Mục này tóm tắt để đọc nhanh.

```sql
checkpoints (
  id, name, geom geography(Point), radius_m,
  category, requires_qr_fallback, address, photo_url
)

-- TẦNG NỀN: nguồn sự thật duy nhất, mọi lens đọc chung
visit_state (
  user_id, checkpoint_id,
  status,            -- unknown | revealed | visited
  visited_at, verified_by,     -- gps | qr | quiz
  PRIMARY KEY (user_id, checkpoint_id)
)

fog_trail (user_id, geom geography, recorded_at)  -- vệt đã đi (Fog of War)
narrators (id, name, bio, portrait_url)
stories (id, checkpoint_id, narrator_id, title, nodes jsonb)
quests (id, title, summary, reward)
quest_steps (quest_id, checkpoint_id, position)
quest_progress (user_id, quest_id, started_at, reward_claimed_at)
stamps (id, checkpoint_id, art_url)
itineraries (id, user_id, title)
itinerary_items (itinerary_id, checkpoint_id, position)
```

**Quy tắc bất biến:** không lens nào được lưu trạng thái mở khóa riêng — tất cả suy ra từ `visit_state`.

### 3.1 Ba hệ quả của quy tắc trên (đã sửa so với bản phác thảo đầu)

1. **`quest_progress` không có `done_steps`.** Bản phác thảo đầu có, và nó phá
   thẳng quy tắc: hoàn thành một checkpoint sẽ phải ghi hai nơi, rồi hai nơi
   lệch nhau. Tiến độ quest suy ra bằng cách giao `quest_steps` với
   `visit_state`. Bảng chỉ giữ thứ **không suy được** — lúc bắt đầu, lúc nhận thưởng.
2. **Không lưu quyền sở hữu tem.** Một con tem thuộc về bạn đúng khi checkpoint
   của nó đã ghé. `stamps` chỉ mô tả con tem, không mô tả ai có nó.
3. **`footprints` không tồn tại ở v1.** Nó thuộc lăng kính Xã hội, đã hoãn sang
   v1.5 ([08-scope.md](08-scope.md)). Bảng đã tồn tại là bảng sẽ có người viết
   code dựa vào.

### 3.2 Hai tầng bảo vệ `visit_state`

`visit_state` được cấp **`SELECT` và không gì khác** cho `authenticated`, đồng
thời **không có policy insert/update/delete nào**. Client dù có session hợp lệ
cũng bị chặn hai lần: một ở tầng quyền, một ở tầng policy. Chỉ edge function
xác thực check-in, chạy bằng `service_role`, mới ghi được.

Đây là cách biến "không tin client" từ một điều ước hẹn khi review code thành
ràng buộc của chính database.

> ⚠️ Bật RLS **không đủ**. Postgres xét `GRANT` trước, chỉ khi động từ đã được
> phép mới xét đến policy. Thiếu `GRANT` thì mọi thứ bị chặn — kể cả bảng nội
> dung ai cũng phải đọc được. Nhìn như đang an toàn, thực ra là app hỏng.
Bật **RLS** cho mọi bảng có `user_id`. Check-in phải qua **Edge Function xác thực server-side** (không tin client).

---

## 4. Rủi ro kỹ thuật & hướng xử lý

| Rủi ro | Mức | Xử lý |
|--------|:---:|-------|
| Fog of war vẽ nhiều geometry → tụt FPS | Cao | Spike sớm; đơn giản hoá vệt đi (Douglas–Peucker), gộp vùng, giới hạn số đỉnh |
| GPS lệch giữa nhà cao tầng Quận 1 | Cao | Bán kính linh hoạt theo độ chính xác; fallback QR / câu đố quan sát |
| Giả GPS (mock location) | Cao | Cờ `isMocked`, kiểm tra tốc độ di chuyển bất thường, xác thực check-in ở server |
| Chạy nền tốn pin | TB | Geofence của OS thay vì polling liên tục; giảm tần suất khi đứng yên |
| Nội dung story tốn công | Cao | Ít điểm – chất lượng cao; Claude API soạn nháp, người biên tập |
| Port Ink cho Dart chưa trưởng thành | TB | Đã tránh: dùng JSON tự định nghĩa ở MVP |

---

## 5. Việc cần kiểm chứng trước khi code thật (spike)

Xem [07-design-phase-plan.md](07-design-phase-plan.md) — mục **Giai đoạn D**.
