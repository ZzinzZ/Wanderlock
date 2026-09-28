# Nơi nào nên có chương truyện

Chủ dự án chốt (2026-09-27): **nơi lớn thì có chương** — địa danh, điểm tham
quan, trung tâm thương mại lớn; **quán ăn và các điểm bình thường thì không**.

Biến câu đó thành quyết định cho 272 nơi cần một dấu hiệu, và "gu của tôi" là
dấu hiệu tồi vì nó không sống lâu hơn người có gu đó. Dấu hiệu dùng ở đây là
**Wikipedia tiếng Việt có bài về nơi đó hay không**: một người không liên quan
gì tới dự án này đã quyết định nơi đó đáng có một bài, hoặc quyết định là
không. Ai cũng kiểm lại được, và chính bài đó là chỗ để viết chương.

```
dart run tool/story_candidates/find_wikipedia_articles.dart
```

Sinh ra `wikipedia_articles.json`. Loại `food` bị loại thẳng, không cần hỏi
Wikipedia.

## Cách tra: hai chiều, và cả hai phải khớp

Tra theo **toạ độ** thôi thì ra bài về thứ khác ở gần — Bến Nhà Rồng từng ra
bài *Rạch Bến Nghé*, con kênh nó đứng bên. Tra theo **tên** thôi là cái bẫy cũ
của kho mã này — Landmark 81 ra một toà tháp ở Yokohama. Nên: hỏi Wikipedia có
bài nào mang tên này, rồi **bỏ những bài mà toạ độ của chính nó nằm nơi khác**.

## Nó chính xác tới đâu — đo bằng 12 điểm đã biết đáp án

**9 trên 12** điểm gốc được nhận đúng. Ba điểm bị bỏ sót: Chùa Vĩnh Nghiêm,
Bến Nhà Rồng, Chùa Bà Thiên Hậu — đều là chuyện tên gọi (bài về Chùa Bà mang
tên *Hội quán Tuệ Thành*) hoặc bài không khai toạ độ.

Nói cách khác: **đây là danh sách rút gọn, không phải phán quyết.** Nó thu
việc từ "xem 272 nơi" xuống "xem 62 nơi rồi ngó lại vài nơi bị bỏ sót".

## Không có cờ `needsStory` nào cả

Một nơi có chương khi và chỉ khi tồn tại `content/stories/<id>.json`. Không
cần thêm trường vào `checkpoints.json`, không cần migration, và không có hai
nguồn sự thật để lệch nhau. File này chỉ trả lời câu "viết chương nào tiếp".
