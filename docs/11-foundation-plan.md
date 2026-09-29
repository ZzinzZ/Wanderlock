# Kế hoạch nền tảng dự án — Phase & Definition of Done

> Phạm vi: từ thư mục rỗng → **lát cắt dọc chạy được trên máy thật**, chứng minh kiến trúc 2 tầng hoạt động.
> Mỗi phase chỉ được coi là xong khi **toàn bộ mục DoD đều kiểm chứng được**, không phải "cảm thấy xong".

---

## Nguyên tắc chung

1. **DoD phải quan sát được.** Mỗi mục là một việc ai đó bấm/chạy/nhìn thấy được, không phải mô tả cảm tính.
2. **Không nhảy phase.** Phase sau chỉ bắt đầu khi phase trước đã đóng.
3. **Mỗi phase kết thúc bằng một commit gắn tag** `foundation-f0` … `foundation-f5`.

---

## Bảng tổng quan

| Phase | Tên | Đầu ra chính | Chặn phase nào |
|-------|-----|--------------|----------------|
| **F0** | Kho mã & quy ước | repo, lint, CI, quy ước | tất cả |
| **F1** | Skeleton app | app chạy, theme, routing | F3 |
| **F2** | Nền dữ liệu | Supabase + Drift + seed | F4 |
| **F3** | Bản đồ nền | map đã nhuộm + marker | F5 |
| **F4** | Tầng mở khóa | check-in + sync + chống gian lận | F5 |
| **F5** | Lát cắt dọc | Fog lens + chuyển lăng kính | — |

---

## F0 — Kho mã & quy ước

**Mục tiêu:** ai clone về cũng code ra cùng một kiểu.

**Đầu ra**
- Repo git khởi tạo, nhánh `main` được bảo vệ
- Cấu trúc thư mục theo [12-engineering-guide.md](12-engineering-guide.md)
- `.gitignore`, `.env.example`, không có bí mật nào trong lịch sử commit
- `analysis_options.yaml` bật lint nghiêm
- CI: chạy `format --set-exit-if-changed`, `analyze`, `test` trên mỗi PR
- `CLAUDE.md` + quy ước commit

**Definition of Done**
- [ ] `git clone` → chạy được lệnh phân tích mã, **0 cảnh báo**
- [ ] Mở một PR rỗng → CI **xanh**
- [ ] Cố tình commit code sai định dạng → CI **đỏ** (chứng minh gác cổng hoạt động)
- [ ] `.env` nằm trong `.gitignore`, `.env.example` có đủ mọi khoá cần thiết
- [ ] Tag `foundation-f0`

---

## F1 — Skeleton app chạy được

**Mục tiêu:** vỏ app đúng hệ thiết kế, chưa có nghiệp vụ.

**Đầu ra**
- App Flutter khởi động trên iOS + Android
- Điều hướng bằng `go_router`, quản lý trạng thái bằng `riverpod`
- **Design token** dịch nguyên văn từ [09-art-direction.md](09-art-direction.md): màu, bo góc, thang chữ, bóng
- Chế độ sáng + tối, đổi được trong app
- Font đã chọn, đã kiểm tra dấu tiếng Việt
- l10n dựng xong; không còn chuỗi hiển thị viết cứng trong widget
- **Cổng kiến trúc** `tool/check_architecture.dart` — cưỡng chế luật phụ thuộc ở [12-engineering-guide.md](12-engineering-guide.md) §2

**Definition of Done**
- [ ] Chạy được trên **máy Android thật**, không crash
- [ ] iOS: **biên dịch được** trên CI runner macOS (`flutter build ios --no-codesign`)
- [ ] Chuyển qua lại 2 màn giả bằng router
- [ ] Bật/tắt chế độ tối → **mọi** màu đổi đúng, không sót thành phần
- [ ] Ảnh chụp màn hình hiển thị đúng `ế ỡ ộ ữ ẫ` ở mọi độ đậm của font
- [ ] Kiểm tra tương phản: nút chính, chữ trên nền màu đều ≥ 4.5:1
- [ ] **Không có mã màu viết cứng** trong màn hình — chỉ dùng token
- [ ] Không còn chuỗi hiển thị viết cứng — kể cả tiêu đề app (nợ từ F0)
- [ ] Cổng kiến trúc chạy trong CI và đã **thử cho đỏ**: cho `fog` import `story` → đỏ; gỡ ra → xanh
- [ ] Tag `foundation-f1`

