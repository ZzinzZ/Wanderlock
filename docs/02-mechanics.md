# Các cơ chế game

> Đánh dấu mức độ ưu tiên: ⭐ phụ · ⭐⭐ mạnh · ⭐⭐⭐ cơ chế lõi.
> Tất cả cơ chế đều đổ chung về **một tầng mở khóa** (xem [03-architecture.md](03-architecture.md)).

---

## A. Khám phá & Mở khóa (Fog of War)

- **A1. Sương mù động theo bán kính đi bộ ⭐⭐⭐**
  Bản đồ tối; mỗi bước chân thật "quét sáng" một vòng quanh bạn. Cả *đường đi* giữa các điểm cũng dần lộ ra → thưởng cho việc lang thang.

- **A2. Checkpoint phân tầng độ khó ⭐⭐**
  - *Dễ* (công viên, quảng trường): chạm GPS là mở.
  - *Ẩn* (quán cà phê lịch sử, hẻm nghệ thuật): chỉ hiện gợi ý mờ, phải tự tìm.
  - *Bí mật* (easter egg): không đánh dấu, chỉ mở khi vô tình đi ngang → cảm giác "kho báu".

- **A3. Vùng khóa cần điều kiện ⭐⭐**
  Một quận/khu chỉ mở khi đã ghé đủ X checkpoint lân cận → lộ trình khám phá có chủ đích.

---

## B. Kể chuyện (điểm khác biệt lớn nhất)

- **B1. "Chương truyện" mở tại chỗ ⭐⭐⭐**
  Đến bảo tàng/di tích → mở chương truyện tương tác (visual novel ngắn, có nhân vật). *Linh hồn* của sản phẩm.

- **B2. Người dẫn truyện xuyên suốt ⭐⭐⭐**
  Một nhân vật đồng hành (hồn ký ức của thành phố, bác xe ôm già, nhà sử học ảo...) kể chuyện qua từng điểm và *nhớ* những nơi bạn đã đi → mạch cảm xúc liên tục.

- **B3. Câu chuyện phân mảnh (fragment) ⭐⭐**
  Một sự kiện lịch sử chia thành mảnh, mỗi mảnh giấu ở một địa điểm liên quan. Ghép đủ → mở toàn cảnh + phần thưởng.

- **B4. Nghe theo bối cảnh thật ⭐⭐**
  Story kích hoạt theo *thời điểm* (đứng ở Dinh Độc Lập gần trưa, góc phố lúc chiều tà...) → gắn câu chuyện với không khí thật.

---

## C. Tiến trình & Phần thưởng

- **C1. Bộ sưu tập tem/huy hiệu ⭐⭐**
  Mỗi checkpoint tặng một con tem thiết kế đẹp (như hộ chiếu du lịch). Tính sưu tầm cao, dễ khoe.

- **C2. Cây danh hiệu theo chủ đề ⭐**
  "Nhà sử học", "Kẻ sành ăn", "Thợ săn kiến trúc"... mở theo loại điểm hay ghé.

- **C3. Bản đồ ký ức cá nhân ⭐⭐**
  Kết thúc chuyến đi → dựng lại hành trình thành "tấm bản đồ kỷ niệm" (đường đi + ảnh + điểm đã mở) để chia sẻ. Vừa là phần thưởng cảm xúc, vừa là công cụ lan truyền.

---

## D. Xã hội

- **D1. "Cắm cờ" / để lại dấu ⭐⭐**
  Người đầu tiên đến một điểm ẩn được ghi tên; người sau thấy "X đã từng đến đây" + để lại lời nhắn.

- **D2. Bảng xếp hạng theo khu ⭐**
  Ai mở nhiều checkpoint nhất Quận 1 tuần này. Nhẹ nhàng, không làm nặng.

- **D3. Nhiệm vụ nhóm ⭐**
  Vài người cùng mở một vùng lớn để unlock story chung → hợp đi nhóm/hẹn hò.

---

## E. Nhiệm vụ (Quest — biến việc đi thành "quest")

- **E1. Tuyến hành trình có cốt truyện ⭐⭐⭐**
  Các "tuyến quest" chủ đề: *"Một ngày làm phóng viên chiến trường 1968"*, *"Ẩm thực người Hoa Chợ Lớn"*. Mỗi tuyến = chuỗi checkpoint + câu chuyện xuyên suốt + kết. Giữ chân người dùng, dễ hợp tác/thương mại hóa nhất.

- **E2. Câu đố tại địa điểm ⭐⭐**
  Đến nơi phải trả lời câu hỏi dựa trên thứ *nhìn thấy thật* ("Tòa nhà xây năm nào? — nhìn bảng đá") mới mở tiếp. Chống gian lận GPS + buộc quan sát thật.

---

## Bộ lõi đề xuất cho MVP

> **A1** (sương mù động) **+ B1 & B2** (chương truyện + người dẫn truyện) **+ E1** (tuyến quest chủ đề) **+ C1/C3** (tem + bản đồ ký ức)

Combo này giữ đủ **cả 3 trụ**: khám phá (fog) · cảm xúc/nội dung (story) · lý do quay lại + chia sẻ (quest + kỷ niệm) — mà không phình tính năng.
