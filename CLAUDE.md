# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Wanderlock — hướng dẫn cho agent

App bản đồ tham quan được game hoá: mỗi địa điểm là một checkpoint bị khóa, phải **thực sự đến nơi** để mở khóa — và một lần đến mở khóa cho **mọi** chế độ chơi.

Pilot: TP.HCM — **272 địa điểm**, tất cả đã seed lên máy chủ. 12 địa danh gốc đã soi toạ độ bằng mắt; 260 điểm còn lại lấy tâm đa giác OpenStreetMap và được chủ dự án chấp nhận ngày 2026-09-29 mà không soi từng cái. Cả **năm lăng kính đã chạy**; 46 chương truyện và 28 ảnh thật đã đóng gói trong app.

**Trạng thái nguồn đúng là `git log` của `main`, không phải [CHECKPOINT.md](CHECKPOINT.md)** — file đó viết tay và đã cũ. [docs/11-foundation-plan.md](docs/11-foundation-plan.md) vẫn đúng về các mục Definition of Done.

Máy chủ chạy bằng docker cục bộ (`npx supabase start`, thêm `npx supabase functions serve` cho hàm check-in). Chưa có dự án trên mạng — chủ dự án chốt 2026-09-29 là chưa cần.

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
| Đụng toạ độ, ảnh, hay chương truyện | README trong `tool/coord_verify/`, `tool/photo_picker/`, `tool/story_candidates/` |

## Quy tắc bất khả xâm phạm

1. **Một tầng mở khóa duy nhất.** Mọi lăng kính đọc chung `visit_state`. Chỉ feature `unlock` được ghi vào đó. Không lăng kính nào lưu trạng thái mở khóa riêng.
2. **Không tin client.** Check-in xác thực ở server. Client chỉ gửi yêu cầu.
3. **Không viết cứng giá trị thiết kế.** Màu, bo góc, cỡ chữ, thời lượng animation đều lấy từ `design/tokens/`.
4. **Không mở rộng ngoài scope v1** (5 lăng kính: Fog · Story · Quest · Sưu tầm · Tùy chỉnh hành trình). Xã hội đã hoãn sang v1.5 — đừng thêm vào. Chủ dự án đổi scope thì ghi quyết định vào `docs/08-scope.md` trước.
   - **Thanh chuyển lăng kính có đúng 3 nút** (Sương mù · Sưu tầm · Hành trình), theo mục 5.2 và 5.4 của scope. Story **không** phải nút thứ tư: nó là màn hình toàn màn mở ra từ một điểm đã mở khoá. Quest và Lộ trình nằm chung sau nút Hành trình.
   - **Lọc, sắp xếp, ẩn hiện chỉ là chuyện hiển thị.** Bộ lọc bản đồ (`app/lenses/map_filter.dart`) đổi cái được vẽ và không bao giờ đổi cái đã mở khoá — có test canh cả ba mặt (visit, sương, tem).
5. **Ưu tiên thư viện có sẵn** thay vì tự build. Ngoại lệ tự viết: Fog of War và tầng mở khoá.
6. **Dùng Context7 để lấy tài liệu thư viện** đúng phiên bản — không code theo trí nhớ về API.

## Lệnh thường dùng

Flutter ghim ở `app/.fvmrc` (3.44.8), chạy qua `fvm`. Trên máy dev này PATH của agent có thể cũ — gọi thẳng `C:\Users\nhata\fvm\versions\3.44.8\bin\flutter.bat` / `dart.bat` nếu `fvm` không có.