> **Vì sao iOS chỉ cần biên dịch được, không cần chạy máy thật (chốt 2026-08-05):**
> Build iOS bắt buộc phải có macOS + Xcode — ràng buộc của Apple, không có
> đường vòng. Máy phát triển hiện tại là Windows. Pilot là một khu ở TP.HCM
> nơi Android chiếm đa số, nên chặn cả phase nền tảng để chờ một máy Mac là
> đánh đổi sai.
>
> **Đây là nợ kỹ thuật, không phải hạng mục đã xong.** Phải trả trước khi có
> bản thử nghiệm cho người dùng thật trên iOS. Job build trên CI runner macOS
> bắt sớm những lỗi kiểu thiếu khai báo quyền trong `Info.plist` — thứ sẽ cắn
> ở F4 khi xin quyền vị trí.

> **Vì sao cổng kiến trúc phải làm ở F1, không để sau:** lúc `lib/` còn rỗng thì
> cổng luôn xanh và gần như miễn phí. Để đến khi đã có 7 feature mới bật thì
> việc đầu tiên phải làm là đi dọn nợ. Luật "feature không import chéo nhau"
> chính là luận điểm sản phẩm viết bằng mã — nó xứng đáng có máy canh, không
> chỉ nằm trong tài liệu.

**Cổng kiến trúc phải bắt được**
- `domain/` import bất cứ thứ gì ngoài Dart thuần
- `presentation/` import thẳng `data/` (phải đi qua `application/`)
- Feature import feature khác — trừ ngoại lệ duy nhất: được phép import `unlock`
- `unlock` import ngược lại bất kỳ feature nào
- `design/` import `features/`

---

## F2 — Nền dữ liệu

**Mục tiêu:** một nguồn sự thật duy nhất, chạy được cả khi offline.

**Đầu ra**
- Supabase project + migration đầu tiên (bảng theo [06-tech-stack.md](06-tech-stack.md))
- RLS bật cho mọi bảng có `user_id`
- Nội dung pilot dạng JSON trong `content/` + script seed
- Schema Drift cục bộ + tầng repository
- Đăng nhập ẩn danh hoặc email

**Definition of Done**
- [ ] Chạy script seed → **12 checkpoint** lên Supabase, chạy lại lần 2 **không nhân đôi dữ liệu**
- [ ] App đọc danh sách checkpoint từ server và hiển thị được
- [ ] **Tắt mạng → vẫn hiển thị đủ 12 checkpoint** từ cache
- [ ] Thử đọc `visit_state` của người dùng khác → **bị RLS từ chối** (có ảnh chụp)
- [ ] Migration chạy lại từ đầu trên DB rỗng thành công
- [ ] Tag `foundation-f2`

---

## F3 — Bản đồ nền

**Mục tiêu:** bản đồ trông như sản phẩm của mình, không như map mặc định.

**Đầu ra**
- MapLibre tích hợp, style tuỳ biến theo palette ở [09-art-direction.md](09-art-direction.md)
- Marker checkpoint dùng **ảnh thật đã qua preset xử lý**
- Vị trí người dùng, theo dõi camera
- Cache tile để dùng offline

**Definition of Done**
- [ ] Đặt cạnh ảnh chụp map mặc định → **khác biệt rõ ràng bằng mắt**
- [ ] Nước, cây, đường, nền đúng mã màu đã chốt
- [ ] 12 marker đúng toạ độ, kiểm chứng bằng cách đối chiếu thực địa hoặc ảnh vệ tinh
- [ ] Cuộn/phóng to bản đồ giữ **≥ 55 FPS** trên máy tầm trung
- [ ] Chế độ sáng và tối đều có bản đồ riêng, không phải đảo màu
- [ ] Tắt mạng → vùng đã cache vẫn hiện
- [ ] Tag `foundation-f3`

