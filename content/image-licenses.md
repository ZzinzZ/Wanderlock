# Bản quyền ảnh địa danh

Sổ bắt buộc. [README.md](README.md) chốt: **ảnh không có dòng trong bảng này thì
không được đưa vào app.** Không lấy ảnh từ kết quả tìm kiếm.

Marker checkpoint dùng **ảnh thật**, không dùng illustration — xem mục 6 và 7.1
của [../docs/09-art-direction.md](../docs/09-art-direction.md).

Mọi ảnh phải qua **cùng một preset xử lý** trước khi vào app. Preset chưa dựng;
đó là việc riêng, không phải việc của sổ này.

## Nguồn được chấp nhận

| Nguồn | Ghi chú |
|-------|---------|
| **Tự chụp** | Ưu tiên. Kiểm soát được góc, ánh sáng, và sở hữu hoàn toàn |
| Wikimedia Commons / kho ảnh giấy phép mở | Phải đọc điều kiện ghi nguồn của **từng ảnh**, không suy từ ảnh khác cùng kho |
| Mua stock | Khi không tự chụp được. Giữ hoá đơn |

Ghi **đúng tên giấy phép** (`CC BY-SA 4.0`, `CC0`, `Tự chụp — sở hữu toàn bộ`,
`Stock — <nhà cung cấp>, giấy phép <loại>`), không ghi "miễn phí" hay "free".
Cột *Yêu cầu ghi nguồn* chép nguyên văn dòng phải hiện trong app, hoặc `—` nếu
giấy phép không đòi.

## 12 checkpoint pilot — ĐÃ DUYỆT

Ảnh nằm ở `content/images/places/`, bản sao đóng gói ở
`app/assets/photos/places/`. Dùng làm **ảnh bìa chương truyện**; các chỗ khác
(màn "Đã mở khoá!", thẻ chi tiết) chưa nối.

> **Mỗi ảnh dưới đây đã được mở ra nhìn ở cỡ đủ lớn trước khi ghi vào bảng.**
> Đó không phải chuyện thừa: xếp hạng tự động theo tên tệp đã chọn phải ảnh
> bên trong chợ Bến Thành, ảnh bảo tàng quân sự ở **Hà Nội** cho bảo tàng
> chiến tranh ở Sài Gòn, và một bức tranh treo tường cho Dinh Độc Lập. Tiêu
> chí: mặt ngoài công trình, nhận ra ngay, không nội thất, không chi tiết,
> không bảng chữ.
>
> Lựa chọn ghi ở `tool/photo_picker/chosen.json`; đổi tên tệp ở đó rồi chạy
> `dart run tool/photo_picker/fetch_photos.dart` là thay được ảnh. Giấy phép
> bên dưới đọc thẳng từ Commons lúc tải, không chép tay.
>
> Ảnh phục vụ ở bề rộng 900 px — vừa cho màn điện thoại, và giữ mỗi tệp quanh
> 250 KB thay vì vài megabyte bản gốc. Tổng 12 ảnh: 3,1 MB.

