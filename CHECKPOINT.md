# Checkpoint — 2026-08-07

Ảnh chụp trạng thái dự án để mở phiên mới không mất context.
Nguồn đúng vẫn là `docs/` và mã nguồn; file này chỉ để định hướng nhanh.

---

## 0. Đọc mục này trước — có 5 PR chưa merge

`main` **chưa có** phần lớn công việc của phiên 2026-08-07. Đừng đọc `main` rồi
kết luận là chưa ai làm gì.

| PR | Nội dung | Gốc | CI |
|----|----------|-----|-----|
| [#16](https://github.com/ZzinzZ/Wanderlock/pull/16) | Phân cấp đường theo `class`; loại đường sắt/phà/pier/đang thi công khỏi lớp đường | `main` | ✅ |
| [#17](https://github.com/ZzinzZ/Wanderlock/pull/17) | Tải trước vùng bản đồ để dùng offline | `main` | ✅ |
| [#18](https://github.com/ZzinzZ/Wanderlock/pull/18) | Trang preview style về `tool/map_preview/`, gỡ mìn `launch.json` | `main` | ✅ |
| [#19](https://github.com/ZzinzZ/Wanderlock/pull/19) | Chốt marker dùng ảnh thật + mở `content/image-licenses.md` | `main` | ✅ |
| [#20](https://github.com/ZzinzZ/Wanderlock/pull/20) | Vị trí người dùng + theo dõi camera | **`feat/f3-offline-tiles`** | ✅ |

⚠️ **#20 xếp chồng trên #17**, không phải trên `main` — hai PR cùng sửa
`map_screen.dart`. **Merge #17 trước**, GitHub sẽ tự trỏ #20 về `main`.
Bốn PR còn lại độc lập, thứ tự nào cũng được.

Nếu chủ dự án đã merge hết thì xoá mục này.

---

## 1. Đang ở đâu

| Phase | Trạng thái |
|-------|-----------|
| **F0** — Kho mã & quy ước | ✅ Đóng · tag `foundation-f0` (`502c436`) |
| **F1** — Skeleton app | ✅ Đóng · tag `foundation-f1` (`c33dfe1`) |
| **F2** — Nền dữ liệu | 🟡 3/5 DoD · chặn ở **toạ độ** |
| **S** — 3 spike | ⛔ Chưa bắt đầu · cần thực địa |
| **F3** — Bản đồ nền | 🟡 4/6 DoD · **chỉ còn toạ độ + một lần máy thật** |
| F4, F5 | Chưa |

`main` được bảo vệ: **mọi thay đổi phải qua PR + CI xanh**, chủ dự án không tự
bypass được.

### F2 chi tiết — không đổi từ 2026-08-06

| DoD | |
|---|---|
| Migration chạy lại từ DB rỗng | ✅ |
| RLS từ chối đọc `visit_state` người khác | ✅ 6 phép thử |
| Seed 2 lần không nhân đôi | 🟡 đúng, nhưng **8/12** (4 điểm thiếu toạ độ) |
| App đọc từ server và hiển thị | ✅ trên Redmi Note 12 thật |
| Tắt mạng vẫn còn dữ liệu | 🟡 tầng dữ liệu có test `live`; **chưa nhìn trên máy** |

### F3 chi tiết — tiến nhiều trong phiên 2026-08-07

| DoD | |
|---|---|
| Khác biệt rõ so với map mặc định | ✅ 3 khung đồng bộ camera + đối chứng Liberty trên native |
| Nước/cây/đường/nền đúng mã màu | ✅ đối chiếu JSON sinh ra với mục 6 art direction |
| Sáng và tối là hai bản đồ riêng | ✅ đã xem cả hai trên SDK native |
| Tắt mạng → vùng cache vẫn hiện | ✅ chứng minh 2 lần (ambient + tải trước) |
| 12 marker đúng toạ độ | ⛔ **chặn ở toạ độ** |
| Cuộn/phóng ≥ 55 FPS máy tầm trung | ⛔ **cần máy thật** — emulator dùng GPU phần mềm, số đo vô nghĩa |
| Tag `foundation-f3` | ⛔ còn 2 mục |

**Đầu ra F3**: style ✅ · cache offline ✅ · vị trí người dùng + theo dõi camera ✅
· marker ảnh thật ⛔ (chặn toạ độ + ảnh).

---

## 2. Chặn ở chủ dự án — xếp theo mức chặn

1. **Toạ độ 12 checkpoint** (~15 phút) — chặn F2 đóng **và** chặn marker F3.
   `content/checkpoints.json`: 4 điểm `coordinates: null` (Bến Nhà Rồng, Chùa Bà
   Thiên Hậu, Landmark 81, Thiền viện Bửu Long), 8 điểm có toạ độ nhưng
   `verified: false`.
   Cách làm: Google Maps → chuột phải **giữa công trình** → copy `10.7770, 106.6955`.
   Sửa xong đổi `verified` thành `true`. Seed script **từ chối chạy** khi còn
   `verified: false`, trừ khi truyền `--allow-unverified`.
   > Vùng cache offline (#17) **tự tính từ checkpoint**, nên nhập toạ độ xong là
   > nó tự đúng, không ai phải sửa hằng số.
2. **Một lần cầm máy thật** — đóng được **ba** thứ trong cùng một buổi mà
   emulator vĩnh viễn không trả lời được: FPS ≥ 55, nhãn bản đồ + dấu tiếng Việt,
   và chấm vị trí người dùng. Xem mục 4 để biết vì sao.
3. **12 ảnh địa danh có bản quyền rõ** — chặn marker F3. Sổ đã mở sẵn ở
   `content/image-licenses.md` (PR #19), 12 dòng trống chờ điền.
   ⚠️ **Landmark 81** là công trình hiện đại còn bảo hộ quyền tác giả kiến trúc —
   dùng ảnh thương mại hay không phụ thuộc *freedom of panorama*, nên xác minh
   trước khi đi chụp.
4. **Phase S** — 3 spike đo FPS / %pin / sai số GPS. Đều cần ra đường.
   **S3 quyết định bán kính check-in, tức là F4** — không chặn phần vị trí của F3
   (đã làm xong).
5. **12 chương truyện** — định dạng đã có, chờ nội dung.
6. **Tên chính thức** — không gấp.

> ⚠️ Wi-Fi và dữ liệu di động trên điện thoại chủ dự án **vẫn đang tắt** từ phiên
> 2026-08-06.

---

## 3. Quyết định đã chốt (bổ sung cho phiên 2026-08-07)

**Bản đồ**
- Đường có **5 tầng** theo `class`, mỗi tầng có bề rộng và `minzoom` riêng.
  Danh sách class là **allow-list** — cái không được gọi tên thì không phải
  đường và không được vẽ.
- **Tile OpenFreeMap dừng ở zoom 14.** Tải quá z14 là tải rỗng; MapLibre tự
  phóng to z14 cho z15-17. Điều này làm vùng cache rẻ hơn nhiều so với trực giác.
- Vùng cache offline **tính từ hộp bao quanh checkpoint + đệm 2 km**, không viết
  cứng. Lề đo bằng **ki-lô-mét** nên phải nhân cosine vĩ độ cho kinh độ.
- Marker checkpoint dùng **ảnh thật** — đã sửa dòng sót ở mục 6 art direction cho
  khớp với mục 7.1, 7.2, danh sách cấm và nhật ký quyết định (vốn đều đã nói ảnh thật).

**Vị trí người dùng**
- Chỉ dùng `MyLocationTrackingMode.tracking`. `trackingCompass` và `trackingGps`
  **xoay bản đồ**, mà xoay đã tắt vì làm lớp phủ Fog khó vẽ đúng. Cùng lý do đó
  chấm vị trí dùng kiểu vẽ trơn, không mũi tên hướng.
- **Kéo tay là nhả bám**, qua `onCameraTrackingDismissed` của chính bản đồ.
- **Không xin quyền lúc mở màn hình.** Hộp thoại tự bật vì người ta mở một màn
  hình sẽ dạy phản xạ bấm "từ chối".
- **Quyền được xử lý trước dịch vụ vị trí.** Chưa cấp quyền thì bảo bật dịch vụ
  cũng vô ích.
- Trạng thái *bám camera* tách khỏi *quyền*: mất quyền không được âm thầm xoá ý
  muốn của người dùng, có lại quyền không được âm thầm kéo bản đồ đi.
- Chỉ tiền cảnh trên cả hai nền tảng. **Không** `ACCESS_BACKGROUND_LOCATION`.
- Chỉ thêm `geolocator`; **`permission_handler` hoá ra không cần** — geolocator
  lo cả kiểm tra quyền, xin quyền, lẫn hai màn cài đặt.

**Hạ tầng**
- API offline của MapLibre nhận style dạng **URL**, và trên Android nó giải URL
  đó **chỉ qua tầng HTTP** — `file://` và `asset://` không bao giờ tới được nguồn
  file. App tự phục vụ style cho chính mình trên `127.0.0.1` trong vài giây tải.
  Cleartext vẫn tắt ở mọi nơi khác, bằng `network_security_config.xml`.

*(Các quyết định trước 2026-08-06 vẫn giữ nguyên — xem lịch sử git của file này.)*

---

## 4. Emulator: dùng được, nhưng biết trước nó mù chỗ nào

Có sẵn AVD **`wanderlock_pixel7`** (Android 16, API 36). Khác điện thoại thật:
`adb install` **được**, `input tap` **được** — không bị MIUI chặn.

> **Máy ảo không vẽ bất kỳ symbol layer nào.** Không chữ, không icon, **không cả
> chấm vị trí**. Đã xác minh chứ không suy đoán: nạp style Liberty của
> OpenFreeMap lên chính máy ảo đó thì đường, công trình, công viên, nước hiện
> đủ, còn nhãn và icon thì **không một cái nào** — trong khi trình duyệt vẽ đủ cả
> hai từ cùng style ấy. GPU của máy ảo là **SwiftShader** (phần mềm).
>
> Hệ quả: **nhãn bản đồ, dấu tiếng Việt trên bản đồ, chấm vị trí, và FPS** đều
> phải chờ máy thật. Đừng mất thời gian debug chúng trên máy ảo.

| | |
|---|---|
| adb | `C:\Users\nhata\AppData\Local\Android\Sdk\platform-tools\adb.exe` |
| **Application id** | `com.wanderlock.wanderlock` — **không phải** `com.wanderlock` |
| Khởi động | `flutter emulators --launch wanderlock_pixel7` |
| Mở app | `adb shell monkey -p com.wanderlock.wanderlock -c android.intent.category.LAUNCHER 1` |
| Cắt mạng | `adb shell cmd connectivity airplane-mode enable` + `svc wifi disable` + `svc data disable` |
| **Vị trí giả** | `adb emu geo fix` **không tạo ra bản định vị nào** trên image này. `adb emu geo nmea '$GPGGA,…'` thì **được** — gửi lặp vài lần |
| Kéo binary ra khỏi máy | `adb exec-out "run-as <pkg> cat <file>"` — dùng `adb shell` sẽ **hỏng file** vì chèn CR |
| Cache bản đồ | `files/mbgl-offline.db`, bảng `tiles`, `regions`, `region_tiles` |

---

## 5. Môi trường máy dev

| | |
|---|---|
| Flutter | `C:\Users\nhata\fvm\versions\3.44.8\bin\flutter.bat` — **PATH của agent có thể cũ, gọi đường dẫn tuyệt đối** |
| gh | `C:\Program Files\GitHub CLI\gh.exe` — đã đăng nhập |
| Điện thoại | Redmi Note 12, Android 15, serial `74a2b5c6` |
| **MIUI chặn** | `adb install` và `input tap`. Chụp màn hình và `am start` thì **được** |
| Cài app lên máy thật | `adb push` APK sang `/sdcard/Download/` rồi chủ dự án chạm tay cài |
| RAM | 15.8 GB — **không chạy nổi emulator cùng lúc với Docker/Supabase** |
| IP LAN | **Đổi liên tục**. Luôn đọc lại trước khi build |
| PowerShell | `Set-Content`/`Out-File` **thêm BOM và làm hỏng dấu tiếng Việt**. Commit message truyền qua `-F <file>` |
| Build Android | ~20-40s incremental; build sạch ~170s |

**Supabase local**
```
npx supabase start
dart run tool/seed_content.dart --allow-unverified
```

---

## 6. Sáu cổng CI

`format` · `analyze --fatal-infos --fatal-warnings` · `check_design_tokens` ·
`check_architecture` · `check_encoding` · `test`

- `check_design_tokens` — có lối thoát `// design-token-ignore: <lý do>`.
- `check_architecture` — **không có lối thoát**.
- `check_encoding` — không có lối thoát.
- Test loại 2 tag: `golden` và `live`.

```
cd app && fvm flutter gen-l10n && fvm dart run build_runner build && fvm dart format . && fvm dart format --output=none --set-exit-if-changed . && fvm flutter analyze --fatal-infos --fatal-warnings && fvm dart run ../tool/check_design_tokens.dart && fvm dart run ../tool/check_architecture.dart && fvm dart run ../tool/check_encoding.dart && fvm flutter test --exclude-tags "golden || live"
```

> ⚠️ `dart format --output=none` **chỉ kiểm tra, không ghi**. Muốn sửa thật phải
> chạy `dart format .` trước rồi mới kiểm.

Số test theo nhánh: `main` 55 · +#16 = 59 · +#17 = 61 · +#20 = 67.

---

## 7. Cách làm việc chủ dự án mong đợi

- **Một cổng chưa từng đỏ là cổng chưa được kiểm chứng.** Luôn cố tình làm hỏng
  để xem nó bắt được, rồi mới báo xong.
- Đối chiếu **"Definition of Done áp dụng cho mọi task"** cuối
  `docs/11-foundation-plan.md` trước khi báo hoàn thành.
- **Không gắn tag khi chưa chứng minh được.**
- Trao đổi **tiếng Việt**; mã, commit, PR **tiếng Anh**.
- Không mở rộng ngoài scope v1. Xã hội = v1.5.

---

## 8. Bài học của phiên 2026-08-07

**Thất bại im lặng nguy hiểm hơn thất bại ồn ào.**

| Lỗi | Vì sao khó thấy |
|---|---|
| `file://` không tới được nguồn file trên Android | Vùng offline **báo Success** sau khi tải 0 tile. Banner nói "đã lưu bản đồ" |
| `downloadOfflineRegion` trả về quá sớm | Future resolve khi hệ điều hành *nhận* vùng, không phải khi tile *về*. Kết quả đến qua `onEvent` |
| Đường sắt, phà, pier, `*_construction` vẽ như đường phố | Lớp `transportation` của OpenMapTiles không phải "lớp đường". Đọc mã không thấy — phải truy vấn tile thật |
| Một test đậu vì **may mắn số học dấu phẩy động** | So sánh hai đại lượng lệch nhau <2%; khi mutation làm chúng bằng nhau, sai số làm tròn ở kinh độ 106 quyết định kết quả. Sửa: đo bằng ki-lô-mét |

**Và một lỗi suýt bị báo nhầm.** Emulator không hiện nhãn bản đồ — trông hệt lỗi
font tiếng Việt. Thay vì báo, dựng đối chứng: nạp style Liberty (đầy nhãn) vào
cùng SDK đó → cũng không chữ nào ⇒ là giới hạn máy ảo. **Khi một thứ trông như
lỗi của mình, hãy tìm một đối chứng trước khi kết luận.**

Tổng cộng 12 mutation trong phiên, tất cả đều bị test bắt sau khi sửa.

---

## 9. Việc kế tiếp

**Trước hết: merge 5 PR** (xem mục 0 — #17 trước #20).

**Nếu chủ dự án đưa toạ độ:** gỡ `--allow-unverified`, seed đủ 12, **đóng F2**,
rồi làm marker cho F3 (cần ảnh nữa).

**Nếu chủ dự án chịu cầm máy thật một buổi:** đo FPS, nhìn nhãn tiếng Việt, nhìn
chấm vị trí — ba mục cùng lúc.

**Việc không bị chặn còn lại của F3:** không còn. Marker cần toạ độ + ảnh; FPS
cần máy thật.

**Hai việc tương phản màu chờ chủ dự án quyết** (đều đụng token màu mà mục 6 art
direction đã chốt cứng, nên không tự sửa):
- Viền đường gần như vô hình: sáng **1.08:1**, tối **1.03:1** so với nền.
- Nhãn chế độ sáng `#6B7280` trên `#F4F1EA` = **4.29:1** ở cỡ chữ 11px —
  **dưới ngưỡng WCAG AA 4.5:1**. Chế độ tối 7.11:1, đạt.

**Đừng làm F4** khi phase S chưa có số: S3 quyết định bán kính check-in và điểm
nào bắt buộc cần QR.