> **Nếu mọi lệnh Flutter báo `Unable to determine engine version`** thì không phải SDK hỏng: git từ chối đọc thư mục SDK vì nó thuộc nhóm quản trị. Một dòng là xong — nhưng nó sửa cấu hình chung của máy, nên hỏi chủ dự án trước:
>
> ```bash
> git config --global --add safe.directory C:/Users/nhata/fvm/versions/3.44.8
> ```

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
| Build APK | `cd app && fvm flutter build apk --release` → `app/build/app/outputs/flutter-apk/app-release.apk`. Không có `app/android/key.properties` thì ký bằng khoá gỡ lỗi và Gradle cảnh báo — xem mục "Ký bản phát hành" trong README |
| Nối Supabase | `--dart-define=SUPABASE_URL=… --dart-define=SUPABASE_PUBLISHABLE_KEY=…` (xem `.env.example`). Không truyền = **bản trình diễn** |
| Seed nội dung | `dart run tool/seed_content.dart [--dry-run] [--allow-unverified] [--prune]` — từ chối toạ độ `verified: false` |
| Máy chủ cục bộ | `npx supabase start` rồi `npx supabase functions serve` — **thiếu lệnh thứ hai là không mở khoá được** |
| iOS | Chỉ kiểm biên dịch trên CI macOS (bản giả lập, không ký): `gh workflow run "iOS build"` |

### Công cụ nội dung

Nằm trong `tool/`, chạy từ gốc kho mã, đều cần mạng. Kết quả sinh ra bị gitignore — chạy lại thay vì tin một bản đã commit.

| Việc | Lệnh |
|------|------|
| Dò lại toạ độ theo OpenStreetMap | `dart run tool/coord_verify/recheck_osm.dart` |
| Dựng trang soi toạ độ (ảnh vệ tinh + ghim Google) | `dart run tool/coord_verify/build_verify_page.dart` |
| Tìm ứng viên ảnh trên Commons theo toạ độ | `dart run tool/photo_picker/find_commons_photos.dart` |
| Tải ảnh đã chọn về | `dart run tool/photo_picker/fetch_photos.dart` — mặc định chỉ tải những gì có trong `chosen.json`; `--all` mới tải hết |
| Dựng trang chọn ảnh | `dart run tool/photo_picker/build_picker_page.dart` |
| Xem nơi nào nên có chương truyện | `dart run tool/story_candidates/find_wikipedia_articles.dart` |

`verify.html` và `picker.html` tự chứa — mở bằng **trình duyệt thật**. Khung xem trong Claude Code không tải ảnh ngoài, nên đừng dùng nó để duyệt ảnh.

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
  **Nghiêng và xoay bản đồ bị tắt, và không bật lại được nếu chưa viết lại bốn lớp phủ**: `MapProjection` là Web Mercator nhìn thẳng từ trên xuống, và sương, marker, chấm người chơi đều định vị bằng nó. Nghiêng là hỏng cả bốn — trong đó có thứ duy nhất của riêng sản phẩm này.
- **Sương mù**: lỗ sương = điểm đã mở (từ `visit_state`) + **vệt đã đi** (`features/fog`, bảng `explored_point_rows`). Vệt **không phải** trạng thái mở khoá — chỉ làm sáng bản đồ. Sương vẽ ở ảnh 1/4 độ phân giải rồi phóng lên (lý do hiệu năng ghi trong `fog_overlay.dart`).
- **Bản trình diễn** (không Supabase): tâm bản đồ là người chơi — vuốt là đi, zoom không phải đi; đi *từ ngoài vào* bán kính thì gửi check-in bình thường. Không bao giờ bật khi có server.
- **Mở khoá cần mạng, đó là thiết kế.** Không có hàng đợi chờ đồng bộ và sẽ không thêm: chỉ máy chủ mới có quyền nói ai đã đến đâu. Mất mạng thì app nói thẳng là chưa mở được, không ghi gì vào `visit_state`.
- **Chống gian lận hoãn sang sau v1.** Máy chủ vẫn đo khoảng cách và vẫn từ chối request dựng tay, nhưng một vị trí bị làm giả trên máy người chơi thì chưa chặn được. `requiresQrFallback` còn trong schema nhưng chưa nơi nào bật.
- **Nội dung** là JSON trong `content/` (nguồn sự thật, seed vào Supabase) và **bản sao y hệt** ở `app/assets/content/` cho lần chạy đầu offline — có test so hai file. Nhiệm vụ (`quest-routes.json`) có `kind: route` (có thứ tự) hoặc `set` (bộ sưu tập), bộ có thể khai `categories` thay vì liệt kê id. Tiến độ nhiệm vụ luôn suy ra từ `visit_state`.
- **Truyện**: mỗi chương là **một file riêng** trong `content/stories/`, và danh sách chương không được ghi ở đâu cả — `StoryChapterBundledSource` tự dò từ `AssetManifest` lúc chạy, bỏ qua file bắt đầu bằng `_`. Chương chỉ mở được khi `visit_state` nói đã đến nơi, và luật đó nằm ở thẻ chi tiết chứ không nằm trong feature `story` (feature đó không đọc `visit_state`). Chương có ảnh bìa **bắt buộc** khai `coverCredit` — CC BY và CC BY-SA đòi nêu tên tác giả ở nơi hiện ảnh, và có test từ chối chương thiếu nó.
- **Ảnh thật** nằm ở `content/images/places/`, bản sao đóng gói ở `app/assets/photos/places/`. Ảnh nào cũng phải có một dòng trong `content/image-licenses.md` mới được dùng. Lựa chọn ghi ở `tool/photo_picker/chosen.json`.
- **Sticker công trình** (`assets/landmarks/*.png`) là hình tạm sinh từ `content/landmarks/generate.py`; tên trong `LandmarkArt` phải khớp file (có test).

