# Checkpoint — 2026-08-06

Ảnh chụp trạng thái dự án để mở phiên mới không mất context.
Nguồn đúng vẫn là `docs/` và mã nguồn; file này chỉ để định hướng nhanh.

---

## 1. Đang ở đâu

| Phase | Trạng thái |
|-------|-----------|
| **F0** — Kho mã & quy ước | ✅ Đóng · tag `foundation-f0` (`502c436`) |
| **F1** — Skeleton app | ✅ Đóng · tag `foundation-f1` (`c33dfe1`) |
| **F2** — Nền dữ liệu | 🟡 3/5 DoD · chặn ở **toạ độ** |
| **S** — 3 spike | ⛔ Chưa bắt đầu · cần thực địa |
| **F3** — Bản đồ nền | 🟡 Style xong · chặn ở **toạ độ + ảnh** |
| F4, F5 | Chưa |

14 PR đã merge. `main` được bảo vệ: **mọi thay đổi phải qua PR + CI xanh**, chủ dự án không tự bypass được.

### F2 chi tiết

| DoD | |
|---|---|
| Migration chạy lại từ DB rỗng | ✅ |
| RLS từ chối đọc `visit_state` người khác | ✅ 6 phép thử |
| Seed 2 lần không nhân đôi | 🟡 đúng, nhưng **8/12** (4 điểm thiếu toạ độ) |
| App đọc từ server và hiển thị | ✅ trên Redmi Note 12 thật |
| Tắt mạng vẫn còn dữ liệu | 🟡 tầng dữ liệu có test `live`; **chưa nhìn trên máy** (chủ dự án bỏ qua) |

### F3 chi tiết

Xong: style bản đồ sinh từ token (sáng + tối riêng biệt), nối OpenFreeMap, màn bản đồ, quyền INTERNET.
Đã xác minh không cần nhìn: 6 `source-layer` đều tồn tại thật, tile HTTP 200, font HTTP 200.
**Chưa ai nhìn thấy bản đồ render.** Trang so sánh sáng/tối đã dựng sẵn, cần mở Browser pane.

---

## 2. Chặn ở chủ dự án — xếp theo mức chặn

1. **Toạ độ 12 checkpoint** (~15 phút) — chặn F2 đóng **và** chặn F3.
   `content/checkpoints.json`: 4 điểm `coordinates: null` (Bến Nhà Rồng, Chùa Bà Thiên Hậu, Landmark 81, Thiền viện Bửu Long — tra tự động ra sai, có ghi chú lý do), 8 điểm có toạ độ nhưng `verified: false`.
   Cách làm: Google Maps → chuột phải **giữa công trình** → copy `10.7770, 106.6955`. Sửa xong đổi `verified` thành `true`.
   Seed script **từ chối chạy** khi còn `verified: false`, trừ khi truyền `--allow-unverified`.
2. **12 ảnh địa danh có bản quyền rõ** — chặn F3 (marker dùng ảnh thật, không illustration). Phải ghi nguồn + giấy phép vào `content/image-licenses.md`.
3. **Phase S** — 3 spike đo FPS / %pin / sai số GPS. Đều cần cầm điện thoại ra đường. **Có quyền chặn F3 và F4.**
4. **12 chương truyện** — định dạng đã có (`content/stories/_format-example.json`), chờ nội dung.
5. **Tên chính thức** — không gấp, định danh kỹ thuật đã tách khỏi tên thương hiệu.

> ⚠️ **Wi-Fi và dữ liệu di động trên điện thoại chủ dự án đang TẮT** — tắt lúc thử ngoại tuyến, chưa bật lại được vì máy rút cáp.

---

## 3. Quyết định đã chốt trong phiên (chưa nằm hết trong docs)

**Hạ tầng**
- Định danh kỹ thuật `wanderlock` / `com.wanderlock` **tách khỏi tên thương hiệu**.
- Flutter ghim **3.44.8** ở `app/.fvmrc`; CI đọc lại chính file đó.
- Job CI tên **`quality gates`** — **đổi tên là `main` không merge được nữa** (nó là required status check).
- iOS **chỉ kiểm tra biên dịch** trên runner macOS (máy dev là Windows). Chạy máy iOS thật = nợ kỹ thuật.
- **Mã sinh ra không commit** (l10n + build_runner), CI sinh lại. File viết tay là nguồn đúng.
- `kotlin.incremental=false` — trên Windows nó hỏng lặp lại được.

**Dữ liệu**
- `quest_progress` **bỏ `done_steps`**, không tạo bảng `footprints` (Xã hội = v1.5). Đã sửa docs cho khớp.
- `visit_state` chỉ có `SELECT` cho `authenticated`, **không có policy ghi nào** — chặn hai tầng.
- Default privileges **chỉ cho `service_role`**; `authenticated` cấp từng bảng một.
- `latitude`/`longitude` là **cột sinh** từ `geom` (PostgREST không gọi được hàm SQL trong `select`).
- **Đăng nhập ẩn danh là bắt buộc**, không phải tiện nghi — RLS chỉ cấp quyền cho `authenticated`.

**Ngữ nghĩa "danh sách rỗng" khác nhau — cố ý**
- Checkpoint rỗng = **thất bại** (không xoá bản đồ đang chạy tốt vì câu trả lời mơ hồ).
- `visit_state` rỗng = **thông tin thật** (máy mới học rằng chưa mở khoá gì).
- Không đụng nhau vì server không với tới được thì **ném lỗi**, không trả rỗng.

