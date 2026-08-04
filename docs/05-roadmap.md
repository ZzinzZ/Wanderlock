# Lộ trình & MVP

> Trạng thái hiện tại: **định hình sản phẩm (pre-MVP)**. Lộ trình dưới đây là bản phác thảo để định hướng, chưa cố định ngày.

---

## Nguyên tắc: MVP tối thiểu nhưng đủ "hồn"

MVP phải chứng minh được **3 trụ** cùng lúc (khám phá + story + lý do quay lại), nếu không sẽ không khác gì một app check-in thường.

**Bộ lõi MVP đề xuất:**
- **A1** Sương mù động (Fog of War)
- **B1 + B2** Chương truyện tại chỗ + người dẫn truyện
- **E1** 1–2 tuyến quest chủ đề
- **C1 + C3** Tem + bản đồ ký ức

---

## Các giai đoạn

### Giai đoạn 0 — Định hình (đang ở đây)
- [x] Chốt insight cốt lõi (2 tầng: unlock vs. lens)
- [x] Viết docs tổng quan
- [ ] Chốt tên sản phẩm chính thức
- [ ] Chọn 5–10 checkpoint pilot ở TP.HCM
- [ ] Viết thử 1 chương truyện mẫu (1 địa điểm)

### Giai đoạn 1 — Prototype trải nghiệm
- [ ] Mockup UI: bản đồ + chuyển lăng kính
- [ ] Prototype fog of war trên bản đồ
- [ ] Luồng check-in GPS + mở khóa 1 checkpoint
- [ ] Demo 1 chương truyện tương tác

### Giai đoạn 2 — MVP có thể chơi
- [ ] Unlock Layer + đồng bộ (single source of truth)
- [ ] 2 lăng kính đầu: Fog of War + Story
- [ ] 1 tuyến quest hoàn chỉnh (Quest lens)
- [ ] Tem + bản đồ ký ức (Sưu tầm)
- [ ] Chống gian lận GPS cơ bản (bán kính + tùy chọn QR)

### Giai đoạn 3 — Mở rộng
- [ ] Thêm lăng kính Xã hội (dấu chân, xếp hạng)
- [ ] Công cụ biên soạn nội dung (thủ công / cộng đồng / hỗ trợ AI)
- [ ] Mở rộng số checkpoint & thêm tuyến quest
- [ ] Chuẩn bị khung đa thành phố

---

## Câu hỏi mở cần quyết định

1. **Nền tảng:** Mobile-first (iOS/Android)? Cross-platform (Flutter / React Native) hay native?
2. **Bản đồ:** Mapbox / Google Maps SDK / MapLibre? (ảnh hưởng chi phí & khả năng tùy biến fog of war)
3. **Nguồn nội dung:** ai viết story? mô hình cộng đồng đóng góp?
4. **Mô hình kinh doanh:** miễn phí + tuyến quest cao cấp trả phí? hợp tác với bảo tàng / du lịch / thành phố?
5. **Tên & thương hiệu chính thức.**

---

## Rủi ro chính

| Rủi ro | Giảm thiểu |
|--------|-----------|
| Nội dung story tốn công biên soạn | Bắt đầu ít điểm, chất lượng cao; tính đến công cụ hỗ trợ |
| Gian lận GPS | QR tại điểm + câu đố quan sát (E2) |
| Tốn pin (fog nền) | Tối ưu tần suất cập nhật vị trí |
| "Chơi vài lần rồi bỏ" | Tuyến quest + nội dung mới định kỳ + yếu tố sưu tầm |
