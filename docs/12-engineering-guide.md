# Quy ước cấu trúc & cách viết mã

> Mục đích: mọi người và mọi agent viết ra cùng một kiểu mã. Tài liệu này **bắt buộc**, không phải gợi ý.

---

## 1. Ngôn ngữ

| Nơi | Ngôn ngữ |
|-----|----------|
| Mã nguồn, tên biến, tên file, comment | **Tiếng Anh** |
| Tài liệu trong `docs/` | Tiếng Việt |
| Nội dung hiển thị cho người dùng | Tiếng Việt, đặt trong file l10n |
| Commit message, PR | Tiếng Anh |

### Từ điển thuật ngữ (bắt buộc dùng đúng, không đặt tên khác)

| Tiếng Việt | Trong mã |
|-----------|----------|
| Checkpoint / địa điểm | `Checkpoint` |
| Trạng thái mở khóa | `VisitState` |
| Lăng kính / chế độ | `Lens` |
| Cắm mắt / sương mù | `Fog` |
| Chương truyện | `StoryChapter` |
| Người dẫn truyện | `Narrator` |
| Tuyến nhiệm vụ | `Quest` |
| Lộ trình tự tạo | `Itinerary` |
| Tem / huy hiệu | `Stamp` |
| Bản đồ ký ức | `MemoryMap` |
| Mở khóa | `unlock` |
| Điểm đã ghé | `visited` |

> Cấm đặt tên kiểu `diaDiem`, `moKhoa`, hay trộn Việt–Anh trong một định danh.

---

## 2. Cấu trúc thư mục

```
Wanderlock/
├─ app/                     # ứng dụng Flutter
│  ├─ lib/
│  │  ├─ main.dart
│  │  ├─ app/               # bootstrap, router, theme, DI gốc
│  │  ├─ design/            # design token + thành phần UI dùng chung
│  │  │  ├─ tokens/         # màu, bo góc, thang chữ, bóng, motion
│  │  │  └─ widgets/        # nút, thẻ, sheet, chip...
│  │  ├─ core/              # tiện ích dùng chung: lỗi, kết quả, extension
│  │  ├─ features/
│  │  │  ├─ checkpoint/
│  │  │  ├─ unlock/         # TẦNG NỀN — visit_state
│  │  │  ├─ fog/
│  │  │  ├─ story/
│  │  │  ├─ quest/
│  │  │  ├─ itinerary/
│  │  │  └─ collection/
│  │  └─ l10n/
│  └─ test/
├─ content/                 # JSON: checkpoints, stories, quests
├─ supabase/
│  ├─ migrations/
│  └─ functions/            # edge function xác thực check-in
├─ spikes/                  # mã thử nghiệm — KHÔNG đưa vào lib/
├─ docs/
└─ CLAUDE.md
```

### Bên trong mỗi feature — 4 lớp

```
features/<name>/
├─ domain/         # entity + interface repository. KHÔNG phụ thuộc gì bên ngoài
├─ data/           # dto, nguồn remote/local, cài đặt repository
├─ application/    # service, notifier, use case
└─ presentation/   # screen, widget
```

### Luật phụ thuộc (bất khả xâm phạm)

1. `domain` **không import** `data`, `application`, `presentation`, hay bất kỳ package bên ngoài nào ngoài Dart thuần.
2. `presentation` **không gọi thẳng** repository — phải qua `application`.
3. **Feature không import chéo nhau.** Ngoại lệ duy nhất: mọi feature được phép phụ thuộc vào `unlock` — nhưng `unlock` **không** được phụ thuộc ngược lại feature nào.
4. `design/` không được import `features/`.

> Luật 3 là cách bảo vệ kiến trúc 2 tầng bằng mã: các lăng kính đều đọc `unlock`, không lăng kính nào biết đến lăng kính khác.

---

## 3. Quy tắc bất khả xâm phạm về nghiệp vụ

