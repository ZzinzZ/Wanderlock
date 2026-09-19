# Chọn ảnh marker cho 12 checkpoint

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
