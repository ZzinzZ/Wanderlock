# Giai đoạn Thiết kế & Tiền chuẩn bị — các bước cần làm

> Mục tiêu: từ "ý tưởng đã chốt" → "sẵn sàng viết dòng code đầu tiên của MVP".
> Công nghệ đã chốt tại [06-tech-stack.md](06-tech-stack.md).

---

## Tổng quan 5 nhóm việc

| | Nhóm | Sản phẩm đầu ra |
|---|------|-----------------|
| **A** | Chốt nền tảng dự án | Tên chính thức, phạm vi pilot, danh sách checkpoint |
| **B** | Thiết kế nội dung | Story bible, người dẫn truyện, 1 chương mẫu, 1 tuyến quest |
| **C** | Thiết kế sản phẩm & UX | Luồng màn hình, wireframe, hướng thị giác, art direction fog |
| **D** | Thiết kế kỹ thuật & spike | Schema chốt, spec fog/check-in/sync, 3 spike kiểm chứng |
| **E** | Tiền chuẩn bị hạ tầng | Repo, tài khoản dịch vụ, skeleton project, CI |

> **Thứ tự khuyến nghị:** A → (B, C, D chạy song song) → E.
> **Quan trọng:** làm **spike ở D sớm**, đừng để đến lúc code MVP mới phát hiện fog of war không đủ mượt.

---

## A. Chốt nền tảng dự án

- [ ] **A1. Chốt tên chính thức** + kiểm tra tên miền / tên app store còn trống
- [ ] **A2. Chốt phạm vi pilot**: 1 khu vực nhỏ (đề xuất: **Quận 1 + rìa Chợ Lớn**) thay vì cả TP.HCM — đủ dày để "phủ sáng" có cảm giác
- [ ] **A3. Danh sách 8–12 checkpoint pilot**, mỗi điểm ghi: toạ độ, bán kính, phân loại, độ khó (dễ / ẩn / bí mật)
- [ ] **A4. Chốt 1 câu "trải nghiệm vàng"** — cảnh 60 giây mà mọi thứ phải phục vụ (vd: *đi bộ tới Bưu điện Thành phố, map bừng sáng, người dẫn truyện lên tiếng*)

**Xong khi:** có file `content/checkpoints.json` bản nháp + tên dự án.

---

## B. Thiết kế nội dung (khâu tốn công nhất — bắt đầu sớm)

- [ ] **B1. Story bible**: bối cảnh, giọng kể, ranh giới (bao nhiêu phần lịch sử thật / bao nhiêu hư cấu)
- [ ] **B2. Thiết kế người dẫn truyện**: là ai, vì sao đồng hành, nhớ gì về hành trình người chơi
- [ ] **B3. Chuẩn định dạng chương truyện** (JSON: node, thoại, lựa chọn, media) — chốt cùng D
- [ ] **B4. Viết 1 chương mẫu hoàn chỉnh** cho 1 địa điểm (đề xuất: Bảo tàng Chứng tích Chiến tranh) — dùng để test cảm xúc
- [ ] **B5. Thiết kế 1 tuyến quest** xuyên 4–6 checkpoint, có mở–thân–kết
- [ ] **B6. Đối chiếu tính chính xác lịch sử** — nhạy cảm, cần nguồn đáng tin
- [ ] **B7. Quy trình soạn nội dung**: nháp bằng Claude API → người biên tập → duyệt

**Xong khi:** đọc thử chương mẫu thấy "muốn đi tiếp".

---

## C. Thiết kế sản phẩm & UX

