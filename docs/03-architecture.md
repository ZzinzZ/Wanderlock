# Kiến trúc 2 tầng & Mô hình dữ liệu

---

## Nguyên lý: Tách "trạng thái mở khóa" khỏi "chế độ trải nghiệm"

App gồm **2 tầng tách biệt**:

| Tầng | Vai trò | Đặc điểm |
|------|---------|----------|
| **Tầng nền — Unlock Layer** | Sự thật chung: bạn đã đến đâu | Duy nhất, dùng chung, không đổi theo chế độ |
| **Tầng trải nghiệm — Lens Layer** | Cách bạn "nhìn" và "chơi" | Chọn được, đổi bất cứ lúc nào |

> Mọi chế độ đọc/ghi chung **một** bảng trạng thái checkpoint → **single source of truth**.
> Đến một địa điểm ở bất kỳ chế độ nào → checkpoint mở khóa cho *tất cả* chế độ.

---

## Sơ đồ luồng

```
        [ Người dùng đến địa điểm thật ]
                     │
                     ▼
         ┌───────────────────────┐
         │   Xác thực GPS / QR    │   ← chống gian lận
         └───────────┬───────────┘
                     ▼
         ┌───────────────────────┐
         │   UNLOCK LAYER         │   ← ghi 1 lần, dùng chung
         │   checkpoint = "đã ghé"│
         └───────────┬───────────┘
                     │  (mọi chế độ đọc chung)
        ┌────────────┼────────────┬────────────┬───────────┐
        ▼            ▼            ▼            ▼           ▼
   [Fog of War]  [Story]      [Quest]     [Sưu tầm]   [Xã hội]
     làm sáng    mở chương    tick tuyến   nhận tem    ghi dấu
       ô map      truyện       nhiệm vụ                cộng đồng
```

---

## Mô hình dữ liệu (bản phác thảo)

### Checkpoint (địa điểm)
```
Checkpoint {
  id
  name
  location { lat, lng }
  radius            // bán kính xác thực đến nơi (m)
  category          // museum | landmark | food | art | hidden | ...
  difficulty        // easy | hidden | secret
  district / area   // để xử lý "vùng khóa"
  content_refs {    // nội dung cho từng lăng kính
    story_id
    stamp_id
    quiz_id
  }
}
```

### VisitState (trạng thái mở khóa — TẦNG NỀN, dùng chung)
```
VisitState {
  user_id
  checkpoint_id
  status            // unknown | revealed | visited
  visited_at
  verify_method     // gps | qr | quiz
}
```
> Đây là bảng **quan trọng nhất**. Tất cả chế độ chỉ đọc `status` từ đây.

### Lens / Mode (chế độ trải nghiệm)
```
Lens {
  id                // fog | story | quest | collect | social
  label
  render_rule       // cách vẽ map/UI dựa trên VisitState
}
```
> Lens **không lưu trạng thái mở khóa riêng** — chỉ diễn giải VisitState theo cách của nó.

### Ví dụ dữ liệu phụ theo từng lens
- **Story:** `StoryChapter { checkpoint_id, script, narrator, media }`
- **Quest:** `Quest { id, title, checkpoint_sequence[], reward }` + `QuestProgress { user_id, quest_id, started_at, reward_claimed_at }`
  > `QuestProgress` **không** giữ danh sách bước đã xong. Đó là bản sao thứ hai
  > của trạng thái mở khoá; tiến độ suy ra từ `visit_state`. Xem
  > [06-tech-stack.md §3.1](06-tech-stack.md).
- **Sưu tầm:** `Stamp { checkpoint_id, art }` (đã mở khi VisitState = visited)
- **Xã hội:** `Footprint { checkpoint_id, user_id, message, first_visit_flag }`

---

## Vì sao kiến trúc này mạnh (kỹ thuật)

1. **Gọn:** thêm chế độ mới = thêm một Lens đọc chung VisitState, không đụng lõi.
2. **Nhất quán:** không có mâu thuẫn "mở ở chế độ này, khóa ở chế độ kia".
3. **Đồng bộ dễ:** chỉ cần đồng bộ một bảng VisitState giữa thiết bị/cloud.
4. **Mở rộng đa thành phố:** Checkpoint gắn theo area/city, dữ liệu phân vùng tự nhiên.

---

## Vấn đề kỹ thuật cần giải (mở)

- **Chống gian lận GPS giả (spoofing):** kết hợp GPS + bán kính + (tùy chọn) QR tại điểm / câu đố quan sát (E2).
- **Độ chính xác GPS đô thị** (nhà cao tầng che tín hiệu): cần bán kính linh hoạt + fallback.
- **Chế độ offline:** cache bản đồ + đồng bộ VisitState khi có mạng.
- **Nguồn nội dung story:** biên soạn thủ công vs. cộng đồng đóng góp vs. hỗ trợ AI.
- **Pin & dữ liệu:** fog of war chạy nền tốn pin — cần tối ưu.
