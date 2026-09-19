# Hướng nghệ thuật (ĐÃ CHỐT)

> Ngày chốt: 2026-08-04 · Nguồn: bản tham khảo của chủ dự án
> Tài liệu này là **hợp đồng thiết kế** — mockup và code phải tuân theo, không tự diễn giải lại.

---

## 0. Sticker cartoon (ĐÃ CHỐT 2026-09-19) — thay các mục bên dưới khi mâu thuẫn

> Chủ dự án thấy giao diện cũ "quá bình thường, như app hàn lâm" và chọn hướng
> **sticker cartoon + icon 3D**. Mockup đã duyệt: canvas "Wanderlock Sticker UI".
> Mục này **thắng** mọi quy tắc cũ bên dưới khi hai bên nói khác nhau.

**Câu định nghĩa mới:** mọi thứ trông như sticker dán lên màn hình — viền mực đậm,
bóng cứng đổ thẳng xuống, màu bão hoà, chữ Baloo 2 đậm cho mọi thứ mang tính game.

| Thành phần | Quy tắc | Token |
|---|---|---|
| Viền | Mực `#2B2140` (sáng) / oải hương `#8C80B8` (tối — **sáng hơn thẻ**, đo được 1,33:1 nếu dùng màu tối) | `AppColors.outline`, `AppSticker.stroke*` |
| Bóng | Cứng, không blur, đổ thẳng xuống 3–9px | `AppShadows.sticker`, `AppSticker.depth*` |
| Nền trang | Kem `#FFF4DE`; lăng kính toàn màn hình dùng **nền bạc hà chấm bi** | `PatternBackground` |
| Nút chính | Viên thuốc vàng `#FFC93C`, chữ mực, bấm là lún xuống bóng của nó | `StickerButton` / `PrimaryButton` |
| Tem | Nghiêng nhẹ xen kẽ, răng cưa đứt nét bên trong | `AppSticker.tilt`, `isPerforated` |
| Địa điểm | **Sticker công trình** (vẽ tạm, nguồn ở `content/landmarks/`) thay icon chung; icon 3D giữ cho điều khiển và trạng thái | `LandmarkArt` |
| Bản đồ | Cartoon: nước xanh ngọc và cỏ có viền vẽ, đường trắng viền nâu nhạt, **đại lộ vàng**, đường dày hơn | `AppMapColors.roadMajor`, `waterEdge`, `greenEdge` |
| HUD | Chỉ những gì v1 có: X/12 địa điểm và số tem. **Không** cấp độ, tiền tệ, xếp hạng | `ExploreHud` |
| Sương mù | Kiểu Liên Minh: vùng sáng **loang**, viền mờ, các vùng chảy vào nhau — không còn đĩa tròn viền cứng. Sáng theo **cả đường đã đi** (vệt 160 m), không chỉ tại điểm. Vẽ bằng Flutter vì lớp fill của MapLibre không làm mờ được | `FogOverlay`, `FogTrail` |

**Vệt đường đi không phải trạng thái mở khoá.** Vệt chỉ làm sáng bản đồ, lưu trên máy
(`explored_point_rows`); checkpoint vẫn chỉ mở qua check-in và `visit_state`.
Ở bản không có máy chủ, **vuốt bản đồ là đi**: vuốt tới đâu sáng tới đó, đi qua
bán kính một điểm thì gửi check-in như khi đến thật. **Zoom không phải là đi** — người
chơi đứng yên khi zoom, zoom xong camera trượt về chỗ họ. Vuốt được từ bất cứ đâu, kể
cả bắt đầu trên marker (marker không nhận chạm; bấm marker được nhận ra từ toạ độ chạm
trên bản đồ). Bản có máy chủ không bao giờ dùng camera làm vị trí.

**Quy tắc cũ bị thay:**
- Mục 2.3 luật 1 (tối đa 3 màu nhấn) và luật 5 (bề mặt trung tính) — **bỏ**. Nhiều màu
  được phép; bù lại mọi cặp chữ/nền vẫn phải ≥ 4.5:1, có test trong `contrast_test.dart`.
