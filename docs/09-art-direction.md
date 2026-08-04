# Hướng nghệ thuật (ĐÃ CHỐT)

> Ngày chốt: 2026-08-04 · Nguồn: bản tham khảo của chủ dự án
> Tài liệu này là **hợp đồng thiết kế** — mockup và code phải tuân theo, không tự diễn giải lại.

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

- Nhuộm lại toàn bộ theo palette: nước `#CDE9F5`, cây xanh `#DCEFD9`, đường `#FFFFFF` viền `#E6E9EE`, nền `#F4F1EA`
- Giảm nhãn tối đa — chỉ giữ tên đường lớn; app này không dùng để chỉ đường
- Không đổ bóng công trình, không hiệu ứng 3D building mặc định
- Marker checkpoint là **illustration của chính địa điểm đó**, không phải ghim chung chung

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
| **Icon điều hướng** | ~15 | **Mua asset pack 3D** | Không cần đặc thù Việt Nam — mua là rẻ và nhanh nhất |
| **Nhân vật dẫn truyện** | 1 | **Thuê** | Tài sản thương hiệu, phải sở hữu bản quyền |
| **Tem / huy hiệu** | 12 | **Dẫn xuất từ ảnh địa danh** (cắt cúp + khung illustration) | Gần như miễn phí, tự động nhất quán với marker trên bản đồ |

**AI dùng ở đâu:** phác thảo concept và thử bố cục để duyệt nhanh. **Không dùng AI sinh ảnh địa danh** — sai chi tiết kiến trúc là lỗi không chấp nhận được với một app dạy về địa điểm thật.

**Yêu cầu bàn giao:** ảnh đã xử lý theo preset, @1x/2x/3x, kèm **bảng ghi nguồn và giấy phép từng ảnh** trong `content/`. Icon và nhân vật: PNG nền trong suốt + file Rive cho phần cần chuyển động.

---

## 8. Fog of War trong hệ màu sáng

**Vấn đề:** bản tham khảo để màn Fog tối trong khi 5 màn còn lại sáng → trông như hai app.

**Luật chốt:** Fog là **chế độ**, không phải theme. Cả hai theme đều phải có bản Fog riêng.

| | Chế độ sáng | Chế độ tối |
|---|---|---|
| Vùng chưa đi | Bản đồ **xám hoá + phủ kem mờ**, ảnh địa danh **khử màu, độ tương phản thấp** | Bản đồ tối `#14161C`, ảnh khử màu và tối đi |
| Vùng đã đi | Bản đồ đủ màu, ảnh địa danh **hiện đủ màu** | Bản đồ sáng lên, ảnh hiện đủ màu |
| Ẩn dụ | **Màu trở lại với nơi bạn đã đến** | Ánh sáng lan ra |

Cách này giữ được kịch tính khám phá mà không bắt người dùng đang ở theme sáng phải nhảy sang màn đen.

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
- ❌ Gradient trên chữ, nút, icon
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
