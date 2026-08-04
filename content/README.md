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