- Mục 5 (neumorphism) — **bỏ**. Bóng cứng dùng được cả trên bản đồ vì nó là nét vẽ,
  không phải hiệu ứng ánh sáng.

**Giữ nguyên:** hồng `#FF48A0` chỉ trong 3 giây mở khoá (tia sáng `unlockRay` cũng bị
cấm như vậy — test canh), màu = trạng thái (chưa đến thì khử màu), font đóng gói offline.

---

## 1. Câu định nghĩa phong cách

> **Neumorphism nhẹ trên nền kem, bo góc lớn, màu pastel tươi trẻ, illustration 3D mềm.**
> Cảm giác: thân thiện, sạch, đáng tin, hơi đồ chơi — **không** hoài cổ, **không** tối tăm, **không** kỹ thuật lạnh.

Ba sợi ADN: **brochure du lịch** (khối lớn, ảnh minh hoạ, bố cục thoáng) × **công nghệ** (số liệu, tiến độ, trạng thái) × **game khám phá** (mở khóa, huy hiệu, HUD nhẹ).

---

## 2. Bảng màu

### 2.1 Chế độ sáng (mặc định)

| Vai trò | Mã | Dùng ở đâu |
|---------|-----|-----------|
| Nền trang | `#F7F8FA` | nền toàn app |
| Mặt thẻ | `#FFFFFF` | thẻ, sheet, ô |
| Mực (chữ chính) | `#1F2430` | tiêu đề, nội dung |
| Chữ phụ | `#6B7280` | mô tả, nhãn |
| **Xanh chủ đạo** | `#4CCB8A` | mảng màu, icon, trạng thái |
| **Xanh nút** | `#17875A` | ⚠️ **bắt buộc** cho mọi nút nền xanh có chữ trắng |
| Vàng | `#FFD166` | CTA phụ (chữ luôn dùng `#5A4210`) |
| San hô | `#FF6B6B` | cảnh báo, điểm chưa mở |
| Xanh dương | `#4DBDFF` | thông tin, tuyến đường |
| Tím / bạc hà | `#A26BFF` `#7ED6C1` | **chỉ trang trí**, không mang nghĩa |
| **Hồng mở khóa** | `#FF48A0` | ⚠️ **chỉ dùng trong 3 giây mở khóa**, cấm ở mọi nơi khác |

### 2.2 Chế độ tối

| Vai trò | Mã |
|---------|-----|
| Nền trang | `#14161C` |
| Mặt thẻ | `#1E212A` |
| Chữ chính | `#F2F4F7` |
| Chữ phụ | `#9AA3B2` |
| Xanh chủ đạo | `#5FD79B` |
| Vàng | `#FFD87A` |
| San hô | `#FF8585` |
| Xanh dương | `#6BC9FF` |

### 2.3 Luật màu (bắt buộc)

1. **Tối đa 3 màu nhấn trên một màn hình.** Bản tham khảo dùng 6 — phải giảm.
2. **Cấm pastel trên pastel.** Mọi cặp chữ/nền phải đạt tương phản ≥ 4.5:1 (chữ thường), ≥ 3:1 (chữ lớn).
3. **Gradient chỉ dùng làm nền trang trí lớn**, không dùng trên chữ, nút, hay icon.
4. Tím và bạc hà **không được mang ý nghĩa trạng thái** — chỉ làm nền minh hoạ.
5. **Bề mặt trung tính; màu do icon và hình khối gánh** (chủ dự án chốt 2026-08-25).
   Thẻ, ô tem, chip lăng kính, nút vị trí — tất cả dùng trắng `#FFFFFF` hoặc
   xám trắng `#EDEFF3`, **không tô nền xanh**. Cái đổi màu là icon 3D và các
   hình vẽ trên bản đồ.
   - **Màu = trạng thái.** Icon đủ màu nghĩa là *đã đạt / đang bật*; icon khử
     màu nghĩa là *chưa / đang tắt*. Cùng một ẩn dụ với Fog ở mục 8 —
     "màu trở lại với nơi bạn đã đến".
   - Hai bề mặt trung tính chồng nhau (chip trên thanh, ô tem trên trang) tách
     nhau bằng `card` so với `surfaceMuted`. Chênh lệch **cố ý yếu** — mạnh hơn
     là tranh chỗ với icon.
   - ⚠️ Chữ phụ `#6B7280` **không đọc được** trên `#EDEFF3` (đo được 3,9:1,
     dưới ngưỡng 4,5:1). Trên bề mặt xám trắng phải dùng mực chính. Có test ghi
     lại phép đo này.

