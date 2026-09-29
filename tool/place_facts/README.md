# Giới thiệu cho những nơi chưa ai viết

272 địa điểm, 46 nơi có chương truyện. 226 nơi còn lại cần **một thứ gì đó** để
người chơi mở khoá xong không nhận về một thẻ trống.

Vấn đề không phải công sức viết. Vấn đề là **không có gì để viết**.

## Đã tra hết, và đây là những gì có thật

Chạy `fetch_place_facts.dart` gom về mọi thứ dữ liệu mở biết về 272 nơi:

| Nguồn | Phủ được bao nhiêu trong 226 nơi |
|-------|----------------------------------|
| Tên và loại hình (OpenStreetMap) | 226 |
| Đường, phường, quận (tra ngược Nominatim) | 226 |
| Giờ mở cửa | 19 |
| Đơn vị quản lý | 8 |
| Mô tả Wikidata | 11 |
| **Đoạn mở đầu Wikipedia tiếng Việt** | **5** |

58 nơi trong số đó có **đúng hai** dòng dữ liệu: cái tên, và một chữ nói nó là
loại gì.

`find_wikipedia_articles.dart` bên `tool/story_candidates/` tìm được 63 nơi có
bài Wikipedia, nhưng 43 nơi đã viết chương rồi, và **cả 20 nơi còn lại đều là
bẫy "bài ở gần"**: Cầu Mống ra bài *Rạch Bến Nghé*, Công viên Vinhomes Central
Park ra bài *Landmark 81*, Chợ Xóm Chiếu ra bài *Quận 4*. Không có nơi nào
trong 226 nơi đó được Wikipedia tiếng Việt viết riêng một bài.

## Nên đã làm thế này

`write_intros.dart` dựng một đoạn giới thiệu ngắn cho mỗi nơi, **chỉ từ những
câu mà dữ liệu nói được**. Không có một câu nào trong file đó mô tả một địa
điểm; chỉ có ngữ pháp để ghép "khu chợ", "đường Cao Thắng, Phường Bàn Cờ" và
"mở cửa 05:00–18:00" thành một câu tiếng Việt.

Kết quả mang `kind: "intro"`, không phải `chapter`. App đọc trường đó và đổi
chữ trên nút thành **"Xem giới thiệu"** thay vì "Đọc chương". Một nơi có vài
dòng dữ kiện không được mời như một câu chuyện.

```bash
dart run tool/place_facts/fetch_place_facts.dart   # ~10 phút, cần mạng
dart run tool/place_facts/write_intros.dart        # tức thì
cp -r content/stories app/assets/content/stories   # đồng bộ bản đóng gói
```

`write_intros.dart` **không bao giờ ghi đè một chương viết tay**. Nó bỏ qua mọi
file có `kind: chapter` hoặc không khai `kind`. Cờ `--force` chỉ ghi đè những
đoạn giới thiệu do chính nó sinh ra.

## Giới hạn, nói thẳng

Một đoạn giới thiệu không phải một chương, và nó không giả vờ là. Nơi nào đáng
có chương thật thì **vẫn đáng** — chỉ là nguồn để viết chưa tồn tại, và bịa ra
một đoạn văn về một khu chợ có thật là việc không được làm.

Cách duy nhất để nâng chất là có người biết nơi đó ngồi viết. Khi điều đó xảy
ra: sửa file, đổi `kind` thành `chapter`, và công cụ này sẽ không đụng vào nó
nữa.

## Kết quả sinh ra bị gitignore

`place-facts.json` không được commit. Chạy lại thay vì tin một bản cũ — dữ liệu
OpenStreetMap thay đổi, và một bản chép tháng trước thì không ai biết nó cũ tới
đâu.
