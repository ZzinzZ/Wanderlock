# Scope dự án (ĐÃ CHỐT — v1 / MVP)

> Ngày chốt: 2026-08-04 · Phạm vi sửa ngày 2026-08-05
> Pilot: **12 địa điểm rải khắp TP.HCM** (trung tâm · Chợ Lớn · Bình Thạnh · Tân Bình · Thủ Đức)
>
> **Đổi so với bản đầu:** ban đầu chốt "Quận 1 + rìa Chợ Lớn" để pilot đủ dày mà
> đi bộ hết được. Chủ dự án đổi sang rải khắp thành phố để bao được những điểm
> đặc sắc nhất và chứng minh app chạy ở nhiều dạng địa hình đô thị. Cái mất:
> **không còn đi bộ hết pilot trong một buổi** — giữa các điểm phải đi xe, và
> Fog of War mất mật độ vệt đi. Mục 6 bên dưới đã sửa theo.
> Nguyên tắc cắt scope: **giữ đủ 3 trụ (khám phá · story · lý do quay lại), cắt mọi thứ cần kiểm duyệt hoặc cần quy mô người dùng.**

---

## 1. Luận điểm mà v1 phải chứng minh

> **"Một lần đến, mở khóa cho mọi cách chơi."**

Muốn chứng minh được, v1 tối thiểu phải có **≥ 2 lăng kính trông khác hẳn nhau** cùng đọc **một** tầng mở khóa. Mọi thứ không phục vụ luận điểm này đều bị đẩy sang sau.

---

## 2. Chốt phạm vi: TRONG / NGOÀI v1

### ✅ TRONG v1

| # | Chức năng | Ghi chú |
|---|-----------|---------|
| F1 | **Bản đồ + định vị người dùng** | MapLibre, style tối |
| F2 | **Check-in & mở khóa checkpoint** | ⭐ **Trái tim hệ thống** — ghi vào `visit_state` |
| F3 | **Chống gian lận cơ bản** | Xác thực server-side, cờ mock-location, fallback QR |
| F4 | **Lens Switcher** (chuyển lăng kính tức thì) | Bằng chứng trực quan cho luận điểm |
| F5 | **Lăng kính Fog of War** | Vệt đi + vùng đã sáng |
| F6 | **Lăng kính Story** | Trình phát chương truyện + người dẫn truyện |
| F7 | **Lăng kính Quest** | 1 tuyến duy nhất ở v1 |
| F8 | **Lăng kính Sưu tầm** | Tem + Bản đồ ký ức |
| F9 | **Tài khoản + đồng bộ** | Supabase Auth |
| F10 | **Hoạt động offline** | Cache map + hàng đợi check-in, sync khi có mạng |
| F11 | **Lăng kính Tùy chỉnh hành trình** | Người dùng tự chọn & sắp thứ tự checkpoint |

### ❌ NGOÀI v1 (đẩy sang sau)

| Bị cắt | Vì sao | Đưa vào |
|--------|--------|---------|
| **Lăng kính Xã hội** (dấu chân, lời nhắn, xếp hạng) | Cần kiểm duyệt nội dung + cần đông người mới vui | v1.5 |
| Nhiệm vụ nhóm (D3) | Phụ thuộc Xã hội | v2 |
| Cây danh hiệu (C2) | Chỉ có ý nghĩa khi nhiều checkpoint | v1.5 |
| Checkpoint "bí mật"/easter egg (A2 tầng 3) | Vui, nhưng không chứng minh luận điểm | v1.5 |
| Vùng khóa theo điều kiện (A3) | Pilot quá nhỏ để cảm nhận | v1.5 |
| Story theo thời điểm trong ngày (B4) | Nhân đôi khối lượng nội dung | v1.5 |
| Câu chuyện phân mảnh (B3) | Cần nhiều điểm mới ghép được | v2 |
| CMS (Directus) | 8–12 điểm thì file JSON đủ | v2 |
| AR | Chi phí lớn, không thuộc lõi | v2+ |
| Đa thành phố / đa ngôn ngữ | Pilot 1 khu trước | v2 |

