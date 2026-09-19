# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Wanderlock — hướng dẫn cho agent

App bản đồ tham quan được game hoá: mỗi địa điểm là một checkpoint bị khóa, phải **thực sự đến nơi** để mở khóa — và một lần đến mở khóa cho **mọi** chế độ chơi.

Pilot: TP.HCM — 12 địa danh gốc (đã kiểm chứng toạ độ) + ~265 điểm nạp từ OpenStreetMap (`verified: false`). App Flutter đã chạy được; đang ở các phase nền tảng F2–F5, xem [CHECKPOINT.md](CHECKPOINT.md) (có thể cũ) và [docs/11-foundation-plan.md](docs/11-foundation-plan.md).

## Đọc gì trước khi làm

| Việc bạn định làm | Đọc trước |
|-------------------|-----------|
| Bất cứ việc gì | [docs/00-overview.md](docs/00-overview.md) |
| Viết mã, tạo file | [docs/12-engineering-guide.md](docs/12-engineering-guide.md) |
| Làm giao diện | [docs/09-art-direction.md](docs/09-art-direction.md) — **mục 0 (sticker cartoon) thắng các mục cũ khi mâu thuẫn** |
| Thêm tính năng | [docs/08-scope.md](docs/08-scope.md) — đọc cả các khối "Sửa ngày…" ở đầu |
| Chọn thư viện | [docs/10-libraries.md](docs/10-libraries.md) |
| Sửa nội dung (địa điểm, nhiệm vụ) | [content/README.md](content/README.md) + `_readme` trong từng file JSON |
| Biết đang ở đâu trong lộ trình | [docs/11-foundation-plan.md](docs/11-foundation-plan.md) |

## Quy tắc bất khả xâm phạm

1. **Một tầng mở khóa duy nhất.** Mọi lăng kính đọc chung `visit_state`. Chỉ feature `unlock` được ghi vào đó. Không lăng kính nào lưu trạng thái mở khóa riêng.
2. **Không tin client.** Check-in xác thực ở server. Client chỉ gửi yêu cầu.
3. **Không viết cứng giá trị thiết kế.** Màu, bo góc, cỡ chữ, thời lượng animation đều lấy từ `design/tokens/`.
4. **Không mở rộng ngoài scope v1** (5 lăng kính: Fog · Story · Quest · Sưu tầm · Tùy chỉnh hành trình). Xã hội đã hoãn sang v1.5 — đừng thêm vào. Chủ dự án đổi scope thì ghi quyết định vào `docs/08-scope.md` trước.
5. **Ưu tiên thư viện có sẵn** thay vì tự build. Ngoại lệ tự viết: Fog of War, tầng mở khóa, logic chống gian lận.
6. **Dùng Context7 để lấy tài liệu thư viện** đúng phiên bản — không code theo trí nhớ về API.

## Lệnh thường dùng

Flutter ghim ở `app/.fvmrc` (3.44.8), chạy qua `fvm`. Trên máy dev này PATH của agent có thể cũ — gọi thẳng `C:\Users\nhata\fvm\versions\3.44.8\bin\flutter.bat` / `dart.bat` nếu `fvm` không có.

Mã sinh ra (`lib/l10n/generated/`, `*.g.dart` của drift) **bị gitignore** — sau khi checkout hoặc sửa `.arb` / bảng drift phải sinh lại:

```bash
cd app && fvm flutter gen-l10n && fvm dart run build_runner build
```

Các cổng kiểm tra, đúng thứ tự CI (`.github/workflows/ci.yml`, job `quality gates` — **không đổi tên job**, nó là required check của `main`):

```bash
cd app && fvm dart format --output=none --set-exit-if-changed . && fvm flutter analyze --fatal-infos --fatal-warnings && fvm dart run ../tool/check_design_tokens.dart && fvm dart run ../tool/check_architecture.dart && fvm dart run ../tool/check_encoding.dart && fvm flutter test --exclude-tags "golden || live"
```

`dart format --output=none` chỉ kiểm, không ghi — muốn sửa thật chạy `fvm dart format lib test` trước.

| Việc | Lệnh |
|------|------|
| Một file test | `cd app && fvm flutter test test/features/fog/fog_trail_test.dart` |
| Một test theo tên | `cd app && fvm flutter test --plain-name "a set has no" test/app/quest_sets_test.dart` |
| Test golden / chạm Supabase thật | tag `golden` và `live` — CI loại cả hai |
| Build APK | `cd app && fvm flutter build apk --release` (ký bằng khoá debug) → `app/build/app/outputs/flutter-apk/app-release.apk` |
| Nối Supabase | `--dart-define=SUPABASE_URL=… --dart-define=SUPABASE_PUBLISHABLE_KEY=…` (xem `.env.example`). Không truyền = **bản trình diễn** |
| Seed nội dung | `dart run tool/seed_content.dart [--dry-run] [--allow-unverified] [--prune]` — từ chối toạ độ `verified: false` |
| iOS | Chỉ kiểm biên dịch trên CI macOS: `gh workflow run "iOS build"` |

## Kiến trúc tổng thể

**Tầng nền** (`visit_state`, dùng chung, là nguồn sự thật) tách khỏi **tầng lăng kính** (cách hiển thị, chọn được, đổi được). Đổi lăng kính không đổi trạng thái mở khóa.

