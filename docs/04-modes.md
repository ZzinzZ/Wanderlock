# Các chế độ trải nghiệm (Lăng kính / Lens)

> Người dùng **bật chế độ nào tùy tâm trạng**; cùng một chuyến đi có thể xem qua nhiều lăng kính.
> Tất cả đọc chung **một tầng mở khóa** ([03-architecture.md](03-architecture.md)) → cộng dồn, không mâu thuẫn.
> **v1 có 5 lăng kính.** Xã hội hoãn sang v1.5 — xem [08-scope.md](08-scope.md).

---

## 1. 🗺️ Chế độ Cắm mắt (Fog of War) — *v1*

- **Trải nghiệm:** Vùng chưa đi bị xám hoá, ảnh địa danh khử màu; đi tới đâu màu trở lại tới đó.
- **Cho ai:** Người thích cảm giác chinh phục, phủ kín bản đồ (trực quan, "gây nghiện" nhất).
- **Cơ chế liên quan:** A1, A2, A3.
- **Cảm giác chủ đạo:** *Chinh phục.*

## 2. 📖 Chế độ Story / Kể chuyện — *v1*

- **Trải nghiệm:** Đến nơi mở "chương truyện" tương tác + người dẫn truyện xuyên suốt nhớ hành trình của bạn.
- **Cho ai:** Người thích chiều sâu văn hóa, lịch sử, cảm xúc.
- **Cơ chế liên quan:** B1, B2, B3, B4.
- **Cảm giác chủ đạo:** *Thấu hiểu & cảm xúc.*

## 3. 🎯 Chế độ Quest / Nhiệm vụ — *v1*

- **Trải nghiệm:** Các tuyến hành trình chủ đề **do đội ngũ biên soạn**, có cốt truyện, có mở–thân–kết.
- **Cho ai:** Người thích có mục tiêu, có lộ trình rõ ràng.
- **Cơ chế liên quan:** E1, E2.
- **Cảm giác chủ đạo:** *Mục tiêu & thành tựu.*

## 4. 🏅 Chế độ Sưu tầm — *v1*

- **Trải nghiệm:** Tem/huy hiệu từng điểm, bản đồ ký ức cá nhân chia sẻ được.
- **Cho ai:** Người thích tích lũy & khoe.
- **Cơ chế liên quan:** C1, C3.
- **Cảm giác chủ đạo:** *Tích lũy & dấu ấn.*

## 5. 🧭 Chế độ Tùy chỉnh hành trình — *v1*

- **Trải nghiệm:** Người dùng **tự chọn checkpoint và sắp thứ tự** thành lộ trình riêng, xem tổng quãng đường/thời gian, rồi bắt đầu đi.
- **Cho ai:** Người đi du lịch thật, có quỹ thời gian cố định, muốn tự quyết chứ không đi theo tuyến có sẵn.
- **Khác gì Quest:** Quest là **tuyến do đội ngũ biên soạn, có cốt truyện**. Tùy chỉnh hành trình là **tuyến do người dùng tự dựng, không có cốt truyện**.
- **Cảm giác chủ đạo:** *Chủ động & kiểm soát.*
- **Vì sao vào được v1:** gần như không tốn thêm backend — chỉ là một danh sách có thứ tự trỏ tới checkpoint, đọc chung `visit_state`.

---

## Hoãn sang v1.5

## 👥 Chế độ Xã hội

- **Trải nghiệm:** "X đã từng đến đây", để lại dấu/lời nhắn, bảng xếp hạng khu vực.
- **Vì sao hoãn:** cần kiểm duyệt nội dung người dùng, và chỉ vui khi đã có đông người chơi.

---

## Ma trận: Chế độ × Người dùng

| Chế độ | Trẻ/teen | Du khách văn hóa | Sưu tầm | Đi nhóm/cặp đôi |
|--------|:---:|:---:|:---:|:---:|
| Fog of War | ★★★ | ★ | ★ | ★★ |
| Story | ★ | ★★★ | ★ | ★★ |
| Quest | ★★ | ★★★ | ★★ | ★★★ |
| Sưu tầm | ★★ | ★★ | ★★★ | ★ |
| Tùy chỉnh hành trình | ★ | ★★★ | ★ | ★★★ |

→ Không nhóm nào bị "bỏ rơi"; và ai cũng có lý do thử thêm lăng kính khác.

---

## Nguyên tắc chuyển lăng kính (UX)

- Chuyển chế độ phải **tức thì**, ngay trên cùng một bản đồ.
- Khi chuyển, **trạng thái mở khóa giữ nguyên** — chỉ thay đổi *cách hiển thị & nội dung*.
- Không ép chọn chế độ khi onboarding; cho trải nghiệm mặc định (Fog of War + gợi ý Story tại điểm đầu tiên) rồi để người dùng tự khám phá.
- Với 5 lăng kính, thanh chuyển **không nên là 5 tab bằng nhau** — ưu tiên Fog/Story/Sưu tầm ở thanh chính, Quest và Tùy chỉnh hành trình vào nhóm "Hành trình".
