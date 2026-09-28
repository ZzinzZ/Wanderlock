# Chọn ảnh cho các địa điểm

Mười hai nhóm ảnh, mỗi nhóm là các ứng viên đã tra được cho một địa điểm. Bấm
**Chọn** ở ảnh dùng được, hoặc **Không ảnh nào đạt** nếu cả nhóm đều hỏng, rồi
bấm **Xuất bảng duyệt**.

Đây là đầu ra cuối cùng còn thiếu của F3. `content/image-licenses.md` đã có
danh sách ứng viên với giấy phép đọc từng ảnh — nhưng đó là kết quả tra **siêu
dữ liệu**, và chính file đó ghi rõ: *chưa ai nhìn ảnh*. Marker cần mặt tiền
công trình, trong khi vài ứng viên tự tố tên là ảnh trong nhà hoặc ảnh chi
tiết. Không cách nào biết ngoài việc mở ra xem ở cỡ đủ lớn.

## Chạy

Từ gốc kho mã:

```
dart run tool/photo_picker/build_picker_page.dart
```

Sinh ra `picker.html`. **Mở thẳng bằng trình duyệt, không cần máy chủ.** Cần
mạng, vì ảnh tải từ Wikimedia Commons.

Xuất xong thì gửi kết quả lại qua chat. Trang chỉ **sinh ra dòng** cho bảng
"12 checkpoint pilot", không tự ghi vào `content/image-licenses.md` — mỗi dòng
giấy phép vẫn phải đi qua một lần review của người.

## Nút "Xem dạng khung vuông"

Marker là một khung nhỏ và chặt, nên ảnh đẹp ở dạng đầy đủ vẫn có thể mất chủ
thể khi bị cắt vuông. Nút này chuyển mọi ảnh sang cắt vuông giữa khung để thấy
phần thật sự sống sót vào bản đồ. Preset xử lý ảnh chưa dựng, nên đây là ước
lượng, không phải bản xem trước chính xác.

## Ghi nguồn được sinh tự động — vẫn phải đọc lại

`CC0` và `Public domain` cho ra `—`. Còn lại cho ra
`<tác giả> / Wikimedia Commons — <giấy phép>`. Đó là dạng mặc định hợp lý, chưa
chắc là dạng đúng cho mọi giấy phép; đối chiếu lại với trang Commons trước khi
chốt.

Tên tệp trong cột đầu để là `<id checkpoint>.jpg`. Preset xử lý ảnh chưa dựng
nên định dạng cuối chưa chốt — sửa lại khi preset xong.

## Cái bẫy đã cắn một lần

Tên tệp trên Commons hay kết thúc bằng mã tải lên trong ngoặc:
`War_Remnants_Museum_(46038433641).jpg`. Regex lười (`\(.+?\)`) sẽ cắt URL ở
dấu ngoặc đóng **đầu tiên** và trả về đường dẫn cụt. Bộ phân tích không hề báo
lỗi — chỉ có 8/18 ảnh không hiện trong trình duyệt. Nay script chặn bằng cách
kiểm đuôi tệp và **dừng hẳn** nếu tên không kết thúc bằng đuôi ảnh.

## Ứng viên đến từ đâu (bổ sung, pilot đã lên 272 điểm)

Trang này giờ gộp hai nguồn ứng viên cho **mọi** địa điểm, không chỉ 12 điểm gốc.

1. **Sổ giấy phép** `content/image-licenses.md` — các dòng tìm bằng tay cho 12
   điểm gốc. Xếp trước trên mỗi thẻ, vì chúng đã được chọn lọc.
2. **`commons_candidates.json`** — sinh bằng
   `dart run tool/photo_picker/find_commons_photos.dart`.

Công cụ ở bước 2 tra Wikimedia Commons **theo toạ độ**, không theo tên. Tra theo
tên là cái bẫy đã cắn dự án này nhiều lần — "Landmark 81" ra toà nhà ở Yokohama,
"Chùa Bửu Long" ra một ngôi chùa khác ở Quận 10. Một toạ độ thì không thể nhập
nhằng. Commons có lưu nơi bức ảnh được chụp, nên câu hỏi trở thành "trong bán
kính vài trăm mét quanh đây, người ta đã chụp những gì".

Nó lọc sẵn: chỉ giữ giấy phép cho phép phát hành kèm ghi nguồn (loại thẳng
`NC` và `ND`), bỏ tệp không phải ảnh chụp (bản đồ, biểu trưng, sơ đồ), và bỏ ảnh
nhỏ hơn 1200×800 vì màn mở khoá không dùng được.

**Ở gần không có nghĩa là chụp đúng chỗ đó.** Ứng viên đầu tiên của Chợ Bến
Thành là ảnh bên trong chợ; nhiều điểm khác sẽ là nắp cống, bảng hiệu, hay bữa
trưa của ai đó. Công cụ thu hẹp đống phải nhìn, không thay người nhìn.

> Kết quả ngày chạy gần nhất: **182 trên 272 địa điểm** có ít nhất một ứng viên;
> 90 điểm còn lại Commons chưa có ảnh nào dùng được. Phần lớn là chợ nhỏ, quán
> ăn và bia tưởng niệm — những nơi sẽ phải tự chụp.