`app/lib/`:

- `features/<tên>/{domain,data,application,presentation}` — `checkpoint`, `unlock`, `fog`, `collection`, `quest`, `itinerary`, `story`. `tool/check_architecture.dart` (không có lối thoát) cấm: feature import chéo nhau, `unlock` phụ thuộc feature khác, `domain` dính package ngoài hay tầng ngoài, `presentation` gọi thẳng `data`, `design/` dính `features/`. Mọi feature được phụ thuộc `unlock`.
- `app/` — **tầng ghép**, nơi duy nhất được biết nhiều feature cùng lúc. `app/lenses/lens_providers.dart` nối nội dung (`checkpointsProvider`) với `visit_state` để sinh dữ liệu cho từng lăng kính (lỗ sương, tem, nhiệm vụ, lộ trình) và truyền xuống dưới dạng giá trị thuần hoặc hàm (vd. `landmarkLookupProvider`). Feature cần thứ của feature khác thì nhận qua tham số, không import.
- `core/` — database drift (`AppDatabase`, migration theo `schemaVersion`), config build-time, `MapProjection` (Web Mercator bằng Dart).
- `design/` — tokens (nguồn duy nhất của màu/bo góc/chữ/thời lượng; `check_design_tokens` chặn giá trị viết cứng ở nơi khác, lối thoát `// design-token-ignore: <lý do>`), widget sticker, style bản đồ.

Những điều phải đọc nhiều file mới thấy:

- **Mở khoá**: `CheckInController` gửi yêu cầu tới `checkInServiceProvider`. Có Supabase → edge function `supabase/functions/check-in` đo khoảng cách ở server; không có → `StandInCheckInService` (tự đo, cùng công thức). Chỉ khi được *grant* mới ghi `visit_state`. Khoảnh khắc mở khoá 3 giây nghe theo kết quả này, không nghe nút bấm.
- **Bản đồ**: MapLibre chỉ vẽ nền (style sinh từ `design/map/map_style.dart`). Marker, sương, người chơi đều là **overlay Flutter** tự chiếu toạ độ bằng `MapProjection` và nghe `controller` (cần `trackCameraPosition: true`). Overlay đều `IgnorePointer`; chạm marker được suy ra từ toạ độ chạm trên bản đồ (`CheckpointMarkerOverlay.checkpointAt`). Zoom < 14.5 vẽ chấm bằng một painter, gần hơn mới vẽ sticker.
- **Sương mù**: lỗ sương = điểm đã mở (từ `visit_state`) + **vệt đã đi** (`features/fog`, bảng `explored_point_rows`). Vệt **không phải** trạng thái mở khoá — chỉ làm sáng bản đồ. Sương vẽ ở ảnh 1/4 độ phân giải rồi phóng lên (lý do hiệu năng ghi trong `fog_overlay.dart`).
- **Bản trình diễn** (không Supabase): tâm bản đồ là người chơi — vuốt là đi, zoom không phải đi; đi *từ ngoài vào* bán kính thì gửi check-in bình thường. Không bao giờ bật khi có server.
- **Nội dung** là JSON trong `content/` (nguồn sự thật, seed vào Supabase) và **bản sao y hệt** ở `app/assets/content/` cho lần chạy đầu offline — có test so hai file. Nhiệm vụ (`quest-routes.json`) có `kind: route` (có thứ tự) hoặc `set` (bộ sưu tập), bộ có thể khai `categories` thay vì liệt kê id. Tiến độ nhiệm vụ luôn suy ra từ `visit_state`.
- **Sticker công trình** (`assets/landmarks/*.png`) là hình tạm sinh từ `content/landmarks/generate.py`; tên trong `LandmarkArt` phải khớp file (có test).

## Bẫy đã gặp

- **Windows: đừng ghi file mã nguồn bằng `Set-Content`/`Out-File`** — thêm BOM, hỏng dấu tiếng Việt, `check_encoding` sẽ chặn.
- **Emulator không vẽ symbol layer** (không nhãn, không icon, không chấm vị trí) và raster bằng CPU — đừng debug nhãn bản đồ hay đo FPS trên đó. Application id là `com.wanderlock.wanderlock`.
- Thêm category checkpoint = sửa enum Dart **và** thêm migration cho enum `checkpoint_category` ở Supabase.
- Trong test, stream provider phải được `container.listen(...)` trước khi đọc `.future`, nếu không nó bị dispose và test treo.

## Ngôn ngữ

- Trao đổi với chủ dự án: **tiếng Việt**
- Mã nguồn, tên biến, commit, PR: **tiếng Anh** — dùng đúng từ điển thuật ngữ ở [docs/12-engineering-guide.md](docs/12-engineering-guide.md). Commit theo Conventional Commits; không commit thẳng vào `main` (được bảo vệ, cần PR + CI xanh)
- Chuỗi hiển thị: tiếng Việt, đặt trong l10n (`app/lib/l10n/app_vi.arb` + `app_en.arb`)
- Mọi font/chuỗi phải kiểm tra dấu tiếng Việt: `ế ỡ ộ ữ ẫ`

## Trước khi báo xong

Đối chiếu mục **"Definition of Done áp dụng cho mọi task"** ở cuối [docs/11-foundation-plan.md](docs/11-foundation-plan.md).