---

## 3. Năm lăng kính cốt lõi của v1

Lưu ý về khối lượng công việc — **hai lăng kính "dày", hai lăng kính "mỏng"**:

| Lăng kính | Độ dày | Vì sao | Cảm giác chủ đạo |
|-----------|--------|--------|------------------|
| 🗺️ **Fog of War** | **Dày** (kỹ thuật) | Phải tự vẽ overlay, tối ưu hiệu năng | *Chinh phục* |
| 📖 **Story** | **Dày** (nội dung) | Mỗi điểm cần một chương truyện được biên tập | *Thấu hiểu & cảm xúc* |
| 🎯 **Quest** | Mỏng | Chỉ là chuỗi checkpoint + tiến độ, đọc từ `visit_state` | *Mục tiêu & thành tựu* |
| 🏅 **Sưu tầm** | Mỏng | Suy trực tiếp từ `visit_state`, gần như miễn phí | *Tích lũy & dấu ấn* |
| 🧭 **Tùy chỉnh hành trình** | Mỏng | Chỉ là danh sách có thứ tự trỏ tới checkpoint | *Chủ động & kiểm soát* |

> Chọn 5 chứ không phải 2, vì Quest, Sưu tầm và Tùy chỉnh hành trình **gần như không tốn thêm code** (chúng chỉ diễn giải lại dữ liệu đã có) nhưng lại cung cấp *lý do quay lại*, *lý do chia sẻ* và *lý do dùng cho chuyến đi thật*. Đây chính là lợi tức của kiến trúc 2 tầng.

---

## 4. Nội dung tối thiểu cho v1

| Hạng mục | Số lượng v1 |
|----------|-------------|
| Checkpoint | **12** (rải khắp TP.HCM) |
| Chương truyện | **8–12** (mỗi checkpoint 1 chương, 2–4 phút đọc) |
| Người dẫn truyện | **1** |
| Tuyến quest | **1** (xuyên 4–6 checkpoint, có mở–thân–kết) |
| Tem | 1 tem / checkpoint |

---

## 5. Show lên cho người dùng thế nào

### 5.1 Nguyên tắc trình bày

1. **Bản đồ là ứng dụng.** Không có "trang chủ" riêng — mở app là thấy bản đồ toàn màn hình.
2. **Đổi lăng kính = bản đồ biến hình tại chỗ.** Không chuyển trang, không tải lại, camera giữ nguyên vị trí. Người dùng phải *thấy* rằng đó vẫn là bản đồ của mình.
3. **Khoảnh khắc mở khóa là ngôi sao.** Đây là 3 giây bán được sản phẩm — phải điện ảnh, không phải một cái toast.

### 5.2 Kiến trúc màn hình (6 màn)

```
┌─────────────────────────────────────┐
│  ① MAP (màn hình chính, toàn màn)   │
│     • bản đồ tối                     │
│     • thẻ trồi lên khi đến gần       │
│     • Lens Switcher ở đáy            │
└──────┬──────────────────────────────┘
       ├─ ② Checkpoint detail (bottom sheet)
       ├─ ③ Story player (toàn màn, chiếm trọn)
       ├─ ④ Quest (danh sách + chi tiết tuyến)
       ├─ ⑤ Bộ sưu tập (lưới tem)
       └─ ⑥ Bản đồ ký ức (ảnh chia sẻ được)
```

### 5.3 Ba trạng thái của một checkpoint (nhất quán ở MỌI lăng kính)

| Trạng thái | Hiển thị |
|------------|----------|
| `unknown` — chưa biết | Không hiện gì, chìm trong sương mù |
| `revealed` — đã lộ | Chấm mờ, không tên, chỉ gợi "có gì đó ở đây" |
| `visited` — đã ghé | Sáng rõ, có tên, có màu theo phân loại |