- [ ] **C1. Sơ đồ luồng chính**: mở app → thấy map tối → di chuyển → vào bán kính → check-in → mở khóa → nội dung theo lens
- [ ] **C2. Thiết kế bộ chuyển lăng kính** (Lens Switcher) — phải đổi **tức thì**, cùng một bản đồ, trạng thái giữ nguyên
- [ ] **C3. Onboarding**: không ép chọn chế độ; mặc định Fog of War + mời thử Story ở điểm đầu tiên
- [ ] **C4. Wireframe 6 màn hình lõi**: Map · Checkpoint detail · Story player · Quest list/detail · Bộ sưu tập · Bản đồ ký ức
- [ ] **C5. Art direction Fog of War**: sương mù trông ra sao, hiệu ứng lúc "bừng sáng" (đây là khoảnh khắc bán được sản phẩm)
- [ ] **C6. Hệ thiết kế cơ bản**: màu, chữ, icon, thiết kế tem
- [ ] **C7. Trạng thái lỗi/biên**: mất GPS, sai lệch vị trí, offline, gần-nhưng-chưa-đủ-gần

**Xong khi:** có prototype bấm được (Figma) cho "trải nghiệm vàng" A4.

---

## D. Thiết kế kỹ thuật & Spike kiểm chứng

### D1. Chốt thiết kế
- [ ] Chốt schema Postgres/PostGIS + chính sách RLS
- [ ] Spec **thuật toán Fog of War**: lưu vệt đi thế nào, đơn giản hoá ra sao, vẽ ra sao
- [ ] Spec **check-in & chống gian lận**: điều kiện hợp lệ, xác thực server-side, fallback QR/câu đố
- [ ] Spec **đồng bộ offline**: cái gì cache, giải quyết xung đột thế nào
- [ ] Chốt định dạng JSON chương truyện (cùng B3)

### D2. Ba spike bắt buộc (làm trước, mỗi cái vài ngày)
- [ ] **Spike 1 — Fog of War**: vẽ vệt đi + mask trên MapLibre, đo FPS sau ~2 giờ đi bộ mô phỏng
- [ ] **Spike 2 — Geofence nền + pin**: đo hao pin khi bật nền 1 buổi; kiểm tra bắt đúng lúc vào bán kính
- [ ] **Spike 3 — Độ chính xác GPS thực địa**: đi thật quanh Quận 1, ghi sai số giữa nhà cao tầng → quyết định bán kính & khi nào cần QR

> Nếu Spike 1 hoặc 3 thất bại → phải điều chỉnh thiết kế **trước khi** làm MVP.

**Xong khi:** 3 spike có kết luận bằng số, không phải phỏng đoán.

---

## E. Tiền chuẩn bị hạ tầng

- [ ] **E1. Khởi tạo git repo** + cấu trúc thư mục (`app/`, `content/`, `supabase/`, `docs/`, `spikes/`)
- [ ] **E2. Tạo tài khoản dịch vụ**: Supabase, nhà cung cấp tile, Firebase (FCM), PostHog, Apple/Google developer
- [ ] **E3. Skeleton Flutter app** chạy được + hiển thị bản đồ trống
- [ ] **E4. Supabase project** + migration đầu tiên + script seed từ `content/*.json`
- [ ] **E5. Quy ước dự án**: nhánh git, commit, lint, quy tắc đặt tên
- [ ] **E6. CI cơ bản**: build + test tự động
- [ ] **E7. Quản lý bí mật**: `.env`, không commit khoá

**Xong khi:** `flutter run` mở ra bản đồ tối, kết nối được Supabase.

---

## Điều kiện để chuyển sang giai đoạn MVP

Tất cả phải đạt:

1. ✅ Tên + danh sách checkpoint pilot đã chốt
2. ✅ 1 chương truyện mẫu đọc thấy hay
3. ✅ Prototype Figma cho "trải nghiệm vàng"
4. ✅ 3 spike kỹ thuật có kết luận khả thi
5. ✅ Repo + Supabase + skeleton app chạy được

---

## Nên bắt đầu từ đâu ngay hôm nay

Ba việc song song, không phụ thuộc nhau:

1. **A3** — liệt kê 8–12 checkpoint pilot (nhanh, mở khoá mọi thứ khác)
2. **B4** — viết chương truyện mẫu (tốn công nhất, bắt đầu sớm nhất)
3. **Spike 1** — thử fog of war trên MapLibre (rủi ro kỹ thuật lớn nhất)