## Bẫy đã gặp

- **Windows: đừng ghi file mã nguồn bằng `Set-Content`/`Out-File`** — thêm BOM, hỏng dấu tiếng Việt, `check_encoding` sẽ chặn.
- **Emulator không vẽ symbol layer** (không nhãn, không icon, không chấm vị trí) và raster bằng CPU — đừng debug nhãn bản đồ hay đo FPS trên đó. Application id là `com.wanderlock.wanderlock`.
- Thêm category checkpoint = sửa enum Dart **và** thêm migration cho enum `checkpoint_category` ở Supabase.
- Trong test, stream provider phải được `container.listen(...)` trước khi đọc `.future`, nếu không nó bị dispose và test treo.
- **`// design-token-ignore:` phải nằm một mình trên dòng ngay trên** dòng vi phạm. Viết chú thích hai dòng rồi để marker ở dòng trên cùng là cổng không thấy.
- **Máy không chọn được ảnh.** Xếp hạng ứng viên theo tên tệp sai 50–60%: nó từng chọn ảnh bên trong chợ Bến Thành, bảo tàng quân sự ở *Hà Nội* cho bảo tàng chiến tranh Sài Gòn, một con thằn lằn cho Thảo Cầm Viên. **Mở từng ảnh ra nhìn** trước khi ghi vào sổ giấy phép.
- **Tra theo tên là bẫy, tra theo toạ độ cũng là bẫy — phải hai chiều.** Theo tên: "Landmark 81" ra một toà tháp ở Yokohama. Theo toạ độ: "Bến Nhà Rồng" ra bài *Rạch Bến Nghé*, con kênh nó đứng bên. Cách dùng được: hỏi theo tên rồi **loại những kết quả có toạ độ ở nơi khác**.
- **Phiếu xếp chồng: sau khi gộp phiếu cha, GitHub không tự trỏ phiếu con về đâu cả.** Gộp lúc đó là nội dung chui vào một nhánh không ai gộp lại nữa, mà vẫn báo thành công. Luôn `gh pr edit <n> --base <nhánh đúng>` rồi mới gộp. Chuyện này đã xảy ra hai lần.

## Ngôn ngữ

- Trao đổi với chủ dự án: **tiếng Việt**
- Mã nguồn, tên biến, commit, PR: **tiếng Anh** — dùng đúng từ điển thuật ngữ ở [docs/12-engineering-guide.md](docs/12-engineering-guide.md). Commit theo Conventional Commits; không commit thẳng vào `main` (được bảo vệ, cần PR + CI xanh)
- Chuỗi hiển thị: tiếng Việt, đặt trong l10n (`app/lib/l10n/app_vi.arb` + `app_en.arb`)
- Mọi font/chuỗi phải kiểm tra dấu tiếng Việt: `ế ỡ ộ ữ ẫ`

## Trước khi báo xong

Đối chiếu mục **"Definition of Done áp dụng cho mọi task"** ở cuối [docs/11-foundation-plan.md](docs/11-foundation-plan.md).
