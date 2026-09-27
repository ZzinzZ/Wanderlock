# Xác nhận toạ độ 12 checkpoint

Mười hai ô ảnh vệ tinh cạnh nhau. Mỗi ô: chấm hồng là toạ độ hiện tại trong
`content/checkpoints.json`, vòng tròn là bán kính check-in, chấm trắng viền đen
là vị trí gốc để đối chiếu sau khi dời. Bấm vào bản đồ hoặc kéo chấm hồng để
sửa, bấm **Đúng** khi ô đó đã ổn, cuối cùng bấm **Xuất JSON**.

Đây là mục DoD còn thiếu của F2: mọi checkpoint đang mang `verified: false` cho
tới khi có người **nhìn ảnh vệ tinh** xác nhận điểm rơi vào giữa công trình.
Toạ độ hiện tại là tâm đa giác trong OpenStreetMap — chính xác về mặt hình học,
nhưng tâm đa giác lệch khỏi tâm nhìn thấy khi công trình có sân lớn hoặc mặt
bằng hình chữ L. Máy không tự quyết được chuyện đó.

## Chạy

Từ gốc kho mã:

```
dart run tool/coord_verify/build_verify_page.dart
```

Sinh ra `verify.html`. **Mở thẳng bằng trình duyệt, không cần máy chủ** — khác
`tool/map_preview`, trang này không đọc file nào cạnh nó lúc chạy. Cần mạng, vì
ảnh vệ tinh và thư viện bản đồ tải qua https.

Xuất xong thì gửi khối JSON lại qua chat; việc ghi ngược vào
`content/checkpoints.json` làm bằng tay để mỗi thay đổi toạ độ đều đi qua một
lần review, không do trang web tự ghi.

## Vì sao Leaflet chứ không phải MapLibre

`tool/map_preview` dùng MapLibre vì nó phải render đúng style vector của sản
phẩm. Trang này chỉ cần ảnh vệ tinh dạng raster, một chấm và một vòng tròn.
Leaflet dựng bằng thẻ `img` thuần, không cần WebGL cũng không cần web worker,
nên mở bằng `file://` là chạy — đúng điều kiện cần cho một trang tự chứa.

Đây là công cụ nội bộ, **không phải phụ thuộc của sản phẩm**, nên không thuộc
phạm vi `docs/10-libraries.md`.

## Ảnh vệ tinh

Esri World Imagery, không cần khoá API. Ghi nguồn là điều kiện sử dụng nên
control ghi nguồn luôn bật — đừng tắt.

## Hai nguồn đối chiếu, và vì sao trang này cần cả hai

Trang xếp điểm đáng ngờ lên trước, dựa trên hai file cạnh nó. Cả hai đều
**không** tự đặt `verified` — đồng ý với một nguồn chỉ chứng minh hai bên trùng
nhau, không chứng minh bên nào đúng. Người nhìn ảnh vệ tinh mới là người quyết.

**`osm_recheck.json`** — sinh bằng `dart run tool/coord_verify/recheck_osm.dart`.
Hỏi lại chính OpenStreetMap, nơi toạ độ được nhập về: điểm đã dời chưa, nó là
một chấm ai đó thả tay hay là tâm của một hình, tên có khớp không. Đây là phép
thử "bản nhập có sao đúng không".

**`gmaps_recheck.json`** — đối chiếu với Google Maps, tức một nguồn *độc lập*.
Với mỗi tên, tìm trên Google rồi đo khoảng cách từ ghim của Google tới toạ độ
đang lưu. Bốn kết luận:

| | |
|---|---|
| `agree` | ghim Google nằm trong bán kính check-in — hai nguồn trùng nhau |
| `near` | lệch dưới 250 m — thường là nơi rộng, mỗi bên ghim một góc |
| `conflict` | lệch trên 250 m — **một trong hai sai**, phải nhìn |
| `unknown` | Google không có địa điểm nào mang tên đó — chỉ còn cách nhìn ảnh |

> **File này chưa có script sinh lại.** Nó được làm bằng cách điều khiển trình
> duyệt tra từng tên trên Google Maps rồi đọc toạ độ ghim từ địa chỉ trang, nên
> nó được commit thay vì bị bỏ qua như `osm_recheck.json`. Muốn làm lại sau khi
> nội dung đổi thì phải chạy lại việc đó. Cần nhớ: tra theo **tên** là cái bẫy
> đã cắn dự án này vài lần (Chùa Bà Thiên Hậu ra bản ở Bình Dương, Landmark 81
> ra toà nhà ở Yokohama) — nên khoảng cách, chứ không phải cái tên Google trả
> về, mới là thứ đáng tin ở đây.
