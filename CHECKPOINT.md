# Checkpoint — 2026-09-19

Ảnh chụp trạng thái dự án để mở phiên mới không mất context.
Nguồn đúng vẫn là `docs/` và mã nguồn; file này chỉ để định hướng nhanh.

---

## 0. Một PR treo: #27

Nhánh `feat/f2-seed-sync-and-check-in` giữ **mọi thứ từ 2026-08-08 tới nay**
(19 commit trên `main`), gói trong **PR #27** — CI `quality gates` xanh,
208 test, mergeable. `main` vẫn đứng ở 2026-08-08: **đọc nhánh này, đừng đọc
`main`**, cho tới khi #27 được merge.

Trong #27: kiểm chứng 12 toạ độ · seed `--prune` · đo khoảng cách check-in ở
server · nội dung đóng gói sẵn · cổng check-in + bản đứng thay · lăng kính Fog,
Sưu tầm, Hành trình (Quest + Lộ trình) · giao diện sticker cartoon · onboarding ·
tối ưu sương mù · 265 điểm OSM + nhiệm vụ dạng bộ sưu tập.

---

## 1. Đang ở đâu

| Phase | Trạng thái |
|-------|-----------|
| **F0** — Kho mã & quy ước | ✅ Đóng · tag `foundation-f0` |
| **F1** — Skeleton app | ✅ Đóng · tag `foundation-f1` |
| **F2** — Nền dữ liệu | 🟡 4/5 DoD · còn **tắt mạng trên máy thật** |
| **S** — 3 spike | ⛔ Chưa bắt đầu · cần thực địa |
| **F3** — Bản đồ nền | 🟡 còn **FPS trên máy thật** + chốt lại DoD marker |
| **F4** — Tầng mở khoá | 🟡 phần lớn mã đã có trong #27; **bán kính chờ S3** |
| **F5** — Lát cắt dọc | 🟡 Fog + chuyển lăng kính đã chạy trong #27; chưa đo trên máy thật |

Mã đã chạy **trước** kế hoạch; cái còn thiếu hầu hết là việc phải làm **ngoài
máy dev** (máy thật, ra đường).

`main` được bảo vệ: **mọi thay đổi phải qua PR + CI xanh**.

### F2 chi tiết

| DoD | |
|---|---|
| Migration chạy lại từ DB rỗng | ✅ lại lần nữa 2026-09-19: `supabase db reset` áp đủ 5 migration |
| RLS từ chối đọc `visit_state` người khác | ✅ 6 phép thử |
| Seed 2 lần không nhân đôi | ✅ 2026-09-19 trên Supabase local: 277 dòng sau cả 2 lần (cần `--allow-unverified` vì 265 điểm OSM) |
| App đọc từ server và hiển thị | ✅ trên Redmi Note 12 thật |
| Tắt mạng vẫn còn dữ liệu | 🟡 tầng dữ liệu có test `live`; **chưa nhìn trên máy** |
| Tag `foundation-f2` | ⛔ chờ mục trên |

> ⚠️ **Seed production sẽ từ chối** chừng nào còn điểm `verified: false` trong
> `content/checkpoints.json`. Hoặc kiểm chứng 265 điểm, hoặc chỉ seed với cờ và
> chấp nhận rủi ro toạ độ — **quyết định của chủ dự án**.

### F3 chi tiết

| DoD | |
|---|---|
| Khác biệt rõ so với map mặc định | ✅ (style giờ là cartoon, sinh từ `design/map/map_style.dart`) |
| Nước/cây/đường/nền đúng mã màu | ✅ |
| Sáng và tối là hai bản đồ riêng | ✅ |
| Tắt mạng → vùng cache vẫn hiện | ✅ |
| Marker đúng toạ độ | 🟡 **đổi hướng**: marker giờ là **sticker công trình** (docs/09 mục 0), không còn chờ ảnh thật. Sticker là hình tạm từ `content/landmarks/generate.py` |
| Cuộn/phóng ≥ 55 FPS máy tầm trung | ⛔ **cần máy thật** |

---

## 2. Chặn ở chủ dự án — xếp theo mức chặn

1. **Review + merge PR #27.** Mọi thứ khác xếp sau nó.
2. **Một lần cầm máy thật** — đóng cùng lúc: FPS ≥ 55 (F3), nhãn bản đồ + dấu
   tiếng Việt, chấm vị trí, và DoD tắt mạng của F2. Emulator vĩnh viễn không trả
   lời được mấy thứ này (mục 4).
3. **Ảnh chụp chế độ tối** cho giao diện sticker — DoD còn thiếu của #27.
4. **265 điểm OSM `verified: false`** — kiểm chứng (quá nhiều để xem tay từng
   cái) hay seed kèm cờ? Chặn seed production.