---

## F4 — Tầng mở khóa (trái tim hệ thống)

**Mục tiêu:** `visit_state` đúng trong mọi tình huống xấu.

**Đầu ra**
- Dịch vụ check-in + geofence
- Edge function xác thực **phía server** (không tin client)
- Ghi `visit_state`

**Definition of Done**
- [ ] Đứng trong bán kính → mở khóa thành công **trên thực địa**, không phải giả lập
- [ ] Đứng ngoài bán kính → **không** có nút mở khóa, chỉ hiện khoảng cách còn lại
- [ ] Gửi thẳng request check-in giả từ công cụ HTTP → **server từ chối**
- [ ] Mở khóa cùng một điểm 2 lần → chỉ ghi nhận 1 lần
- [ ] Mất mạng → nói rõ là cần mạng, **không** ghi gì vào `visit_state`
- [ ] Có bộ test tự động cho các nhánh: hợp lệ / ngoài bán kính / mất mạng / trùng lặp
- [ ] Tag `foundation-f4`

> **Mở khóa cần mạng — đây là thiết kế, không phải thiếu sót (chốt 2026-09-29).**
> Chỉ máy chủ mới có quyền nói ai đã đến đâu. Một hàng đợi chờ đồng bộ nghĩa là
> điện thoại tự nhận mình đã đến rồi xin duyệt sau, và trong khoảng chờ đó app
> phải hiển thị một trạng thái không ai xác nhận. Đổi lại sự tiện đó là chỗ dựa
> duy nhất của sản phẩm. Mất mạng thì app nói thẳng là chưa mở được.
>
> **Chống gian lận hoãn sang sau v1 (chốt 2026-09-29).** Phát hiện giả vị trí,
> kiểm tra tốc độ di chuyển và dự phòng quét QR đều không làm trong v1. Máy chủ
> vẫn đo khoảng cách và vẫn từ chối request dựng tay; thứ chưa chặn được là một
> vị trí bị làm giả ngay trên máy người chơi. Trường `requiresQrFallback` vẫn
> còn trong schema nhưng chưa nơi nào bật.

---

## F5 — Lát cắt dọc (chứng minh kiến trúc)

**Mục tiêu:** chứng minh luận điểm *"một lần đến, mở khóa cho mọi cách chơi"* bằng phần mềm chạy thật.

**Đầu ra**
- Cơ chế Lens Switcher
- Lăng kính **Fog of War** hoàn chỉnh
- Một lăng kính mỏng thứ hai (**Sưu tầm**) để có cái đối chiếu
- Khoảnh khắc mở khóa 3 giây theo đúng đặc tả ở [09-art-direction.md](09-art-direction.md)

**Definition of Done**
- [ ] Mở khóa 1 checkpoint ở lăng kính Fog → **con tem tự xuất hiện** ở lăng kính Sưu tầm, không cần thao tác thêm
- [ ] Đổi lăng kính: **camera giữ nguyên vị trí**, không tải lại, dưới 300ms
- [ ] Không lăng kính nào lưu trạng thái mở khóa riêng (kiểm chứng bằng đọc mã + test)
- [ ] Khoảnh khắc mở khóa chạy đủ 6 bước đặc tả, có haptic
- [ ] Hồng `#FF48A0` **chỉ** xuất hiện trong 3 giây đó, không nơi nào khác
- [ ] Tag `foundation-f5`

---

## Definition of Done áp dụng cho **mọi** task, không riêng phase

- [ ] `format` + `analyze` sạch, CI xanh
- [ ] Có test cho logic mới (UI thuần có thể miễn)
- [ ] **Không mã màu, không số bo góc, không cỡ chữ viết cứng** — chỉ dùng design token
- [ ] Không chuỗi hiển thị viết cứng trong widget
- [ ] Đụng UI → kèm ảnh chụp **cả sáng lẫn tối**
- [ ] Đụng chữ tiếng Việt → kiểm tra dấu
- [ ] Không mở rộng ngoài [08-scope.md](08-scope.md)
