# Chính sách thư viện & danh sách đề xuất

> Nguyên tắc của chủ dự án: **ưu tiên dùng thư viện có sẵn thay vì tự build**, để giao diện đạt đúng chất lượng mong muốn thay vì thoả hiệp vì giới hạn tự code.

---

## 1. Chính sách

1. **Tra trước, code sau.** Trước khi tự viết một thành phần UI hoặc một tiện ích, phải tìm thư viện đã giải quyết bài toán đó.
2. **Dùng Context7 để lấy tài liệu đúng phiên bản** — không code theo trí nhớ về API.
3. **Chỉ tự viết khi** không có thư viện phù hợp, hoặc thư viện kéo theo phụ thuộc nặng/không được bảo trì, hoặc đây là phần lõi khác biệt của sản phẩm (Fog of War, tầng mở khóa).
4. **Trước khi thêm bất kỳ package nào**, kiểm tra: lần cập nhật gần nhất, số issue mở, có hỗ trợ đủ iOS + Android, giấy phép.
5. **Ngược lại — không lạm dụng.** Nếu nền tảng đã có sẵn (haptic, chia sẻ, định dạng ngày giờ) thì dùng thẳng, không kéo thêm package.

> Hai nguyên tắc 1 và 5 nghe mâu thuẫn nhưng không phải: **thư viện cho thứ khó (đồ hoạ, bản đồ, đồng bộ), nền tảng cho thứ đã có sẵn.**

---

## 2. Danh sách đề xuất theo lớp

> ⚠️ Danh sách là **điểm khởi đầu**, không phải chốt cuối. Trước khi đưa vào `pubspec.yaml`, kiểm tra trạng thái bảo trì và độ tương thích phiên bản Flutter đang dùng.

### Bản đồ & vị trí
| Nhu cầu | Đề xuất |
|---------|---------|
| Render bản đồ vector, style tuỳ biến | `maplibre_gl` |
| Bản đồ nhẹ thay thế (tile-based) | `flutter_map` |
| Lấy vị trí, độ chính xác, cờ mock | `geolocator` |
| Geofence checkpoint | plugin geofence gắn API gốc của OS |
| Quyền truy cập | `permission_handler` |
| Trạng thái mạng | `connectivity_plus` |

### Đồ hoạ & hiệu ứng — nơi nên "xài thư viện" nhiều nhất
| Nhu cầu | Đề xuất | Ghi chú |
|---------|---------|---------|
| **Illustration 3D clay có animation** | **`rive`** | ⭐ Quan trọng nhất. Cho phép landmark và nhân vật dẫn truyện chuyển động, nhẹ hơn video, đổi trạng thái theo dữ liệu — rất hợp cảnh "tô màu illustration khi mở khóa" |
| Animation dựng sẵn từ After Effects | `lottie` | Dùng cho hiệu ứng một lần |
| Chuỗi animation trong code | `flutter_animate` | Viết ngắn, dễ đọc |
| Bề mặt neumorphic | package neumorphic đang được bảo trì | Chỉ dùng cho bề mặt, không dùng trên bản đồ — xem [09-art-direction.md](09-art-direction.md) |
| Khung xương lúc tải | `skeletonizer` |  |
| Hiệu ứng ăn mừng lúc mở khóa | `confetti` | Chỉ trong 3 giây mở khóa |
| SVG | `flutter_svg` |  |
| Cache ảnh mạng | `cached_network_image` |  |

### Dữ liệu & nền tảng
| Nhu cầu | Đề xuất |
|---------|---------|
| Backend, auth, realtime, storage | `supabase_flutter` |
| CSDL cục bộ / offline | `drift` |
| Quản lý trạng thái | `riverpod` |
| Điều hướng | `go_router` |
| Tác vụ nền (đồng bộ hàng đợi) | `workmanager` |
| Lưu bí mật | `flutter_secure_storage` |
| Quét QR (chống gian lận) | `mobile_scanner` |
| Push | `firebase_messaging` |
| Analytics | `posthog_flutter` |
| Font | `google_fonts` (sau khi test dấu tiếng Việt) |

### Kiểm thử
`mocktail` · công cụ test tích hợp trên thiết bị thật (cần cho luồng GPS)

---

## 3. Phần **không** dùng thư viện

| Phần | Vì sao tự viết |
|------|----------------|
| **Fog of War** | Không có thư viện nào làm đúng thứ ta cần; đây là khác biệt lõi của sản phẩm |
| **Tầng mở khóa (`visit_state`)** | Là nguồn sự thật duy nhất, phải tự kiểm soát hoàn toàn |
| **Logic chống gian lận check-in** | Không giao cho bên thứ ba |
| **Định dạng chương truyện** | Đã chốt dùng JSON tự định nghĩa — xem [06-tech-stack.md](06-tech-stack.md) |

---

## 4. Công cụ hỗ trợ đã cài cho agent

| Công cụ | Loại | Trạng thái | Dùng để làm gì |
|---------|------|-----------|----------------|
| **Context7** | MCP server | ✅ Đã cấu hình tại `.mcp.json` | Lấy tài liệu thư viện đúng phiên bản, tránh API bịa |
| **Ponytail** | Plugin Claude Code | ⏳ Cần chủ dự án tự cài (2 lệnh slash) | Ép agent viết ít code, ưu tiên thứ đã có sẵn |
| **React Bits** | Thư viện React (web) | ⛔ Chưa cài | **Không dùng được với Flutter hay React Native** — chỉ dùng khi làm landing page web ở giai đoạn sau |

### Cài Ponytail (chủ dự án tự chạy, gõ lần lượt 2 lệnh)

```
/plugin marketplace add DietrichGebert/ponytail
```

```
/plugin install ponytail@ponytail
```

### Context7 — nâng giới hạn (tuỳ chọn)
`.mcp.json` hiện dùng endpoint công khai, không cần khoá. Nếu bị giới hạn tần suất, lấy API key miễn phí tại context7.com rồi thêm header `Authorization: Bearer <KEY>`.
