# Wanderlock — hướng dẫn cho agent

App bản đồ tham quan được game hoá: mỗi địa điểm là một checkpoint bị khóa, phải **thực sự đến nơi** để mở khóa — và một lần đến mở khóa cho **mọi** chế độ chơi.

Pilot: Quận 1 + rìa Chợ Lớn, TP.HCM. Trạng thái: **chưa có mã nguồn**, đang ở giai đoạn nền tảng.

## Đọc gì trước khi làm

| Việc bạn định làm | Đọc trước |
|-------------------|-----------|
| Bất cứ việc gì | [docs/00-overview.md](docs/00-overview.md) |
| Viết mã, tạo file | [docs/12-engineering-guide.md](docs/12-engineering-guide.md) |
| Làm giao diện | [docs/09-art-direction.md](docs/09-art-direction.md) |
| Thêm tính năng | [docs/08-scope.md](docs/08-scope.md) |
| Chọn thư viện | [docs/10-libraries.md](docs/10-libraries.md) |
| Biết đang ở đâu trong lộ trình | [docs/11-foundation-plan.md](docs/11-foundation-plan.md) |

## Quy tắc bất khả xâm phạm

1. **Một tầng mở khóa duy nhất.** Mọi lăng kính đọc chung `visit_state`. Chỉ feature `unlock` được ghi vào đó. Không lăng kính nào lưu trạng thái mở khóa riêng.
2. **Không tin client.** Check-in xác thực ở server. Client chỉ gửi yêu cầu.
3. **Không viết cứng giá trị thiết kế.** Màu, bo góc, cỡ chữ, thời lượng animation đều lấy từ `design/tokens/`.
4. **Không mở rộng ngoài scope v1** (5 lăng kính: Fog · Story · Quest · Sưu tầm · Tùy chỉnh hành trình). Xã hội đã hoãn sang v1.5 — đừng thêm vào.
5. **Ưu tiên thư viện có sẵn** thay vì tự build. Ngoại lệ tự viết: Fog of War, tầng mở khóa, logic chống gian lận.
6. **Dùng Context7 để lấy tài liệu thư viện** đúng phiên bản — không code theo trí nhớ về API.

## Kiến trúc — một câu

**Tầng nền** (`visit_state`, dùng chung, là nguồn sự thật) tách khỏi **tầng lăng kính** (cách hiển thị, chọn được, đổi được). Đổi lăng kính không đổi trạng thái mở khóa.

Trong mã, luật này được bảo vệ bằng: mọi feature được phụ thuộc `unlock`, nhưng `unlock` không phụ thuộc feature nào, và các feature không import chéo nhau.

## Ngôn ngữ

- Trao đổi với chủ dự án: **tiếng Việt**
- Mã nguồn, tên biến, commit: **tiếng Anh** — dùng đúng từ điển thuật ngữ ở [docs/12-engineering-guide.md](docs/12-engineering-guide.md)
- Chuỗi hiển thị: tiếng Việt, đặt trong l10n
- Mọi font/chuỗi phải kiểm tra dấu tiếng Việt: `ế ỡ ộ ữ ẫ`

## Trước khi báo xong

Đối chiếu mục **"Definition of Done áp dụng cho mọi task"** ở cuối [docs/11-foundation-plan.md](docs/11-foundation-plan.md).