---

## 3. Chữ

| Vai trò | Cỡ / độ đậm |
|---------|-------------|
| Tiêu đề màn | 24 / 600 |
| Tiêu đề thẻ | 17 / 600 |
| Nội dung | 15 / 400, line-height 1.6 |
| Nhãn phụ | 13 / 400 |
| Số liệu, khoảng cách, toạ độ | dùng **chữ số tabular**, canh phải |

### Font đã chọn

| Vai trò | Font | Lý do |
|---------|------|-------|
| UI, nội dung, nút | **Be Vietnam Pro** | Thiết kế bởi người Việt, dấu tiếng Việt là mối quan tâm hàng đầu chứ không phải phần thêm vào. 9 độ đậm, trung tính, không đánh nhau với illustration |
| Tiêu đề lớn, số điểm, huy hiệu | **Baloo 2** | Bo tròn, vui, khớp illustration clay |
| Số liệu | chữ số **tabular** của Be Vietnam Pro | Không thêm font mono — bớt một font là bớt một nguồn lỗi dấu |

**Hai ràng buộc kèm theo**

1. **Đóng gói font vào app**, không tải lúc chạy. App phải chạy offline; nếu tải runtime thì lần đầu mất mạng sẽ rơi về font hệ thống và vỡ bố cục.
2. **Bắt buộc test dấu thật trước khi khoá** — lỗi dấu thường chỉ lộ ở độ đậm cao và khi chồng dấu: `ế ỡ ộ ữ ẫ`. Đây là một mục DoD của phase F1.

---

## 4. Hình khối & bo góc

| Thành phần | Bo góc |
|-----------|--------|
| Nút | pill (bo tràn) |
| Thẻ | 24px |
| Bottom sheet | 28px (chỉ 2 góc trên) |
| Chip, ô nhỏ | 16px |
| Marker bản đồ | tròn hoàn toàn |

Không có góc vuông ở bất kỳ đâu, **trừ chính bề mặt bản đồ**.

---

## 5. Neumorphism — dùng ở đâu, cấm ở đâu

Neumorphism cần **nền phẳng đồng màu** và **ánh sáng kiểm soát được**. App này dùng ngoài trời và đè lên bản đồ, nên phải giới hạn:

### ✅ Được dùng
- Bottom sheet, thẻ trên nền kem phẳng
- Màn Bộ sưu tập — hiệu ứng **tem lõm vào giấy** rất hợp
- Ô icon, nút phụ, thanh chuyển lăng kính khi nằm trên nền đặc
- Thông số: bóng ngoài `4px 4px 10px rgba(31,36,48,0.08)`, bóng trong sáng `-4px -4px 10px rgba(255,255,255,0.9)`

### ❌ Cấm dùng
- **Mọi thành phần nằm trực tiếp trên bản đồ** — bóng mềm tan vào nền nhiều màu
- Nút hành động chính (mở khóa, bắt đầu quest) — phải là **khối màu đặc**, viền hoặc bóng cứng
- Bất kỳ chỗ nào chữ nằm trên nền cùng tông

> Quy tắc một câu: **neumorphism cho bề mặt, khối đặc cho hành động.**

---

## 6. Bản đồ — chống generic

Đây là chỗ dễ hỏng nhất. Bản đồ **không được dùng style mặc định** của nhà cung cấp.

- Nhuộm lại toàn bộ theo palette: nước `#CDE9F5`, cây xanh `#DCEFD9`, đường `#FFFFFF` viền `#C9CFDB`, nền `#F4F1EA`
- Giảm nhãn tối đa — chỉ giữ tên đường lớn; app này không dùng để chỉ đường
- Nhãn đường dùng **mực `#1F2430`** ở chế độ sáng, `#9AA3B2` ở chế độ tối
- Ranh giới hành chính có màu riêng (`#E6E9EE` sáng, `#11131A` tối) — **không dùng lại màu viền đường**
- Không đổ bóng công trình, không hiệu ứng 3D building mặc định
- Marker checkpoint là **ảnh thật của chính địa điểm đó** đã qua preset xử lý ở mục 7.1, không phải ghim chung chung và không phải illustration

