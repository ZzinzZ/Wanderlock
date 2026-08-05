# Nội dung pilot

Nguồn sự thật của nội dung là **file trong thư mục này**, không phải database.
Supabase được nạp bằng script seed đọc từ đây (xem F2 trong
[../docs/11-foundation-plan.md](../docs/11-foundation-plan.md)). Nhờ vậy nội dung
được version-control và seed lại được từ đầu.

Chưa dùng CMS ở v1 — 8–12 checkpoint thì file JSON gọn hơn.

## Cấu trúc dự kiến

```
content/
├─ checkpoints.json      # 8–12 checkpoint: toạ độ, bán kính, phân loại
├─ stories/              # 1 chương truyện / checkpoint (JSON tự định nghĩa)
├─ quests.json           # 1 tuyến quest xuyên 4–6 checkpoint
├─ stamps.json           # 1 tem / checkpoint
└─ image-licenses.md     # ⚠️ BẮT BUỘC — xem bên dưới
```

## Định dạng chương truyện

Xem [stories/_format-example.json](stories/_format-example.json) — file mẫu
minh hoạ đủ mọi loại node. File bắt đầu bằng `_` được seed script bỏ qua.

Một chương gồm phần đầu (`id`, `checkpointId`, `narratorId`, `title`,
`coverImage`, `estimatedMinutes`) và một danh sách `nodes` **tuyến tính**:

| Node | Dùng khi |
|------|----------|
| `narration` | Giọng người dẫn truyện, không gắn nhân vật — mô tả, bối cảnh, chuyển cảnh |
| `speech` | Một nhân vật lên tiếng. `speakerId` trỏ tới id trong content, **không phải tên hiển thị** — đổi tên nhân vật thì chương truyện không hỏng |
| `image` | Ảnh thật, tỉ lệ 16:9. Địa danh không bao giờ dùng illustration |

**Không có lựa chọn, không phân nhánh.** Câu chuyện phân mảnh nằm ở v2 theo
[../docs/08-scope.md](../docs/08-scope.md). Một định dạng cho phép rẽ nhánh
ngay bây giờ sẽ mời gọi nội dung phụ thuộc vào nó, và người viết sẽ tới trước
người làm.

**Trình đọc rất khắt khe.** Sai chính tả một `type` là báo lỗi kèm đúng tên
chương và số thứ tự node, chứ không âm thầm bỏ qua đoạn đó — người phát hiện
ra sẽ là độc giả đang đứng trước một di tích, chỗ tệ nhất để biết.

`estimatedMinutes` hiện ra trước khi mở chương: người đang đứng ngoài nắng
xứng đáng được biết mình sắp cam kết bao lâu. Pilot nhắm 2–4 phút.

## Bản quyền ảnh — bắt buộc

[../docs/09-art-direction.md](../docs/09-art-direction.md) chốt: địa danh dùng
**ảnh thật**, và **mỗi ảnh phải ghi lại nguồn cùng giấy phép**. Không lấy ảnh từ
kết quả tìm kiếm.

`image-licenses.md` phải có đủ mỗi ảnh một dòng:

| Tệp | Địa điểm | Nguồn | Giấy phép | Yêu cầu ghi nguồn | Ngày lấy |
|-----|----------|-------|-----------|-------------------|----------|

Ảnh không có dòng tương ứng thì **không được đưa vào app**.

## Xử lý ảnh

Mọi ảnh phải qua **cùng một preset** (cân màu ấm nhẹ, giảm bão hoà, hạt film rất
nhẹ, tỉ lệ khung cố định theo vị trí dùng). Lệch tông một tấm là hỏng cả hệ thống
— xem mục 7.1 của art direction. Preset chưa dựng; đây là việc còn treo.
