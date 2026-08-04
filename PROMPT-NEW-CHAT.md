# Prompt mở chat mới

Dán nguyên khối dưới đây vào chat mới. Nếu thư mục làm việc không phải `D:\Project\Idea\Wanderlock`, sửa đường dẫn ở dòng đầu.

---

Dự án tại `D:\Project\Idea\Wanderlock`. Trước khi trả lời bất cứ điều gì, hãy đọc tài liệu để nắm context — **đừng đoán, đừng tự suy ra từ tên file**.

**Đọc theo thứ tự:**
1. `CLAUDE.md` — quy tắc bắt buộc
2. `docs/00-overview.md` — mục lục và tổng quan
3. `docs/08-scope.md` — scope v1 đã chốt
4. `docs/09-art-direction.md` — hợp đồng thiết kế
5. `docs/11-foundation-plan.md` — đang ở phase nào, Definition of Done
6. `docs/12-engineering-guide.md` — cấu trúc thư mục và quy ước code

Đọc thêm khi cần: `03-architecture.md` (mô hình dữ liệu), `06-tech-stack.md` (công nghệ), `10-libraries.md` (thư viện), `02-mechanics.md` + `04-modes.md` (cơ chế game).

**Tóm tắt để bạn định hướng khi đọc** (tài liệu mới là nguồn đúng, phần này chỉ để bạn biết mình đang đọc gì):

- Sản phẩm: app bản đồ tham quan game hoá. Mỗi địa điểm là một checkpoint bị khoá, phải **thực sự đến nơi** (xác thực GPS) mới mở khoá. Pilot: Quận 1 + rìa Chợ Lớn, TP.HCM. App song ngữ Việt–Anh.
- Ý tưởng lõi: **tách tầng mở khoá khỏi tầng trải nghiệm**. Một lần đến mở khoá cho **mọi** chế độ chơi. Chế độ chỉ đổi *cách trải nghiệm*, không đổi *kết quả mở khoá*.
- v1 có **5 lăng kính**: Fog of War · Story · Quest · Sưu tầm · Tùy chỉnh hành trình. (Xã hội đã hoãn sang v1.5 — đừng thêm vào.)
- Công nghệ đã chốt: **Flutter + MapLibre + Supabase/PostGIS + Drift**. Chương truyện dùng JSON tự định nghĩa.
- Thiết kế đã chốt: neumorphism nhẹ trên nền kem, bo góc lớn, pastel tươi. Luật: **neumorphism cho bề mặt, khối đặc cho hành động** — không dùng bóng mềm trên bản đồ hay trên nút hành động chính. Font: **Be Vietnam Pro** (UI) + **Baloo 2** (tiêu đề), đóng gói vào app.
- **Địa danh dùng ảnh thật**, không dùng illustration. Illustration chỉ dành cho icon, nhân vật dẫn truyện, màn trống. Mọi ảnh phải qua cùng một preset xử lý và phải rõ bản quyền.

**Quy tắc bất khả xâm phạm:**
1. Một tầng mở khoá duy nhất — mọi lăng kính đọc chung `visit_state`; chỉ feature `unlock` được ghi vào đó.
2. Không tin client — check-in xác thực ở server.
3. Không viết cứng màu, bo góc, cỡ chữ, thời lượng animation — lấy từ design token.
4. Không thêm tính năng ngoài scope v1.
5. Ưu tiên thư viện có sẵn thay vì tự build. Ngoại lệ tự viết: Fog of War, tầng mở khoá, chống gian lận.
6. Dùng Context7 lấy tài liệu thư viện đúng phiên bản, không code theo trí nhớ về API.

**Trạng thái hiện tại:** chưa có dòng code nào. Đã xong toàn bộ tài liệu nền tảng. Việc kế tiếp là **phase F0** (khởi tạo git, cấu trúc thư mục, lint, CI) trong `docs/11-foundation-plan.md`.

**Còn treo, cần chủ dự án quyết:**
- Tên chính thức (đang dùng codename Wanderlock; phương án đề xuất: **Tem**)
- Style bản đồ tuỳ biến (chốt ở phase F3)
- Gom 12 ảnh địa danh có bản quyền rõ ràng + dựng preset xử lý ảnh

**Cách làm việc:** trao đổi bằng tiếng Việt; code và commit bằng tiếng Anh theo từ điển thuật ngữ trong `docs/12-engineering-guide.md`. Trước khi báo xong bất kỳ việc gì, đối chiếu mục "Definition of Done áp dụng cho mọi task" ở cuối `docs/11-foundation-plan.md`.

Đọc xong, tóm tắt lại cho tôi bạn hiểu dự án đang ở đâu và đề xuất việc kế tiếp — **chưa viết code cho tới khi tôi xác nhận**.
