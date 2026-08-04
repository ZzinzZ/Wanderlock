# Wanderlock

> Codename — tên chính thức chưa chốt. `wanderlock` là **định danh kỹ thuật**
> (tên package, bundle id) và được giữ ổn định kể cả khi tên thương hiệu đổi.
> Tên hiển thị lấy từ l10n nên đổi lúc nào cũng được.

App bản đồ tham quan được game hoá: mỗi địa điểm là một checkpoint bị khoá,
phải **thực sự đến nơi** để mở khoá — và một lần đến mở khoá cho **mọi** chế độ chơi.

Pilot: Quận 1 + rìa Chợ Lớn, TP.HCM.

---

## Bắt đầu

Yêu cầu: Flutter **3.44.8** (ghim trong [`.fvmrc`](.fvmrc)), Android SDK, Xcode (nếu build iOS).

```bash
dart pub global activate fvm
```

```bash
fvm install && fvm use
```

```bash
cp .env.example .env
```

```bash
cd app && fvm flutter pub get
```

## Các cổng kiểm tra (chạy đúng như CI)

```bash
cd app && fvm dart format --output=none --set-exit-if-changed . && fvm flutter analyze --fatal-infos --fatal-warnings && fvm dart run ../tool/check_design_tokens.dart && fvm flutter test
```

`check_design_tokens` chặn màu, bo góc, cỡ chữ và thời lượng animation viết cứng
ở ngoài `app/lib/design/tokens/`. Xem [tool/check_design_tokens.dart](tool/check_design_tokens.dart).

## Cấu trúc

| Thư mục | Nội dung |
|---------|----------|
| `app/` | Ứng dụng Flutter |
| `content/` | JSON nội dung pilot + bảng bản quyền ảnh |
| `supabase/` | Migration + edge function xác thực check-in |
| `spikes/` | Mã thử nghiệm — **không** đưa vào `app/lib/` |
| `docs/` | Tài liệu nền tảng (tiếng Việt) |
| `tool/` | Script kiểm tra dùng cho CI |

## Tài liệu

Bắt đầu từ [docs/00-overview.md](docs/00-overview.md). Trước khi viết mã, đọc
[docs/12-engineering-guide.md](docs/12-engineering-guide.md) và
[CLAUDE.md](CLAUDE.md).

Đang ở phase nào và Definition of Done: [docs/11-foundation-plan.md](docs/11-foundation-plan.md).

## Quy ước

- Trao đổi: tiếng Việt · Mã nguồn, commit: tiếng Anh
- Commit theo Conventional Commits — `feat(unlock): verify check-in server-side`
- Nhánh `feat/…`, `fix/…`, `spike/…`, `chore/…`. Không commit thẳng vào `main`.