| Tệp | Địa điểm | Nguồn | Giấy phép | Yêu cầu ghi nguồn | Ngày lấy |
|-----|----------|-------|-----------|-------------------|----------|
| `images/places/independence-palace.jpg` | Dinh Độc Lập | [Commons](https://commons.wikimedia.org/wiki/File%3AReunification%20Palace%20front%20view.jpg) | CC BY-SA 3.0 | Amore Mio / Wikimedia Commons — CC BY-SA 3.0 | 2026-09-27 |
| `images/places/central-post-office.jpg` | Bưu điện Trung tâm Sài Gòn | [Commons](https://commons.wikimedia.org/wiki/File%3AOficina%20Central%20de%20Correos%2C%20Ciudad%20Ho%20Chi%20Minh%2C%20Vietnam%2C%202013-08-14%2C%20DD%2006.JPG) | CC BY-SA 3.0 | Diego Delso / Wikimedia Commons — CC BY-SA 3.0 | 2026-09-27 |
| `images/places/ben-thanh-market.jpg` | Chợ Bến Thành | [Commons](https://commons.wikimedia.org/wiki/File%3ABen%20Thanh%2C%20Ciudad%20Ho%20Chi%20Minh%2C%20Vietnam%2C%202013-08-14%2C%20DD%2001.JPG) | CC BY-SA 3.0 | Diego Delso / Wikimedia Commons — CC BY-SA 3.0 | 2026-09-27 |
| `images/places/war-remnants-museum.jpg` | Bảo tàng Chứng tích Chiến tranh | [Commons](https://commons.wikimedia.org/wiki/File%3AWar%20Remnants%20Museum%2C%20HCMC%2C%20front.JPG) | CC BY-SA 3.0 | Prenn / Wikimedia Commons — CC BY-SA 3.0 | 2026-09-27 |
| `images/places/vinh-nghiem-pagoda.jpg` | Chùa Vĩnh Nghiêm | [Commons](https://commons.wikimedia.org/wiki/File%3ATu%20vi%E1%BB%87n%20V%C4%A9nh%20Nghi%C3%AAm%2C%20h%E1%BA%ADu%20%C4%91%C6%B0%E1%BB%9Dng%20(khung%20c%E1%BA%A3nh)%20(24).jpg) | CC BY-SA 4.0 | Phương Huy / Wikimedia Commons — CC BY-SA 4.0 | 2026-09-27 |
| `images/places/binh-tay-market.jpg` | Chợ Bình Tây | [Commons](https://commons.wikimedia.org/wiki/File%3ABinh%20Tay%20Market%202011.jpg) | CC BY 2.0 | Ken Marshall / Wikimedia Commons — CC BY 2.0 | 2026-09-27 |
| `images/places/le-van-duyet-tomb.jpg` | Lăng Ông Bà Chiểu | [Commons](https://commons.wikimedia.org/wiki/File%3AC%E1%BB%95ng%20ch%C3%ADnh%20L%C4%83ng%20%C3%94ng%20B%C3%A0%20Chi%E1%BB%83u.jpg) | CC BY-SA 3.0 | Bùi Thụy Đào Nguyên / Wikimedia Commons — CC BY-SA 3.0 | 2026-09-27 |
| `images/places/giac-lam-pagoda.jpg` | Tổ đình Giác Lâm | [Commons](https://commons.wikimedia.org/wiki/File%3AChuaGiacLam02.jpg) | Public domain | — | 2026-09-27 |
| `images/places/nha-rong-wharf.jpg` | Bến Nhà Rồng | [Commons](https://commons.wikimedia.org/wiki/File%3AHo%20Chi%20Minh%20Museum%2C%20in%20Saigon.jpg) | CC0 | — | 2026-09-27 |
| `images/places/thien-hau-temple.jpg` | Chùa Bà Thiên Hậu | [Commons](https://commons.wikimedia.org/wiki/File%3ACh%C3%B9a%20B%C3%A0%20Thi%C3%AAn%20H%E1%BA%ADu%2C%20Ch%E1%BB%A3%20L%E1%BB%9Bn.jpg) | CC BY-SA 2.0 | SiSi Ro / Wikimedia Commons — CC BY-SA 2.0 | 2026-09-27 |
| `images/places/landmark-81.jpg` | Landmark 81 | [Commons](https://commons.wikimedia.org/wiki/File%3AT%C3%B2a%20nh%C3%A0%20Landmark%2081%20(52353066123).jpg) | Public domain | — | 2026-09-27 |
| `images/places/buu-long-pagoda.jpg` | Thiền viện Bửu Long | [Commons](https://commons.wikimedia.org/wiki/File%3AB%E1%BB%ADu%20Long%20Pagoda%2C%20Th%E1%BB%A7%20%C4%90%E1%BB%A9c%2C%20HCM%20City%2C%20Vietnam%20(14537196651).jpeg) | Public domain | — | 2026-09-27 |

**Bộ xử lý ảnh vẫn chưa dựng.** Ảnh hiện là bản Commons phục vụ sẵn ở 900 px,
chưa qua preset màu/cắt cúp nào của dự án.

## Ứng viên cho cả 272 địa điểm — tra theo toạ độ

> Bảng ứng viên bên dưới chỉ phủ 12 điểm gốc và được tra **theo tên**. Pilot đã
> lên 272 điểm, nên có thêm một mẻ tra nữa, lần này **theo toạ độ**: xem
> [../tool/photo_picker/README.md](../tool/photo_picker/README.md).
>
> Kết quả mẻ đó nằm ở `tool/photo_picker/commons_candidates.json` — file sinh
> ra, không commit, chạy lại bằng
> `dart run tool/photo_picker/find_commons_photos.dart`. Nó **không phải** sổ
> này và không cho phép ảnh nào vào app: luật ở đầu file vẫn nguyên — ảnh không
> có dòng trong bảng duyệt thì không được đưa vào.
>
> Lần chạy gần nhất: 182/272 địa điểm có ứng viên, 90 điểm chưa có ảnh nào
> dùng được trên Commons.

## Ứng viên tìm được trên Wikimedia Commons — **CHƯA DUYỆT**

> Bảng này **không phải** bảng duyệt ở trên. Không ảnh nào ở đây được phép vào
> app cho tới khi chủ dự án chọn và chép sang bảng "12 checkpoint pilot".
>
> **Chưa ai nhìn ảnh.** Tải ảnh xem hàng loạt bị Commons chặn tốc độ, nên đây là
> kết quả tra **siêu dữ liệu**, không phải thẩm định bố cục. Vài cái tên đã tự
> tố là ảnh trong nhà hoặc ảnh chi tiết — `War Remnants Museum sewer`,
> `Binh Tay Market, interior`, `Tu viện Vĩnh Nghiêm, hậu đường` — trong khi
> marker cần **mặt tiền công trình**. Phải mở link xem trước khi chọn.
>
> Giấy phép thì đã đọc từng ảnh, không suy từ ảnh khác cùng kho.

| Địa điểm | Tệp trên Commons | Giấy phép | Tác giả | Kích thước |
|----------|------------------|-----------|---------|------------|
| Dinh Độc Lập | [Palacio de la Reunificación … DD 32](https://commons.wikimedia.org/wiki/File:Palacio_de_la_Reunificaci%C3%B3n,_Ciudad_Ho_Chi_Minh,_Vietnam,_2013-08-14,_DD_32.JPG) | CC BY-SA 3.0 | Diego Delso | 5410×3674 |
| ↳ | [Palacio de la Reunificación … DD 33](https://commons.wikimedia.org/wiki/File:Palacio_de_la_Reunificaci%C3%B3n,_Ciudad_Ho_Chi_Minh,_Vietnam,_2013-08-14,_DD_33.JPG) | CC BY-SA 3.0 | Diego Delso | 5401×3591 |
| Bưu điện Trung tâm Sài Gòn | [Oficina Central de Correos … DD 06](https://commons.wikimedia.org/wiki/File:Oficina_Central_de_Correos,_Ciudad_Ho_Chi_Minh,_Vietnam,_2013-08-14,_DD_06.JPG) | CC BY-SA 3.0 | Diego Delso | 5600×3733 |
| ↳ | [Oficina Central de Correos … DD 04](https://commons.wikimedia.org/wiki/File:Oficina_Central_de_Correos,_Ciudad_Ho_Chi_Minh,_Vietnam,_2013-08-14,_DD_04.JPG) | CC BY-SA 3.0 | Diego Delso | 4824×3216 |
| Chợ Bến Thành | [Ben Thanh … DD 01](https://commons.wikimedia.org/wiki/File:Ben_Thanh,_Ciudad_Ho_Chi_Minh,_Vietnam,_2013-08-14,_DD_01.JPG) | CC BY-SA 3.0 | Diego Delso | 5079×3664 |
| ↳ | [2023-12-10 Bến Thành Market 02](https://commons.wikimedia.org/wiki/File:2023-12-10_B%E1%BA%BFn_Th%C3%A0nh_Market_(Ch%E1%BB%A3_B%E1%BA%BFn_Th%C3%A0nh)_02.jpg) | CC BY-SA 4.0 | 源義信 | 4096×3072 |
| Bảo tàng Chứng tích Chiến tranh | [War Remnants Museum (46038433641)](https://commons.wikimedia.org/wiki/File:War_Remnants_Museum_(46038433641).jpg) | CC BY-SA 2.0 | Isabell Schulz | 5472×3648 |
| Chùa Vĩnh Nghiêm | [Tu viện Vĩnh Nghiêm, hậu đường (24)](https://commons.wikimedia.org/wiki/File:Tu_vi%E1%BB%87n_V%C4%A9nh_Nghi%C3%AAm,_h%E1%BA%ADu_%C4%91%C6%B0%E1%BB%9Dng_(khung_c%E1%BA%A3nh)_(24).jpg) | CC BY-SA 4.0 | Phương Huy | 3024×4032 |
| Chợ Bình Tây | [Binh Tay Market, Cholon (49056971593)](https://commons.wikimedia.org/wiki/File:Binh_Tay_Market,_Cholon,_Ho_Chi_Minh_City,_Vietnam_(49056971593).jpg) | CC BY 2.0 | Nick | 4928×3264 |
| Lăng Ông Bà Chiểu | [Phong cảnh Lăng Ông Bà Chiểu](https://commons.wikimedia.org/wiki/File:Phong_c%E1%BA%A3nh_L%C4%83ng_%C3%94ng_B%C3%A0_Chi%E1%BB%83u.jpg) | CC BY-SA 3.0 | Bùi Thụy Đào Nguyên | 4608×3456 |
| Tổ đình Giác Lâm | [Giac Lam Pagoda (10017927476)](https://commons.wikimedia.org/wiki/File:Giac_Lam_Pagoda_(10017927476).jpg) | CC0 | Gary Todd | 3168×4752 |
| ↳ | [Chùa Giác Lâm năm 2014 (12)](https://commons.wikimedia.org/wiki/File:Ch%C3%B9a_Gi%C3%A1c_L%C3%A2m_n%C4%83m_2014_(12).jpg) | CC BY-SA 4.0 | Phương Huy | 4320×3240 |
| Bến Nhà Rồng | [Ho Chi Minh Museum, Saigon](https://commons.wikimedia.org/wiki/File:Ho_Chi_Minh_Museum,_Saigon.jpg) | CC0 | Gary Todd | 5184×3456 |
| ↳ | [Ho Chi Minh Museum, in Saigon](https://commons.wikimedia.org/wiki/File:Ho_Chi_Minh_Museum,_in_Saigon.jpg) | CC0 | Syced | 4080×3072 |
| Chùa Bà Thiên Hậu | [Thien Hau Temple (Unsplash)](https://commons.wikimedia.org/wiki/File:Thien_Hau_Temple,_Ho_Chi_Minh_City,_Vietnam_(Unsplash).jpg) | CC0 | Chinh Le Duc | 5878×3919 |
| Landmark 81 | [Landmark 81 view from Saigon River](https://commons.wikimedia.org/wiki/File:Landmark_81_view_from_Saigon_River.jpg) | CC BY-SA 4.0 + `FoP-Vietnam` | Josemite | 1552×3264 |
| ↳ | [Tòa nhà Landmark 81 (52353066123)](https://commons.wikimedia.org/wiki/File:T%C3%B2a_nh%C3%A0_Landmark_81_(52353066123).jpg) | Public domain | Kien Mike | 3024×4032 |
| ↳ | [Landmark81 (49739070616)](https://commons.wikimedia.org/wiki/File:Landmark81_(49739070616).png) | Public domain | Cuong Tran | 3720×5978 |
| ↳ | [DJI 0325-HDR-Pano](https://commons.wikimedia.org/wiki/File:DJI_0325-HDR-Pano.jpg) | CC BY 2.0 | Lê Minh Phát | 5823×8211 |
| Thiền viện Bửu Long | [Bửu Long Pagoda, Thủ Đức (14537196651)](https://commons.wikimedia.org/wiki/File:B%E1%BB%ADu_Long_Pagoda,_Th%E1%BB%A7_%C4%90%E1%BB%A9c,_HCM_City,_Vietnam_(14537196651).jpeg) | Public domain | minhphuc_99kdd | 4514×2871 |
| ↳ | [Tháp chính chùa Bửu Long](https://commons.wikimedia.org/wiki/File:Th%C3%A1p_ch%C3%ADnh_ch%C3%B9a_B%E1%BB%ADu_Long.jpg) | CC BY-SA 4.0 | Thienn | 1024×768 |

### Cái bẫy phải biết khi tự tra thêm

Tra theo **tên** trên Commons trả về nhầm y hệt như lúc tra toạ độ:

- `Landmark 81` → ra **Yokohama Landmark Tower**, Nhật Bản
- `Chùa Bửu Long` → ra **Chùa Bửu Đà, Quận 10**, một ngôi chùa khác

Dùng `incategory:"<tên category>"` thay vì tìm chữ tự do thì hết nhầm.

## Ảnh khác

Ảnh bìa chương truyện và ảnh trong node `image` cũng là địa danh, nên cũng phải
có dòng ở đây. Thêm vào bảng dưới khi có.

| Tệp | Dùng ở | Nguồn | Giấy phép | Yêu cầu ghi nguồn | Ngày lấy |
|-----|--------|-------|-----------|-------------------|----------|

## Lưu ý riêng cho Landmark 81

Công trình hiện đại, còn trong thời hạn bảo hộ quyền tác giả kiến trúc. Ảnh
chụp công trình như vậy ở nơi công cộng có được dùng thương mại hay không tuỳ
thuộc quy định *freedom of panorama* — đừng mặc định là được.

**Tra thêm được ngày 2026-08-08 — mối lo này CÓ CƠ SỞ.** Wikimedia Commons duy
trì bản mẫu `Template:NoFoP-Vietnam`. Luật Sở hữu trí tuệ sửa đổi
(Luật 07/2022/QH15, Điều 25.1(h)) thêm chữ **"không nhằm mục đích thương mại"**
vào quyền chụp ảnh công trình kiến trúc nơi công cộng.

Phải hiểu cho đúng: giấy phép `CC BY` hay `CC0` trên một tấm ảnh Landmark 81 là
giấy phép của **người chụp** cho **bức ảnh**. Nó không nói gì về quyền tác giả
của **công trình** nằm trong khung hình. Hai quyền khác nhau.

### Sửa lại ngày 2026-09-08 — điều khoản này KHÔNG hồi tố

Kết luận trước đó ("không có đường nào ngoài thay điểm, tự chụp cũng không gỡ
được") **nói quá**. Đọc kỹ chính bản mẫu `NoFoP-Vietnam` thì Commons ghi rõ:

> Ảnh tải lên **đến hết 2022-12-31** vẫn hợp lệ, vì áp theo freedom of panorama
> cũ của Việt Nam — bản cũ **không** hạn chế dùng thương mại.

Bản sửa đổi có hiệu lực **2023-01-01** và không hồi tố. Vậy nên:

- Ảnh Landmark 81 **xuất bản/tải lên trước 2023** — dùng được, kể cả thương mại.
- Ảnh chụp **từ 2023 trở đi** — vướng. **Tự chụp bây giờ (2026) vẫn vướng**, vì
  vấn đề nằm ở công trình chứ không ở ai bấm máy. Chỗ này kết luận cũ đúng.
- Category `Landmark 81` trên Commons gắn `{{NoFoP-category}}`: chặn ảnh mới,
  **không** xoá 70 ảnh cũ đã có sẵn trong đó.

Bằng chứng mạnh nhất là [Landmark 81 view from Saigon River](https://commons.wikimedia.org/wiki/File:Landmark_81_view_from_Saigon_River.jpg)
(tải lên 2021): Commons gắn thẳng `{{Licensed-FoP|{{FoP-Vietnam}}|{{self|cc-by-sa-4.0}}}}`
— tức chính Commons đứng ra khẳng định FoP bản cũ áp cho tấm này. Đây là tấm
**an toàn nhất** vì lập luận pháp lý được ghi ngay trên trang ảnh, không phải
suy ra.

Ba ứng viên còn lại trong bảng trên đều tải lên trước 2023 và đều là `Public
domain` hoặc `CC BY`, nhưng chúng chỉ mang giấy phép của **bức ảnh** — phần
công trình vẫn phải dựa vào lập luận không-hồi-tố ở trên.

**Kết luận: giữ Landmark 81, chọn ảnh tải lên trước 2023.** Không cần thay điểm.

### Vì sao thay điểm cũng không cứu được "Sài Gòn hiện đại"

Nếu vẫn muốn tuyệt đối không mơ hồ thì phải biết cái giá: bảo hộ kiến trúc ở
Việt Nam hết hạn **50 năm sau khi kiến trúc sư mất**. Nghĩa là **mọi** công
trình hiện đại của thành phố đều vướng y hệt — Bitexco, cầu Ba Son, cầu Thủ
Thiêm. Thay Landmark 81 bằng một công trình hiện đại khác không giải quyết gì;
thay bằng một công trình đủ cũ thì pilot thành **12 công trình cũ**, mất hẳn
điểm đối trọng đương đại. Đó là quyết định sản phẩm, không phải quyết định
pháp lý.

### Ba đường đi cũ — vẫn còn giá trị nếu muốn chắc hơn

1. Hỏi luật sư sở hữu trí tuệ. Chắc chắn nhất, chậm nhất. Câu cần hỏi giờ hẹp
   hơn nhiều: *"điều khoản không hồi tố có bảo vệ bên dùng lại ảnh, hay chỉ bảo
   vệ người chụp?"*
2. Xin phép chủ sở hữu công trình bằng văn bản.
3. Thay Landmark 81 bằng một điểm khác — xem mục ngay trên về cái giá phải trả.

> Tôi không phải luật sư. Phần trên là đọc bản mẫu và điều luật mà Commons dẫn,
> cùng chính sách lưu trữ của Commons — không phải ý kiến pháp lý.
