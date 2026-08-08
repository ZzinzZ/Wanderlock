# Xem trước style bản đồ

Ba khung cạnh nhau, cùng một khung nhìn: **style mặc định của nhà cung cấp**,
**Wanderlock sáng**, **Wanderlock tối**. Đây là cách kiểm mục DoD *"đặt cạnh
ảnh chụp map mặc định → khác biệt rõ ràng bằng mắt"* của F3.

## Chạy

Từ `app/`, sinh style ra thư mục này:

```
fvm flutter test test/design/map_style_preview.dart
```

Rồi mở cấu hình `map-style-preview` (xem `.claude/launch.json`), hoặc phục vụ
thư mục này bằng bất kỳ máy chủ tĩnh nào và mở `preview.html`.

File `style-*.json` **sinh ra, không commit** — nguồn đúng là `design/tokens/`.

## Vì sao vẫn cần trình duyệt khi đã chạy được trên máy thật

Máy ảo Android dùng GPU phần mềm (SwiftShader) và **không vẽ chữ trên bản đồ**
— đã đối chứng bằng cách nạp style Liberty của OpenFreeMap, vốn đầy nhãn, và
nó cũng không hiện chữ nào. Nên nhãn và dấu tiếng Việt chỉ có thể đánh giá ở
trình duyệt hoặc trên điện thoại thật.
