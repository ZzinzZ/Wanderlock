# Spike kỹ thuật

Mục đích: **biết trước điều gì sẽ hỏng, trước khi xây lên trên.**

> ⛔ Mã trong thư mục này **không được** đưa vào `app/lib/`. Spike là để trả lời
> câu hỏi rồi vứt đi, không phải bản nháp của mã sản phẩm.

Ba spike chạy **song song**, bắt đầu ngay sau F0. Chúng không nằm trong đường
găng, nhưng kết quả có quyền **chặn F3 và F4** — nếu một spike thất bại thì phải
sửa thiết kế trước, không được xây tiếp.

| Spike | Câu hỏi | Kết luận phải có |
|-------|---------|------------------|
| **S1 — Fog of War** | Vẽ vệt đi + mask trên MapLibre, sau 2 giờ đi bộ mô phỏng còn mượt không? | Số **FPS đo được** ở mốc 30/60/120 phút trên máy tầm trung → "đạt" hoặc "phải đổi cách vẽ" |
| **S2 — Geofence & pin** | Chạy nền một buổi tốn bao nhiêu pin? Có bắt đúng lúc vào bán kính không? | **%pin/giờ đo được** + tỉ lệ bắt đúng trên ≥ 20 lần vào/ra vùng |
| **S3 — GPS thực địa** | Sai số GPS giữa nhà cao tầng Quận 1 là bao nhiêu? | Bảng sai số tại ≥ 8 điểm thật → **bán kính nên đặt bao nhiêu**, điểm nào bắt buộc cần QR |

## Cách ghi chép

Mỗi spike một thư mục `s1-fog/`, `s2-geofence/`, `s3-gps-field/`, bên trong có
`NOTES.md` gồm: thiết lập đo (máy gì, điều kiện gì), **số liệu thô**, và kết luận
một câu.

Kết luận phải **bằng số**, không phải cảm nhận. "Có vẻ mượt" không đóng được spike.
