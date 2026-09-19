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

## Sửa danh sách địa điểm

**Danh sách 12 điểm chưa chốt.** Thêm, sửa, hay bỏ một điểm đều là sửa
`checkpoints.json` rồi seed lại — không đụng mã nguồn.

| Việc | Làm gì |
|------|--------|
| Sửa toạ độ, bán kính, tên, địa chỉ | Sửa mục đó rồi seed lại. Upsert ghi đè |
| Thêm điểm | Thêm mục mới. Toạ độ phải `verified: true` — dùng [../tool/coord_verify](../tool/coord_verify) |
| Gắn ảnh marker | Điền `photoUrl`, sau khi ảnh đã có dòng trong `image-licenses.md` |
| Đánh dấu cần QR | Đặt `requiresQrFallback: true` — kết luận của spike S3 |
| **Bỏ một điểm** | Xoá khỏi file **rồi chạy `--prune`**. Xem cảnh báo dưới |

### Bỏ một điểm: vì sao phải có thêm một bước

Seed là **upsert**, nên xoá một mục khỏi file chỉ khiến nó *thôi được ghi* —
dòng cũ nằm lại trong database vĩnh viễn và điểm đó vẫn hiện trên bản đồ. Chạy
seed thường sẽ **báo cáo** những điểm thừa như vậy nhưng không tự xoá.

```
dart run tool/seed_content.dart --prune
```

Xoá một checkpoint sẽ **CASCADE sang `visit_state`** — tức là xoá luôn lịch sử
mở khoá của người chơi ở điểm đó, thứ duy nhất không dựng lại được. Nên
`--prune` **từ chối** động vào điểm đã có người ghé, trừ khi thêm `--force`.

Thêm `--dry-run` để xem trước mà không ghi gì.

> Nếu chỉ muốn **đổi tên hiển thị**, sửa `name` — đừng đổi `id`. Đổi `id` bị
> hiểu là xoá điểm cũ và thêm điểm mới, và sẽ mất lượt mở khoá.

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
