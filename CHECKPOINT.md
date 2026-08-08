# Checkpoint — 2026-08-08

Ảnh chụp trạng thái dự án để mở phiên mới không mất context.
Nguồn đúng vẫn là `docs/` và mã nguồn; file này chỉ để định hướng nhanh.

---

## 0. Không còn PR treo

Toàn bộ công việc của phiên 2026-08-07 (#16–#21) đã vào `main` ngày 2026-08-08.
`main` giờ là bức tranh đầy đủ — đọc `main` là đủ.

---

## 1. Đang ở đâu

| Phase | Trạng thái |
|-------|-----------|
| **F0** — Kho mã & quy ước | ✅ Đóng · tag `foundation-f0` (`502c436`) |
| **F1** — Skeleton app | ✅ Đóng · tag `foundation-f1` (`c33dfe1`) |
| **F2** — Nền dữ liệu | 🟡 3/5 DoD · chặn ở **một chữ `true`** |
| **S** — 3 spike | ⛔ Chưa bắt đầu · cần thực địa |
| **F3** — Bản đồ nền | 🟡 4/6 DoD · chặn ở **ảnh + một lần máy thật** |
| F4, F5 | Chưa |

`main` được bảo vệ: **mọi thay đổi phải qua PR + CI xanh**, chủ dự án không tự
bypass được.

### F2 chi tiết

| DoD | |
|---|---|
| Migration chạy lại từ DB rỗng | ✅ |
| RLS từ chối đọc `visit_state` người khác | ✅ 6 phép thử |
| Seed 2 lần không nhân đôi | 🟡 **12/12 đã có toạ độ**, dry-run nạp đủ 12; còn chờ `verified: true` rồi chạy thật 2 lần |
| App đọc từ server và hiển thị | ✅ trên Redmi Note 12 thật |
| Tắt mạng vẫn còn dữ liệu | 🟡 tầng dữ liệu có test `live`; **chưa nhìn trên máy** |

### F3 chi tiết

| DoD | |
|---|---|
| Khác biệt rõ so với map mặc định | ✅ 3 khung đồng bộ camera + đối chứng Liberty trên native |
| Nước/cây/đường/nền đúng mã màu | ✅ đối chiếu JSON sinh ra với mục 6 art direction |
| Sáng và tối là hai bản đồ riêng | ✅ đã xem cả hai trên SDK native |
| Tắt mạng → vùng cache vẫn hiện | ✅ chứng minh 2 lần (ambient + tải trước) |
| 12 marker đúng toạ độ | ⛔ toạ độ đã có, **còn chặn ở ảnh** |
| Cuộn/phóng ≥ 55 FPS máy tầm trung | ⛔ **cần máy thật** — emulator dùng GPU phần mềm, số đo vô nghĩa |
| Tag `foundation-f3` | ⛔ còn 2 mục |

**Đầu ra F3**: style ✅ · cache offline ✅ · vị trí người dùng + theo dõi camera ✅
· marker ảnh thật ⛔ (chỉ còn chặn ở ảnh).

> ⚠️ **Chưa ai nhìn bản đồ sau khi đổi màu tương phản (#23).** Số đúng, test
> đúng, nhưng DoD "đụng UI → ảnh chụp cả sáng lẫn tối" chưa đạt. Mở
> `tool/map_preview/preview.html` là thấy cả ba khung.

---

## 2. Chặn ở chủ dự án — xếp theo mức chặn

1. **Xác nhận 12 toạ độ bằng ảnh vệ tinh** (~3 phút) — chặn F2 đóng.
   Toạ độ **đã có đủ 12** (#24), lấy từ tâm đa giác công trình trong
   OpenStreetMap, `source` ghi mã đối tượng để truy ngược. Reverse geocoding
   khớp 12/12 tên đường. Chỉ còn thiếu bước nhìn ảnh vệ tinh để đổi `verified`
   thành `true`.
   Đã dựng sẵn trang xem 12 ảnh vệ tinh cùng lúc, bấm để dời chấm, xuất ra JSON
   dán thẳng vào file — agent gửi qua chat, file tự chứa, mở bằng trình duyệt.
   > ⚠️ **Lăng Ông Bà Chiểu dời 83m**, vượt bán kính 60m. Khuôn viên rộng ~170m
   > nên đứng ở cổng sẽ **không mở khoá được**. Câu hỏi bán kính này thuộc về S3.
2. **Một lần cầm máy thật** — đóng được **ba** thứ trong cùng một buổi mà
   emulator vĩnh viễn không trả lời được: FPS ≥ 55, nhãn bản đồ + dấu tiếng Việt,
   và chấm vị trí người dùng. Xem mục 4 để biết vì sao.
3. **Chọn 12 ảnh địa danh** — chặn marker F3. `content/image-licenses.md` giờ có
   sẵn **danh sách ứng viên trên Wikimedia Commons** cho cả 12 điểm, giấy phép
   đọc từng ảnh (#25). Việc còn lại là **mở link nhìn và chọn**, rồi chép sang
   bảng duyệt. Chưa ai nhìn ảnh — vài cái tên tự tố là ảnh trong nhà.
   ⚠️ **Landmark 81 đã có kết luận:** Commons duy trì `Template:NoFoP-Vietnam`,
   nên Việt Nam bị xếp là **không có freedom of panorama**. Giấy phép CC0 trên
   tấm ảnh không gỡ được — đó là quyền của người chụp, không phải quyền của kiến
   trúc sư. **Tự chụp cũng không gỡ được.** Ba đường đi ghi trong file; rẻ nhất
   là thay bằng điểm khác, vì 11 điểm còn lại đều đủ cũ để không vướng.
4. **Bật Docker Desktop** — engine Linux chưa lên, agent không tự bật được
   (có thể đang chờ thao tác trong giao diện của nó). Cần nó để chạy Supabase
   cục bộ và đóng nốt DoD "seed 2 lần không nhân đôi".
5. **Phase S** — 3 spike đo FPS / %pin / sai số GPS. Đều cần ra đường.
   **S3 quyết định bán kính check-in, tức là F4** — không chặn phần vị trí của F3
   (đã làm xong).
6. **12 chương truyện** — định dạng đã có, chờ nội dung.
7. **Tên chính thức** — không gấp.

> ⚠️ Wi-Fi và dữ liệu di động trên điện thoại chủ dự án **vẫn đang tắt** từ phiên
> 2026-08-06.

---

## 3. Quyết định đã chốt

**Bản đồ — tương phản (chốt 2026-08-08)**
- Viền đường `#E6E9EE` → **`#C9CFDB`** (sáng), `#11131A` → **`#454C5B`** (tối).
- **Chế độ tối, viền phải SÁNG hơn mặt đường** — ngược chiều với chế độ sáng.
  Nền tối gần đen sẵn nên viền tối hơn nữa là biến mất; không có màu nào vừa
  tối hơn mặt đường vừa tách được khỏi nền.
- Nhãn bản đồ có **token riêng**, không mượn `inkMuted` của UI: nhãn nằm trên
  bốn bề mặt (nền, nước, cây xanh, mặt đường), không phải trên thẻ. Sáng dùng
  mực `#1F2430` (chủ dự án chọn), tối giữ `#9AA3B2` vì đã đạt 7.11:1.
- **Ranh giới hành chính tách khỏi viền đường.** Trước đây dùng chung màu; khi
  viền đường được làm cho thấy được thì mọi ranh giới quận cũng sáng lên theo,
  mà ranh giới vẽ dày như đường phố chính là lỗi mà phân cấp đường (#16) vừa
  dọn cho đường sắt và phà.

**Bản đồ (phiên 2026-08-07)**
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

## 8b. Bài học của phiên 2026-08-08

**GitHub không tự trỏ PR xếp chồng về `main` nếu nhánh gốc không bị xoá.** #20
xếp trên #17. Merge #17 xong, `gh pr view 20` vẫn báo `base=feat/f3-offline-tiles`
— và merge #20 lúc đó thì nó vào *nhánh kia*, không vào `main`, mà vẫn báo
MERGED. Phải mở PR mới cherry-pick sang `main` (#22) mới sửa được. **Sau khi
merge PR gốc, đọc lại `baseRefName` của PR con trước khi merge nó.**

**Nhánh được bảo vệ đòi nhánh con phải ngang bằng `main`.** Mỗi lần `main` nhích
là các PR còn lại phải `update-branch` và chờ CI chạy lại — merge hàng loạt
buộc phải tuần tự. Và `gh pr checks` ngay sau `update-branch` **trả về kết quả
của lần chạy CŨ**, xanh, trong khi lần chạy mới chưa kịp đăng ký. Phải đợi
`statusCheckRollup[0].status == COMPLETED` trên head SHA mới.

**Tra theo TÊN là cái bẫy lặp lại hai lần trong cùng một phiên.** Toạ độ 4 điểm
`null` và ảnh 12 điểm đều từng tra hỏng vì cùng một lý do: công trình mang tên
khác trong cơ sở dữ liệu so với tên người Việt gọi.

| Tra gì | Ra gì |
|---|---|
| `Bến Nhà Rồng` (OSM) | không có — nó tên `Bảo tàng Hồ Chí Minh` |
| `Chùa Bà Thiên Hậu` (OSM) | chùa cùng tên ở Bình Dương — bản Chợ Lớn tên `Hội quán Tuệ Thành` |
| `Landmark 81` (OSM) | không có — nó tên `Vincom Center` |
| `Landmark 81` (Commons) | **Yokohama Landmark Tower**, Nhật Bản |
| `Chùa Bửu Long` (Commons) | **Chùa Bửu Đà, Quận 10** — chùa khác |

Cách thoát: tra bằng **thuộc tính** thay vì bằng tên. Landmark 81 tìm ra nhờ
`height=461.2` + `building:levels=81`; trên Commons thì dùng `incategory:"…"`;
và luôn đối chứng ngược bằng reverse geocoding rồi so với địa chỉ đã ghi.

**Một test không thể làm cho đỏ thì không phải cổng gác.** Đã viết một test
khẳng định "viền đường phải nằm khác phía mặt đường so với nền". Nó đậu — nhưng
thử mọi cách vẫn không làm nó đỏ độc lập được: mặt đường sáng là `#FFFFFF` nên
không màu nào sáng hơn, còn nền tối gần đen nên không màu nào tối hơn mà còn
tách được khỏi nền. Điều nó khẳng định đã bị test tương phản hàm ý sẵn. Đã gỡ
và chuyển lý lẽ thành chú thích. **Đo mức bắt lỗi của test bằng mutation trước
khi tính nó là một cổng.**

---

## 9. Việc kế tiếp

Xếp theo lượng việc mở ra được, nhiều nhất trước.

**Nếu chủ dự án xác nhận 12 toạ độ** (~3 phút, trang xem ảnh vệ tinh đã gửi qua
chat): đổi `verified` thành `true`, bật Docker, seed thật hai lần, **đóng F2**.

**Nếu chủ dự án chọn xong 12 ảnh:** dựng preset xử lý ảnh rồi làm marker —
**đầu ra cuối cùng còn thiếu của F3**.

**Nếu chủ dự án chịu cầm máy thật một buổi:** đo FPS, nhìn nhãn tiếng Việt, nhìn
chấm vị trí — ba mục cùng lúc, và đóng nốt DoD offline của F2.

**Việc không bị chặn còn lại:** không còn. Cả ba nhánh trên đều bắt đầu bằng một
thao tác của chủ dự án.

**Đừng làm F4** khi phase S chưa có số: S3 quyết định bán kính check-in và điểm
nào bắt buộc cần QR. Lăng Ông Bà Chiểu đã cho thấy câu hỏi này là thật chứ không
phải lý thuyết — xem mục 2.