> **Sửa 2026-08-08 — hai màu ở trên đã đổi, đây là lý do.**
>
> Viền đường cũ `#E6E9EE` chỉ đạt **1.08:1** so với nền `#F4F1EA`, và bản tối
> **1.03:1** — tức là cùng một màu với mặt đất. Đường vẽ ra thành dải phẳng
> không viền, đúng thứ mà cái viền sinh ra để tránh. Viền mới `#C9CFDB` đạt
> 1.56:1 so với mặt đường và 1.39:1 so với nền.
>
> Ở chế độ **tối, viền phải SÁNG hơn mặt đường** (`#454C5B`), ngược chiều với
> chế độ sáng. Nền tối đã gần đen sẵn, nên một cái viền tối hơn nữa thì biến
> mất — không màu nào tối hơn mặt đường mà còn tách được khỏi nền.
>
> Nhãn đường cũ mượn `#6B7280` của UI, chỉ đạt **4.29:1** trên nền bản đồ ở cỡ
> 11px — dưới chính ngưỡng 4.5:1 mà mục 2.3 của tài liệu này bắt buộc. Nhãn bản
> đồ giờ có token riêng vì nó nằm trên **bốn** bề mặt (nền, nước, cây xanh, mặt
> đường), không phải trên thẻ.
>
> Đánh đổi đã biết: mực `#1F2430` làm nhãn nổi hơn, hơi kéo căng với luật "giảm
> nhãn tối đa" ngay phía trên. Bù lại bằng cách giữ nguyên allow-list — chỉ
> `motorway`, `trunk`, `primary` mới có tên. Ít nhãn hơn, nhưng nhãn nào có thì
> đọc được.

---

## 7. Illustration

### 7.1 Địa danh dùng **ảnh thật**, không dùng illustration

Người dùng cần nhận ra địa điểm **trước mặt mình** — ảnh thật làm việc đó tốt hơn illustration.

**Nguồn ảnh (bắt buộc rõ bản quyền)**
| Nguồn | Ghi chú |
|-------|---------|
| **Tự chụp** | Ưu tiên. Kiểm soát được góc, ánh sáng, và sở hữu hoàn toàn |
| Wikimedia Commons / kho ảnh giấy phép mở | Phải đọc kỹ điều kiện ghi nguồn của **từng ảnh** |
| Mua stock | Khi không tự chụp được |

> ⛔ Không lấy ảnh từ kết quả tìm kiếm. Mỗi ảnh phải ghi lại nguồn và giấy phép trong `content/`.

**Xử lý ảnh — đây là phần quyết định app trông có phải một hệ thống hay không**

Ảnh thật đặt cạnh UI bo tròn pastel sẽ lệch tông nếu để nguyên. Mọi ảnh phải qua **cùng một công thức**:
- Cân màu ấm nhẹ, kéo bão hoà xuống một chút để không đánh nhau với màu nhấn của app
- Hạt film rất nhẹ
- Bo góc theo thang bo góc ở mục 4
- **Tỉ lệ khung cố định** theo từng vị trí dùng (marker tròn, thẻ 4:3, ảnh bìa chương truyện 16:9)

Công thức này phải viết ra thành preset và áp cho **toàn bộ** ảnh, không chỉnh tay từng tấm.

### 7.2 Illustration vẫn dùng — nhưng không cho địa danh

| Dùng illustration cho | Không dùng |
|-----------------------|-----------|
| Bộ icon điều hướng | ❌ Địa danh |
| Nhân vật dẫn truyện | ❌ Marker bản đồ |
| Màn trống, màn lỗi, onboarding | ❌ Ảnh bìa chương truyện |
| Khung/nhãn của tem | ❌ Tem (phần ruột là ảnh) |