5. **Phase S** — 3 spike FPS / %pin / sai số GPS, cần ra đường. **S3 quyết định
   bán kính check-in.** Lăng Ông Bà Chiểu lệch 83m so với bán kính 60m; quán ăn
   40m, công viên/TTTM tới 150m đang là số ước lượng.
6. **Landmark 81** — Việt Nam không có freedom of panorama theo Commons. Rẻ
   nhất là thay bằng điểm khác (chi tiết `content/image-licenses.md`).
7. **Sticker công trình** là hình tạm — cần hoạ sĩ vẽ lại.
8. **12 chương truyện** (lăng kính Story) — định dạng đã có, chờ nội dung.
9. **Tên chính thức** — không gấp.

---

## 3. Quyết định đã chốt

**Phiên 2026-09-19**
- **Giao diện sticker cartoon** (docs/09 mục 0) thắng các mục cũ khi mâu thuẫn:
  viền mực, bóng cứng, màu bão hoà, sticker công trình thay icon chung, icon 3D
  giữ cho điều khiển. Marker **không** còn dùng ảnh thật.
- **Pilot mở rộng** (docs/08, khối "Sửa 2026-09-19"): 12 điểm gốc + 265 điểm OSM,
  5 loại mới (`park`, `shopping`, `food`, `sight`, `entertainment`) có migration
  enum ở Supabase. Bán kính theo loại.
- **Quest có hai kiểu**: `route` (có thứ tự) và `set` (bộ sưu tập, khai được
  `categories` thay vì liệt kê id). 11 nhiệm vụ. Tiến độ luôn suy ra từ `visit_state`.
- **Vệt đã đi không phải trạng thái mở khoá** — chỉ làm sáng bản đồ (bảng
  `explored_point_rows`).
- **Bản trình diễn** (không Supabase): kéo bản đồ là đi, zoom không đi; chỉ mở
  khoá khi **đi từ ngoài vào** bán kính. Không bao giờ bật khi có server.
- **Sương vẽ ở ảnh 1/4 độ phân giải** rồi phóng lên; các phương án đã thử và bỏ
  ghi trong `fog_overlay.dart`. Zoom < 14.5 vẽ chấm bằng một painter.
- **Marker không nhận chạm** (overlay `IgnorePointer`); chạm được suy ra từ toạ
  độ trên bản đồ. Cần `trackCameraPosition: true`.
- Onboarding 3 trang, hiện một lần; **quyền vị trí chỉ xin từ nút bấm**.

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
- ~~Marker checkpoint dùng **ảnh thật**~~ — **đã thay 2026-09-19 bằng sticker công trình**. Ghi chú cũ: — đã sửa dòng sót ở mục 6 art direction cho
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

Số test theo nhánh: `main` 55 · +#16 = 59 · +#17 = 61 · +#20 = 67 · #27 = 208.

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

## 8c. Bài học của phiên 2026-09-19

**Đo hiệu năng trên emulator chỉ có nghĩa ở dạng tỉ lệ.** Emulator raster bằng
CPU nên số tuyệt đối vô nghĩa, nhưng **cùng một kịch bản vuốt** chạy trên hai bản
build cho ra tỉ lệ đáng tin (sương: raster p50 khi zoom gần 610ms → 77ms).

**Một truy vấn "watch" đọc lại cả bảng mỗi lần insert** — mỗi bước kéo bản đồ
trả giá bằng toàn bộ lịch sử vệt. Nạp một lần, giữ trong bộ nhớ.

**Blur trên save layer `dstOut` bị bỏ qua im lặng.** Lại một thất bại im lặng.

**Camera mặc định nằm trong bán kính Hội trường Thành phố** — bản cài mới mở ra
đã "1/277". Sửa: chỉ mở khoá khi *đi vào* bán kính, không phải khi *đang ở trong*.

---

## 9. Việc kế tiếp

Xếp theo lượng việc mở ra được, nhiều nhất trước.

1. **Merge #27** → `main` bắt kịp; mọi PR sau đó nhỏ và tách được.
2. **Buổi máy thật** → đóng F2 (tag `foundation-f2`) và mục FPS của F3.
3. **Chủ dự án quyết 265 điểm OSM** → seed production được.
4. **Phase S** → có bán kính thật → đóng F4.

**Việc agent làm được mà không bị chặn:** chụp ảnh chế độ tối trên emulator
(nhớ: RAM không đủ chạy emulator cùng Docker — `npx supabase stop` trước);
xử lý marker chồng nhau ở Quận 1 khi ở zoom thành phố.

**Đừng chốt bán kính** khi phase S chưa có số.