> Ba trạng thái này đọc từ **cùng một** `visit_state`. Đó là lý do mở ở lăng kính nào cũng sáng ở mọi lăng kính.

### 5.4 Cùng một bản đồ, bốn cách hiển thị

| Lăng kính | Bản đồ trông thế nào | Chạm vào checkpoint đã mở thì ra gì |
|-----------|----------------------|--------------------------------------|
| 🗺️ Fog | Tối, có vệt sáng theo đường đã đi, checkpoint phát sáng | Thẻ ngắn: tên + thời điểm ghé |
| 📖 Story | Sáng hơn, checkpoint có chương truyện hiện icon sách | Mở **Story player** toàn màn |
| 🎯 Quest | Chỉ nổi bật các điểm thuộc tuyến, có đường nối thứ tự | Bước thứ mấy / còn lại gì |
| 🏅 Sưu tầm | Checkpoint hiện dưới dạng **con tem** | Xem tem cỡ lớn + chi tiết |
| 🧭 Tùy chỉnh | Checkpoint có nút thêm vào lộ trình, điểm đã chọn được đánh số | Thêm / bỏ / đổi thứ tự trong lộ trình |

**Lens Switcher:** thanh chính 3 mục (Bản đồ · Sưu tầm · Hành trình), trong đó Hành trình gom Quest và Tùy chỉnh. Chạm → bản đồ chuyển tiếp mượt sang cách hiển thị mới, **giữ nguyên vị trí camera và toàn bộ trạng thái mở khóa**.

### 5.5 Luồng "trải nghiệm vàng" (60 giây phải làm đúng)

```
Đi bộ, bản đồ tối dần hé sáng quanh mình
        ↓
Vào bán kính → thẻ trồi lên từ đáy:
   "Bạn đang đứng trước Bưu điện Thành phố"   [Mở khóa]
        ↓
Chạm → xác thực vị trí (server) → THÀNH CÔNG
        ↓
★ KHOẢNH KHẮC MỞ KHÓA (toàn màn, ~3 giây)
   sương tan · ánh sáng lan ra · tên địa điểm hiện
   con tem rơi vào bộ sưu tập
        ↓
Người dẫn truyện lên tiếng → mời đọc chương truyện
        ↓
Quay lại bản đồ: điểm đã sáng ở MỌI lăng kính
```

### 5.6 Trạng thái biên bắt buộc phải thiết kế

- Gần nhưng **chưa đủ gần** → hiện khoảng cách còn lại, không hiện nút mở khóa
- **GPS yếu / sai lệch** → gợi ý quét QR tại điểm
- **Mất mạng** → vẫn mở khóa được, xếp hàng đồng bộ sau, báo rõ cho người dùng
- **Nghi ngờ gian lận** → không từ chối thẳng, chuyển sang xác thực bằng QR / câu đố quan sát

---

## 6. Tiêu chí "v1 đã xong"

1. Đi thật tới ≥ 8 trong 12 checkpoint và mở khóa được — nhiều buổi, di chuyển bằng xe giữa các cụm
2. Chuyển qua lại 5 lăng kính, trạng thái mở khóa **luôn nhất quán**
3. Hoàn thành trọn 1 tuyến quest, và tự dựng được 1 lộ trình riêng
4. Đọc được 8–12 chương truyện
5. Xuất được Bản đồ ký ức để chia sẻ
6. Hoạt động khi mất mạng, đồng bộ lại đúng
7. Đi bộ liên tục 2 giờ: app không tụt khung hình, không ngốn pin bất thường

> Mục 7 giờ là **bài đo riêng**, không còn là hệ quả tự nhiên của việc đi hết
> pilot. Pilot rải khắp thành phố nên phải chủ động dành một buổi đi bộ liên
> tục để đo — nếu không, Fog of War và mức hao pin sẽ không bao giờ bị thử ở
> đúng điều kiện mà người dùng thật sẽ gặp.