**Phong cách illustration:** 3D mềm (clay) — bề mặt mờ không bóng, một nguồn sáng dịu từ trên-trái, bóng đổ mềm nhạt, bo tròn mọi cạnh, palette giới hạn trong bảng màu app, nền trong suốt.
Cấm: phản chiếu kim loại, glow, đổ bóng gắt, chi tiết vụn.

### 7.3 Kế hoạch sản xuất (ĐÃ CHỐT)

**Nguyên tắc: tách theo loại tài sản, không dùng một cách cho tất cả.**

| Loại | SL | Cách làm | Lý do |
|------|:--:|----------|-------|
| **Ảnh địa danh** | 12 | **Tự chụp** (ưu tiên) hoặc kho ảnh giấy phép mở / mua stock, rồi áp preset xử lý chung | Rẻ nhất, nhận diện tốt nhất. Chi phí dồn vào khâu **xử lý đồng bộ**, không phải khâu tạo |
| **Icon điều hướng** | ~26 | **[3dicons.co](https://3dicons.co)** (CC0) — lấy biến thể **`color`**, **dùng nguyên màu gốc** | Không cần đặc thù Việt Nam — nguồn có sẵn, miễn phí, và màu sẵn có hợp hướng trẻ trung |
| **Nhân vật dẫn truyện** | 1 | **Thuê** | Tài sản thương hiệu, phải sở hữu bản quyền |
| **Tem / huy hiệu** | 12 | **Dẫn xuất từ ảnh địa danh** (cắt cúp + khung illustration) | Gần như miễn phí, tự động nhất quán với marker trên bản đồ |

**Ghi chú nguồn icon điều hướng — đánh giá 2026-08-25, sửa lại cùng ngày**

3dicons.co có 120 icon (không phải 200), mỗi icon 4 biến thể vật liệu: `color`,
`clay`, `gradient`, `premium`.

> **CHỦ DỰ ÁN ĐỔI QUYẾT ĐỊNH — 2026-08-25.** Bản đánh giá buổi sáng chốt dùng
> `clay` rồi tự nhuộm màu. Chủ dự án chọn **`color`, giữ nguyên màu gốc**, lý do:
> app định hướng trẻ trung và nhiều màu. Mục này ghi lại quyết định đó; hai chỗ
> nó chạm vào danh sách cấm ghi ở dưới.

**Đã đo trên file tải về, không phải đọc mô tả:**

| | `clay` | `color` |
|---|---|---|
| Kích thước | 400×400 PNG, nền trong suốt | 400×400 PNG, nền trong suốt |
| Màu | **100% pixel đục là đơn sắc**, luma 137–239 | Bão hoà 0,55–0,84 |
| Dải màu | không có | cam 34° · xanh lá 95° · xanh ngọc 164–190° · xanh dương 245°; riêng `key` là bạc xám |
| Cần nhuộm không | **Bắt buộc** | **Không** — dùng nguyên bản |

Mô tả cũ *"`color` = bóng, gradient cam/đỏ"* là **sai**: bộ này trải khắp vòng
màu chứ không chỉ cam/đỏ. Ảnh chụp trang explore của 3dicons xác nhận: khiên
xanh ngọc, sổ xanh dương, ví nâu, dấu tick xanh.

**Hai chỗ chạm danh sách cấm (mục 10):**

1. *"Gradient trên chữ, nút, icon"* — icon `color` có chuyển sắc trên khối 3D.
   **Ngoại lệ được duyệt cho icon**, vì đó là đổ bóng của một vật thể ba chiều
   chứ không phải gradient trang trí phết lên một hình phẳng. Luật vẫn giữ
   nguyên với **chữ và nút**.
2. *"Tối đa 3 màu nhấn trên một màn hình"* (mục 2.3) — đây mới là luật thật sự
   bị tiêu tốn. Mỗi icon tự mang màu của nó vào màn hình, nên **phải đếm màu
   khi chọn icon cho từng màn**, không phải chọn theo nghĩa rồi thôi.

Ràng buộc kỹ thuật vẫn đúng cho cả hai biến thể:
- Tải về chỉ có PNG/webp dựng sẵn, **không có** model glb/Blender nguồn.
- Icon đến từ nhiều đợt vẽ khác nhau của cùng bộ — khi chọn, kiểm tra tỷ lệ và
  độ dày hình khối giữa các icon đã chọn để không bị lệch bộ.
- CC0 không bắt buộc ghi nguồn, nhưng vẫn ghi ở `content/icon-licenses.md` cho
  nhất quán với cách quản lý ảnh ở mục 7.1.

**Mỗi địa điểm một icon riêng (chốt 2026-08-25).** Marker trên bản đồ không
dùng chấm tròn nữa mà dùng icon 3D, và **không phải icon theo phân loại**:
phong thư cho Bưu điện, tên lửa cho Landmark 81, va-li cho Bến Nhà Rồng, vương
miện cho Lăng Ông, cờ cho Dinh Độc Lập, túi cho hai khu chợ, nén nhang cho bốn
ngôi chùa. Bốn cái chợ-chợ-bảo tàng-dinh vẽ thành bốn cái ghim giống nhau là
một bảng chú giải, không phải một tấm bản đồ — chọn thế này để **đọc được hình
dạng thành phố trước khi đọc một chữ nào**. Bảng tra ở
`app/lib/features/checkpoint/presentation/checkpoint_icons.dart`.

**Cỡ icon tăng ~50% toàn bộ (2026-08-25).** Sau khi bỏ nền màu, icon là thứ duy
nhất còn mang màu; ở cỡ cũ chúng đọc ra như dấu đầu dòng cạnh chữ chứ không phải
chủ thể.

**Neumorphism đã dùng đúng chỗ tài liệu chỉ định.** Màn Sưu tầm: tem đã mở
**nổi lên** (`raised`), tem chưa mở **lún vào giấy** (`inset`) — đúng mô tả sẵn
có trong `app_shadows.dart`. Vẫn **không** dùng trên bản đồ: marker chỉ có viền
đặc, vì nền dưới nó là một thành phố chứ không phải mặt phẳng sáng đều.

**Bộ `clay` vẫn giữ trong `content/icons/3dicons-clay/`** dù không dùng: nếu sau
này có bề mặt cần icon một màu theo token thì đã có sẵn, khỏi tải lại.

**⚠️ Bộ 120 icon thiếu 5 thứ dự án sẽ cần:** đóng (×), tải lại, tải bản đồ
offline, **QR** (mục 5.6 của scope), **chia sẻ** (màn Bản đồ ký ức). Ba cái đầu
hiện vẫn dùng Material Icons, có chú thích `clay-icon-gap` tại chỗ và có test
đếm để con số không lặng lẽ tăng. Chưa quyết cách xử lý — xem
`content/icon-licenses.md`.

**AI dùng ở đâu:** phác thảo concept và thử bố cục để duyệt nhanh. **Không dùng AI sinh ảnh địa danh** — sai chi tiết kiến trúc là lỗi không chấp nhận được với một app dạy về địa điểm thật.

**Yêu cầu bàn giao:** ảnh đã xử lý theo preset, @1x/2x/3x, kèm **bảng ghi nguồn và giấy phép từng ảnh** trong `content/`. Icon và nhân vật: PNG nền trong suốt + file Rive cho phần cần chuyển động.

---

## 8. Fog of War — luôn tối

**Luật chốt (chủ dự án, 2026-09-08): Fog tối ở CẢ HAI theme.**

Ẩn dụ là **cắm mắt trong LMHT**: chỗ chưa tới thì thật sự tối, chỗ đã tới thì
sáng lên. Tương phản đó *chính là* lăng kính. Đổi theme đổi bản đồ nền, không
đổi việc sương thì tối.

| | Cả hai theme |
|---|---|
| Vùng chưa đi | Phủ `#14161C` ở 82% — đủ tối để đọc ra là chưa biết, đủ mỏng để còn thấy dạng phố |
| Vùng đã đi | Nhấc lớp phủ, cộng một lớp sáng nhẹ 12%; viền xanh `#5FD79B` 40% |
| Ẩn dụ | **Ánh sáng lan ra** |

### Vì sao lật luật cũ

Luật cũ ghi *"Fog là chế độ, không phải theme"* — chế độ sáng dùng **phủ kem
mờ** để không quăng người dùng vào màn đen. Ý tốt, nhưng đo trên máy thì nó
**bằng không về mặt số học**:

```
đất       #F4F1EA = (244, 241, 234)
phủ kem   #F2EFE6 @ 60%
kết quả           = (243, 240, 232)
```

Chênh **1–2 trên 255**. Không phải mờ nhẹ — là không có gì. Không thể làm xám
một bản đồ kem bằng cách phủ kem lên nó; muốn xám hoá thì lớp phủ phải tối hơn
hoặc nhạt màu hơn hẳn nền.

Có một ghi chú cũ nói 86% "xoá sạch thành phố, đọc ra như trang giấy trắng" nên
hạ xuống 60%. Chẩn đoán đó nhắm sai chỗ: vấn đề nằm ở **màu**, không phải ở
**độ mờ**. 82% của một màu tối thì vẫn thấy phố, vì nó tối hơn nền chứ không
trùng nền.

> Ảnh địa danh trong vùng chưa đi vẫn **khử màu, tương phản thấp** như luật cũ.
> Phần đó không đổi — chỉ lớp phủ bản đồ đổi.

---

## 9. Chuyển động

- **Ngày thường:** mềm, có đàn hồi nhẹ, 200–300ms. Nhấn nút: thu về `scale(0.96)`.
- **3 giây mở khóa:** chỗ **duy nhất** được bung hết cỡ —
  1. Màu đổ lan ra từ vị trí người dùng
  2. Ảnh địa điểm chuyển từ **khử màu sang đủ màu**
  3. Tên địa điểm hiện
  4. Huy hiệu 3D rơi vào bộ sưu tập
  5. Hồng `#FF48A0` chỉ xuất hiện ở đây
  6. Kèm haptic + âm thanh ngắn
- **Màn Sưu tầm:** được phép dày và vui hơn các màn khác.

---

## 10. Danh sách cấm

- ❌ Bóng mềm neumorphic trên bản đồ hoặc trên nút hành động chính
- ❌ Quá 3 màu nhấn trên một màn hình
- ❌ Gradient trên chữ và nút — **icon 3D là ngoại lệ đã duyệt 2026-08-25**, xem mục 7.3
- ❌ Map style mặc định của nhà cung cấp
- ❌ Ảnh chưa qua preset xử lý chung (lệch tông là hỏng cả hệ thống)
- ❌ Ảnh không rõ nguồn / không rõ giấy phép
- ❌ Illustration thay cho địa danh (địa danh luôn dùng ảnh thật)
- ❌ Icon lấy sẵn từ bộ line generic
- ❌ Cặp màu dưới ngưỡng tương phản 4.5:1
- ❌ Hồng `#FF48A0` ngoài khoảnh khắc mở khóa
- ❌ Font chưa test dấu tiếng Việt
- ❌ Góc vuông (trừ bề mặt bản đồ)

---

## 11. Việc còn treo

1. ~~Chốt font~~ → đã chọn **Be Vietnam Pro** + **Baloo 2**. Còn lại: **test dấu thật** (DoD của F1)
2. ~~Chốt cách sản xuất~~ → đã chốt: **địa danh dùng ảnh thật**, illustration chỉ cho icon/nhân vật. Còn lại: **gom 12 ảnh có bản quyền rõ ràng + dựng preset xử lý**
3. Chốt style bản đồ tuỳ biến
4. ~~Chốt số lăng kính cho v1~~ → đã chốt **5** (thêm Tùy chỉnh hành trình; Xã hội hoãn sang v1.5)
5. ~~Chốt nguồn icon điều hướng~~ → đã chọn **3dicons.co** (CC0, biến thể **`color`**, giữ nguyên màu gốc — chủ dự án chốt 2026-08-25). Đã tải cả 120 icon và bundle 26 cái đang dùng. Còn lại: **quyết cách bù 5 icon bộ này không có** (đóng · tải lại · tải offline · QR · chia sẻ), và **soát lại luật 3 màu nhấn/màn hình** giờ khi icon tự mang màu (xem mục 7.3)
