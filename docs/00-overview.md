# Wanderlock — Tổng quan dự án

> **Codename:** Wanderlock (Wander + Unlock) — tên tạm, có thể đổi.
> **Ngày khởi tạo docs:** 2026-08-04
> **Trạng thái:** Ý tưởng / định hình sản phẩm (pre-MVP)

---

## 1. Một câu định nghĩa

> **Một app bản đồ tham quan được "game hóa": mỗi địa điểm đặc sắc là một checkpoint bị khóa, bạn phải *thực sự đến nơi* để mở khóa — và mỗi lần đến sẽ mở khóa cho MỌI chế độ chơi.**

Kết hợp giữa **Pokémon GO** (mở khóa theo vị trí thật + fog of war) và **du lịch văn hóa có kể chuyện** (audio-guide biến thành game phiêu lưu).

---

## 2. Vấn đề & Cơ hội

- App bản đồ tham quan hiện tại (Google Maps, TripAdvisor...) chỉ **hiển thị thông tin**, không tạo **động lực khám phá** hay **cảm xúc**.
- Người dùng đến một thành phố nhưng không có "lý do chơi" để đi hết các điểm đặc sắc.
- Nội dung lịch sử / văn hóa của các bảo tàng, di tích thường bị trình bày khô khan, ít ai đọc.

**Cơ hội:** Biến việc tham quan thành một trò chơi khám phá có tiến trình, có cốt truyện, có phần thưởng — khiến người ta *muốn* đi hết thành phố.

---

## 3. Insight thiết kế cốt lõi

> **Tách "trạng thái mở khóa" ra khỏi "chế độ trải nghiệm".**

- **Một địa điểm = một checkpoint duy nhất.** Đến nơi (xác thực GPS) → mở khóa **vĩnh viễn** cho *mọi chế độ*.
- Chế độ chỉ thay đổi **cách trải nghiệm**, **không** thay đổi kết quả mở khóa.
- Ví dụ: vào Bảo tàng ở chế độ **Story** vẫn làm sáng ô bảo tàng trong chế độ **Cắm mắt (Fog of War)**. Một lần đi, mọi chế độ đều được ghi nhận.

→ Nhờ vậy người dùng **không phải chọn phe**: trẻ thích cắm mắt, người lớn thích story + quest — cùng một app, cùng một chuyến đi, ai cũng được phục vụ. Các chế độ **cộng dồn**, không mâu thuẫn.

Chi tiết kiến trúc 2 tầng: xem [03-architecture.md](03-architecture.md).

---

## 4. Đối tượng người dùng

| Nhóm | Động lực chính | Chế độ ưa thích |
|------|----------------|-----------------|
| Trẻ em / teen | Chinh phục, phủ kín bản đồ | Cắm mắt (Fog of War) |
| Người lớn / du khách văn hóa | Chiều sâu lịch sử, cảm xúc | Story, Quest |
| Người thích sưu tầm | Tích lũy, khoe | Sưu tầm (tem, huy hiệu) |
| Người đi nhóm / cặp đôi | Cùng khám phá, so tài | Xã hội, Quest nhóm |

---

## 5. Phạm vi thử nghiệm ban đầu

- **Thành phố pilot:** TP. Hồ Chí Minh.
- **Các điểm mẫu:** Bảo tàng Chứng tích Chiến tranh, Dinh Độc Lập, Bưu điện Thành phố, Chợ Bến Thành, khu Chợ Lớn...

---

## 6. Câu pitch ngắn

> **"Một bản đồ, một lần đến, mở khóa cho mọi cách chơi.
> Bạn chọn lăng kính để *trải nghiệm* thành phố — nhưng dấu chân của bạn thì thuộc về tất cả."**

---

## 7. Danh mục tài liệu

| File | Nội dung |
|------|----------|
| [00-overview.md](00-overview.md) | Tổng quan (file này) |
| [01-vision.md](01-vision.md) | Tầm nhìn, giá trị cốt lõi, khác biệt |
| [02-mechanics.md](02-mechanics.md) | Các cơ chế game chi tiết |
| [03-architecture.md](03-architecture.md) | Kiến trúc 2 tầng & mô hình dữ liệu |
| [04-modes.md](04-modes.md) | Các chế độ trải nghiệm (lăng kính) |
| [05-roadmap.md](05-roadmap.md) | Lộ trình & MVP |
| [06-tech-stack.md](06-tech-stack.md) | Ngăn xếp công nghệ đã chốt + schema + rủi ro |
| [07-design-phase-plan.md](07-design-phase-plan.md) | Các bước giai đoạn thiết kế & tiền chuẩn bị |
| [08-scope.md](08-scope.md) | **Scope v1 đã chốt** — chức năng, lăng kính, cách hiển thị |
| [09-art-direction.md](09-art-direction.md) | **Hợp đồng thiết kế** — màu, chữ, bo góc, neumorphism, illustration |
| [10-libraries.md](10-libraries.md) | Chính sách thư viện, danh sách đề xuất, công cụ agent |
| [11-foundation-plan.md](11-foundation-plan.md) | **Phase nền tảng + Definition of Done từng phase** |
| [12-engineering-guide.md](12-engineering-guide.md) | **Quy ước cấu trúc & cách viết mã** |
