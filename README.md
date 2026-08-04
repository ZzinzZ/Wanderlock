# Wanderlock

[![CI](https://github.com/ZzinzZ/Wanderlock/actions/workflows/ci.yml/badge.svg)](https://github.com/ZzinzZ/Wanderlock/actions/workflows/ci.yml)

> Codename — tên chính thức chưa chốt. `wanderlock` là **định danh kỹ thuật**
> (tên package, bundle id) và được giữ ổn định kể cả khi tên thương hiệu đổi.
> Tên hiển thị lấy từ l10n nên đổi lúc nào cũng được.

App bản đồ tham quan được game hoá: mỗi địa điểm là một checkpoint bị khoá,
phải **thực sự đến nơi** để mở khoá — và một lần đến mở khoá cho **mọi** chế độ chơi.

Pilot: Quận 1 + rìa Chợ Lớn, TP.HCM.

---

## Bắt đầu

Yêu cầu: Flutter **3.44.8** (ghim trong [`app/.fvmrc`](app/.fvmrc)), Android SDK,
Xcode (nếu build iOS).

Cài FVM một lần (PowerShell quyền quản trị):

```bash
choco install fvm -y
```

Rồi lấy đúng phiên bản đã ghim và nạp phụ thuộc:

```bash
cd app && fvm install && fvm flutter pub get
```

```bash
cp .env.example .env
```

Chuỗi hiển thị sinh từ `lib/l10n/*.arb`, **không commit mã sinh ra**:

```bash
cd app && fvm flutter gen-l10n
```

## Các cổng kiểm tra (chạy đúng như CI)

```bash
cd app && fvm flutter gen-l10n && fvm dart format --output=none --set-exit-if-changed . && fvm flutter analyze --fatal-infos --fatal-warnings && fvm dart run ../tool/check_design_tokens.dart && fvm dart run ../tool/check_architecture.dart && fvm flutter test
```

| Cổng | Chặn cái gì |
|------|-------------|
| [check_design_tokens](tool/check_design_tokens.dart) | Màu, bo góc, cỡ chữ, thời lượng animation viết cứng ngoài `design/tokens/`. Có lối thoát `// design-token-ignore: <lý do>` |
| [check_architecture](tool/check_architecture.dart) | Feature import chéo nhau, `unlock` phụ thuộc ngược, `domain` dính package ngoài, `presentation` gọi thẳng `data`, `design` dính `features`. **Không có lối thoát** |

> Tên job CI là `quality gates` và **không được đổi** — nó là required status
> check trong ruleset bảo vệ `main`. Thêm cổng thì thêm bước, đừng đổi tên job.

## Nền tảng

| | Trạng thái |
|---|---|
| Android | Phát triển và chạy trên máy thật |
| iOS | **Chỉ kiểm tra biên dịch** trên CI runner macOS. Chạy trên máy iOS thật là **nợ kỹ thuật** phải trả trước bản thử nghiệm — xem [docs/11-foundation-plan.md](docs/11-foundation-plan.md) |

Job [`iOS build`](.github/workflows/ios-build.yml) không chạy ở mỗi PR vì
runner macOS tính phí gấp 10 lần trên repo private. Nó chạy khi `main` đổi,
và chạy tay được:

```bash
gh workflow run "iOS build"
```

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