**Sản phẩm**
- Pilot đổi từ "Quận 1 + rìa Chợ Lớn" sang **12 điểm rải khắp TP.HCM** (chủ dự án quyết). Đã sửa `08-scope.md` và 3 mục DoD dựa trên việc đi bộ.
- Chương truyện **tuyến tính**, 3 loại node. Phân nhánh là v2.
- Tile: **OpenFreeMap** (miễn phí, không khoá). URL là cấu hình, đổi sang Protomaps offline được sau.
- Hai màu tối art direction không quy định (nút hành động, chữ trên san hô) — đã duyệt, ghi trong `app_colors.dart`.

---

## 4. Môi trường — những thứ sẽ mất thời gian nếu không biết trước

| | |
|---|---|
| Flutter | `C:\Users\nhata\fvm\versions\3.44.8\bin\flutter.bat` — **PATH của tiến trình agent có thể cũ, gọi đường dẫn tuyệt đối** |
| gh | `C:\Program Files\GitHub CLI\gh.exe` — đã đăng nhập |
| Điện thoại | Redmi Note 12, Android 15, serial `74a2b5c6` |
| **MIUI chặn** | `adb install` và **mô phỏng thao tác** (`input tap`). Chụp màn hình và `am start` thì **được** |
| Cài app lên máy thật | `adb push` APK sang `/sdcard/Download/` rồi chủ dự án chạm tay cài |
| RAM | 15.8 GB — **không chạy nổi emulator cùng lúc với Docker/Supabase** |
| IP LAN | **Đổi liên tục** (đã thấy 10.226.40.84 → 192.168.6.215 → 192.168.1.155). **Luôn đọc lại trước khi build**, đừng tin lần trước |
| PowerShell | `Set-Content`/`Out-File` **thêm BOM và làm hỏng dấu tiếng Việt** — không dùng cho file nguồn. Commit message truyền qua `-F <file>`, viết inline sẽ vỡ vì dấu ngoặc |
| Build Android | ~40s bình thường; build sạch từng mất 13 phút và hỏng trước khi tắt kotlin incremental |

**Supabase local**
```
npx supabase start
dart run tool/seed_content.dart --allow-unverified
```
Khoá local in ra khi `supabase start`. Test `live` cần `--dart-define` URL + publishable key.

---

## 5. Sáu cổng CI

`format` · `analyze --fatal-infos --fatal-warnings` · `check_design_tokens` · `check_architecture` · `check_encoding` · `test`

- `check_design_tokens` — có lối thoát `// design-token-ignore: <lý do>`, **phải nằm đúng dòng ngay trên**.
- `check_architecture` — **không có lối thoát**. Vướng thì sửa thiết kế.
- `check_encoding` — không có lối thoát. Đã bắt 2 lỗi BOM thật trong phiên.
- Test loại 2 tag: `golden` (rasterise khác nhau giữa Windows/Linux) và `live` (cần Supabase).

Chạy đủ như CI:
```
cd app && fvm flutter gen-l10n && fvm dart run build_runner build && fvm dart format --output=none --set-exit-if-changed . && fvm flutter analyze --fatal-infos --fatal-warnings && fvm dart run ../tool/check_design_tokens.dart && fvm dart run ../tool/check_architecture.dart && fvm dart run ../tool/check_encoding.dart && fvm flutter test --exclude-tags "golden || live"
```

---

## 6. Cách làm việc chủ dự án mong đợi

- **Một cổng chưa từng đỏ là cổng chưa được kiểm chứng.** Luôn cố tình làm hỏng để xem nó bắt được, rồi mới báo xong.
- Đối chiếu **"Definition of Done áp dụng cho mọi task"** cuối `docs/11-foundation-plan.md` trước khi báo hoàn thành.
- **Không gắn tag khi chưa chứng minh được.** Ghi rõ mục nào dựa vào báo cáo của chủ dự án chứ không phải mình tự kiểm.
- Trao đổi **tiếng Việt**; mã, commit, PR **tiếng Anh**.
- Không mở rộng ngoài scope v1. Xã hội = v1.5, đừng thêm.

---

## 7. Bài học lớn nhất của phiên

**Đọc mã không phát hiện được những lỗi này. Chỉ chạy mới thấy.**

| Lỗi | Vì sao đọc không thấy |
|---|---|
| Thiếu `GRANT` | RLS + policy viết đúng hết. Nhìn như **đang an toàn**, thực ra chặn cả bảng nội dung |
| `service_role` không có quyền | Supabase hosted có default privileges che mất — chỉ lộ khi deploy |
| PostgREST không gọi được hàm SQL trong `select` | Cú pháp trông hợp lý, nó hiểu thành khoá ngoại |
| `await` Supabase trước `runApp` | Trông hoàn toàn hợp lý; server không tới được thì app treo màn trắng |
| Quyền INTERNET chỉ ở manifest debug | Mọi lần thử đều là bản debug |
| Nút Back Android thoát app | Test bấm nút back **trong app** — đường code khác, xanh suốt |

---

## 8. Việc kế tiếp

**Nếu chủ dự án đưa toạ độ:** gỡ `--allow-unverified`, seed đủ 12, **đóng F2**, rồi làm marker cho F3.

**Nếu chưa:** hai hướng đi được ngay
- **Xem bản đồ render** — trang so sánh sáng/tối đã dựng, chỉ cần mở Browser pane. Đóng được mục DoD đầu của F3.
- **Cache tile offline** (mục DoD của F3) — có thể phải chuyển sang Protomaps `.pmtiles`.

**Đừng làm F4** khi phase S chưa có số: S3 quyết định bán kính check-in và điểm nào bắt buộc cần QR.
