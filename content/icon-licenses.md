# Nguồn và giấy phép — icon

Song song với `image-licenses.md` (dành cho ảnh địa danh). Hai loại tài sản
này có luật khác hẳn nhau nên tách bảng: ảnh địa danh vướng bản quyền công
trình, còn icon thì không.

---

## Nguồn duy nhất: 3dicons.co

| | |
|---|---|
| Trang | https://3dicons.co |
| Mã nguồn | https://github.com/realvjy/3dicons |
| Tác giả | Vijay Verma (realvjy) |
| Giấy phép | **CC0 1.0** — miễn phí cho mọi mục đích, kể cả thương mại, **không bắt buộc ghi nguồn** |
| Số icon | 120 (bản đã tải về ngày 2026-08-25) |
| Biến thể đang dùng | **`color`** — nguyên màu gốc, không nhuộm |
| Cũng đã tải | `clay` — giữ lại phòng khi cần bề mặt một màu theo token |

Ghi nguồn ở đây dù CC0 không bắt buộc, cho nhất quán với cách quản lý ảnh ở
mục 7.1 art direction, và để sau này còn truy được icon đến từ đâu.

### Vì sao `color`

3dicons có 4 biến thể vật liệu cho mỗi icon:

| Biến thể | Dùng? | Lý do |
|---|---|---|
| `color` | ✅ **đang dùng** | Chủ dự án chốt 2026-08-25: app hướng trẻ trung, dùng nguyên màu gốc |
| `clay` | 🗄 giữ, không dùng | Đơn sắc, nhuộm được theo token — để dành cho bề mặt cần một màu |
| `gradient` | ❌ | Gradient phẳng trang trí, không phải đổ bóng khối |
| `premium` | ❌ | Phản chiếu kim loại — phạm mục 10 art direction |

> Quyết định buổi sáng cùng ngày là `clay` + tự nhuộm. Chủ dự án đổi sang
> `color`. Chi tiết và hai chỗ chạm danh sách cấm: mục 7.3 art direction.

---

## Đã tải về những gì

```
content/icons/3dicons-manifest.json   # 120 icon: tên, nhóm, góc, URL cả 4 biến thể
content/icons/3dicons-color/*.png     # 120 file PNG color, 400×400, ~8,3 MB  ← đang dùng
content/icons/3dicons-clay/*.png      # 120 file PNG clay,  400×400, ~4,9 MB  ← dự phòng
app/assets/icons/*.png                # 26 file color — chỉ những cái app đang vẽ
```

**Thư viện tách khỏi bundle là cố ý.** Mọi thứ trong `app/assets/` đều nằm
trong file cài đặt dù có vẽ ra hay không. Giữ đủ 120 icon ở `content/` để chọn
thoải mái, chép sang `app/assets/icons/` khi màn hình thật sự dùng đến.

Manifest giữ URL CDN gốc của từng icon, nên tải lại hay đổi sang biến thể khác
đều không phải đi tìm lại.

---

## Đặc điểm kỹ thuật đã đo, không phải đọc

Đo bằng Pillow trên file thật.

**Bản `color` (đang dùng):** 400×400 RGBA nền trong suốt · bão hoà 0,55–0,84 ·
độ sáng 0,54–0,87 · dải màu trải rộng: cam 34° (`sun`), xanh lá 95° (`medal`),
xanh ngọc 164–190° (`explorer` `lock` `tick`), xanh dương 245° (`notebook`);
riêng `key` là bạc xám không bão hoà. Dùng nguyên bản, **không nhuộm** — xem
`app/lib/design/widgets/app_icon.dart`.

**Bản `clay` (dự phòng):** 100% pixel đục là đơn sắc (r = g = b), nhưng có dải
sáng-tối luma 137–239 — đó chính là khối 3D. Nếu sau này dùng tới, phải nhuộm
bằng `BlendMode.modulate` (nhân) chứ không phải `srcIn`: `srcIn` tô mọi pixel
một màu phẳng và làm icon bẹp thành bóng đổ. Và vì phép nhân **chỉ làm tối đi**,
màu nhuộm phải là màu trung tính hoặc sáng — nhuộm bằng mực đậm thì ra hình đen.
*(Đã thử trên máy ảo, đúng là ra hình đen.)*

---

## 26 icon đang bundle

| Dùng ở đâu | Slug |
|---|---|
| Lăng kính: Bản đồ · Sưu tầm · Hành trình | `map-pin` `medal` `explorer` |
| Trạng thái checkpoint (mục 5.3) | `lock` `tick` `pin` |
| Hành động trên checkpoint | `key` `plus` `notebook` `target` |
| Điều khiển bản đồ | `location` |
| Story player | `play` `pause` `next` `back` |
| Quest và phần thưởng | `flag` `trophy` `star` |
| Bản đồ ký ức | `camera` `picture` |
| Cài đặt và chủ đề | `setting` `sun` `moon` |
| Trạng thái biên (mục 5.6) | `wifi` `puzzle` `sheild` |

---

## ⚠️ Bộ 120 icon KHÔNG có những cái này

Đã tra hết 120 slug. Ba chỗ dưới đây vẫn đang dùng Material Icons, mỗi chỗ có
chú thích `clay-icon-gap` ngay tại dòng mã, và có test đếm chúng để con số
không lặng lẽ tăng lên:

| Cần | Ở đâu | Vì sao chưa thay |
|---|---|---|
| Đóng (×) | Thẻ checkpoint | Không có glyph close. Xoay `plus` 45° đọc ra là mẹo vặt, không phải nút |
| Tải lại | Danh sách checkpoint | Không có glyph refresh/reload |
| Tải bản đồ offline | Màn bản đồ | Không có glyph download/cloud |

Ngoài ra còn hai thứ **sẽ cần** khi làm tới, và cũng không có sẵn:

- **QR** — mục 5.6 nói GPS yếu thì mời quét QR. Không có icon QR nào trong bộ.
- **Chia sẻ** — Bản đồ ký ức (màn ⑥) cần nút chia sẻ.

Ba đường đi khi chạm phải một lỗ hổng: đặt vẽ riêng cho khớp bộ, tìm bộ CC0
khác cùng chất 3D, hoặc chấp nhận một icon phẳng cho đúng mấy nút công cụ đó.
**Chưa quyết** — cần chủ dự án chọn.