1. **Chỉ `unlock` được ghi `visit_state`.** Không feature nào khác được ghi.
2. **Không lăng kính nào lưu trạng thái mở khóa riêng.** Mọi trạng thái suy ra từ `visit_state`.
3. **Check-in phải xác thực ở server.** Client chỉ gửi yêu cầu, không tự quyết.
4. Mọi ghi dữ liệu phải **an toàn khi lặp lại** — mở khóa 2 lần chỉ ghi 1 lần.

---

## 4. Đặt tên

| Loại | Quy tắc | Ví dụ |
|------|---------|-------|
| File, thư mục | `snake_case` | `visit_state_repository.dart` |
| Class, enum | `PascalCase` | `VisitStateRepository` |
| Biến, hàm | `camelCase` | `unlockCheckpoint()` |
| Hằng | `camelCase` có `const` | `defaultRadiusMeters` |
| Provider (Riverpod) | hậu tố `Provider` | `visitStateProvider` |
| Boolean | bắt đầu bằng `is/has/can` | `isVisited`, `canUnlock` |
| Đại lượng có đơn vị | **ghi đơn vị vào tên** | `radiusMeters`, `timeoutMs` |

---

## 5. Cách viết mã

- **Bất biến mặc định.** Model là class bất biến, có `copyWith`. Không sửa tại chỗ.
- **Không logic nghiệp vụ trong widget.** Widget chỉ đọc trạng thái và bắn sự kiện.
- **Trạng thái bất đồng bộ** dùng `AsyncValue` của Riverpod. UI phải xử lý đủ **3 nhánh**: đang tải / lỗi / có dữ liệu. Không được bỏ nhánh lỗi.
- **Lỗi** ném exception có kiểu ở tầng `data`; `application` bắt và chuyển thành trạng thái. Cấm `catch` rỗng nuốt lỗi.
- **Cấm `dynamic`** trừ khi bắt buộc khi giải mã JSON.
- **Kích thước:** file thường dưới ~300 dòng, hàm dưới ~40 dòng. Vượt thì tách, không phải xin phép.
- **Comment giải thích *vì sao*, không phải *cái gì*.** Mã tự nói được cái gì.
- **Không TODO không chủ.** Viết `// TODO(<tên>): <việc>` hoặc đừng viết.

---

## 6. Giao diện

- **Cấm viết cứng** mã màu, số bo góc, cỡ chữ, thời lượng animation. Tất cả lấy từ `design/tokens/`.
- Mỗi widget mới phải chạy đúng ở **cả chế độ sáng và tối**.
- Chuỗi hiển thị đặt trong l10n, không nằm trong widget.
- Thành phần dùng lại ≥ 2 nơi thì đưa vào `design/widgets/`.
- Tuân thủ [09-art-direction.md](09-art-direction.md), gồm cả luật *neumorphism cho bề mặt, khối đặc cho hành động*.
- **Ưu tiên thư viện** theo [10-libraries.md](10-libraries.md) thay vì tự dựng hiệu ứng.

---

## 7. Kiểm thử

| Loại | Bắt buộc cho |
|------|--------------|
| Unit | logic mở khóa, đồng bộ, chống gian lận, đơn giản hoá hình học fog |
| Widget | thành phần trong `design/widgets/` |
| Tích hợp | luồng check-in đầy đủ, gồm nhánh offline |

Bắt buộc có test cho: **mở khóa hợp lệ · ngoài bán kính · offline rồi đồng bộ · mở khóa trùng lặp · request giả từ client**.

---

## 8. Git

- Nhánh: `feat/<mô-tả-ngắn>`, `fix/…`, `spike/…`, `chore/…`. Nhánh sống ngắn.
- Commit theo Conventional Commits: `feat(unlock): verify check-in server-side`
- Không commit thẳng vào `main`. Không commit bí mật, không commit file build.
- Mỗi phase nền tảng kết thúc bằng tag `foundation-fN`.

---

## 9. Trước khi coi một task là xong

Xem mục **"Definition of Done áp dụng cho mọi task"** ở cuối [11-foundation-plan.md](11-foundation-plan.md).
