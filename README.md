# Wanderlock

[![CI](https://github.com/ZzinzZ/Wanderlock/actions/workflows/ci.yml/badge.svg)](https://github.com/ZzinzZ/Wanderlock/actions/workflows/ci.yml)

> Codename — tên chính thức chưa chốt. `wanderlock` là **định danh kỹ thuật**
> (tên package, bundle id) và được giữ ổn định kể cả khi tên thương hiệu đổi.
> Tên hiển thị lấy từ l10n nên đổi lúc nào cũng được.

App bản đồ tham quan được game hoá: mỗi địa điểm là một checkpoint bị khoá,
phải **thực sự đến nơi** để mở khoá — và một lần đến mở khoá cho **mọi** chế độ chơi.

Pilot: **272 địa điểm rải khắp TP.HCM**, tất cả đã seed lên máy chủ. 12 địa
danh gốc đã soi toạ độ bằng mắt; 260 điểm còn lại lấy tâm đa giác OpenStreetMap
và được chấp nhận mà không soi từng cái.

Cả năm lăng kính đã chạy: Sương mù, Sưu tầm, Nhiệm vụ, Lộ trình, và Truyện
(46 chương, 28 nơi có ảnh thật). Không có máy chủ thì app chạy ở **bản trình
diễn**: kéo bản đồ thay cho đi bộ.

**Mở khoá cần mạng.** Chỉ máy chủ mới có quyền nói ai đã đến đâu, nên không có
hàng đợi chờ đồng bộ — mất mạng thì app nói thẳng là chưa mở được.

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

> Nếu mọi lệnh Flutter báo `Unable to determine engine version`: không phải SDK
> hỏng, mà git từ chối đọc thư mục SDK vì khác chủ sở hữu. Đánh dấu nó tin được:
>
> ```bash
> git config --global --add safe.directory <đường-dẫn-tới-sdk>
> ```

```bash
cp .env.example .env
```

Chuỗi hiển thị sinh từ `lib/l10n/*.arb`, **không commit mã sinh ra**:

```bash
cd app && fvm flutter gen-l10n
```

## Các cổng kiểm tra (chạy đúng như CI)

```bash
cd app && fvm flutter gen-l10n && fvm dart run build_runner build && fvm dart format --output=none --set-exit-if-changed . && fvm flutter analyze --fatal-infos --fatal-warnings && fvm dart run ../tool/check_design_tokens.dart && fvm dart run ../tool/check_architecture.dart && fvm dart run ../tool/check_encoding.dart && fvm flutter test --exclude-tags "golden || live"
```

> `dart format --output=none` chỉ **kiểm**, không ghi. Muốn sửa thật thì chạy
> `fvm dart format lib test` trước rồi mới kiểm.
>
> Test mang tag `golden` hoặc `live` bị loại — `live` cần Supabase thật.

| Cổng | Chặn cái gì |
|------|-------------|
| [check_design_tokens](tool/check_design_tokens.dart) | Màu, bo góc, cỡ chữ, thời lượng animation viết cứng ngoài `design/tokens/`. Có lối thoát `// design-token-ignore: <lý do>` |
| [check_architecture](tool/check_architecture.dart) | Feature import chéo nhau, `unlock` phụ thuộc ngược, `domain` dính package ngoài, `presentation` gọi thẳng `data`, `design` dính `features`. **Không có lối thoát** |
| [check_encoding](tool/check_encoding.dart) | BOM, byte không phải UTF-8, và mojibake. **Không có lối thoát** |

> ⚠️ **Trên Windows, đừng sửa file mã nguồn bằng `Set-Content` hay `Out-File`.**
> Chúng thêm BOM và làm hỏng dấu tiếng Việt — đúng loại lỗi `check_encoding`
> sinh ra để chặn. Dùng trình soạn thảo hoặc công cụ ghi UTF-8 không BOM.

> Tên job CI là `quality gates` và **không được đổi** — nó là required status
> check trong ruleset bảo vệ `main`. Thêm cổng thì thêm bước, đừng đổi tên job.

## Nền tảng

| | Trạng thái |
|---|---|
| Android | Phát triển và chạy trên máy thật |
| iOS | **Chỉ kiểm tra biên dịch** trên CI runner macOS, bản giả lập, không ký. Chạy trên máy iOS thật là **nợ kỹ thuật** phải trả trước bản thử nghiệm — xem [docs/11-foundation-plan.md](docs/11-foundation-plan.md) |

Job [`iOS build`](.github/workflows/ios-build.yml) không chạy ở mỗi PR vì
runner macOS tính phí gấp 10 lần trên repo private. Nó chạy khi `main` đổi,
và chạy tay được:

```bash
gh workflow run "iOS build"
```

## Ký bản phát hành

Bản `flutter build apk --release` mặc định ký bằng **khoá gỡ lỗi** — chạy được
trên máy, nhưng Play từ chối. Muốn ký thật thì tạo kho khoá một lần:

```bash
keytool -genkey -v -keystore wanderlock-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias wanderlock
```

Rồi chép `app/android/key.properties.example` thành `app/android/key.properties`
và điền mật khẩu vào. Cả hai file `.jks` và `key.properties` đều đã nằm trong
`.gitignore`.

> ⚠️ **Mất kho khoá là mất quyền cập nhật app.** Google Play nhận diện bản cập
> nhật bằng chữ ký; không có khoá cũ thì không đẩy bản mới lên được, chỉ còn
> cách đăng app mới và bỏ lại toàn bộ người dùng đang có. Sao lưu ở nơi khác
> máy này, và mật khẩu thì cất ở trình quản lý mật khẩu.

Không có `key.properties` thì bản release vẫn build, nhưng Gradle in cảnh báo
rằng nó ký bằng khoá gỡ lỗi và không phát hành được.

---

## Cấu trúc

| Thư mục | Nội dung |
|---------|----------|
| `app/` | Ứng dụng Flutter |
| `content/` | Địa điểm, nhiệm vụ, chương truyện, ảnh thật — và sổ bản quyền ảnh |
| `supabase/` | Migration + edge function xác thực check-in |
| `docs/` | Tài liệu nền tảng (tiếng Việt) |
| `tool/` | Cổng kiểm tra của CI, và các công cụ nội dung (soi toạ độ, chọn ảnh) |

## Tài liệu

Bắt đầu từ [docs/00-overview.md](docs/00-overview.md). Trước khi viết mã, đọc
[docs/12-engineering-guide.md](docs/12-engineering-guide.md) và
[CLAUDE.md](CLAUDE.md).

Definition of Done của từng phase: [docs/11-foundation-plan.md](docs/11-foundation-plan.md).

Còn *đang ở đâu* thì đọc `git log` của `main` — [CHECKPOINT.md](CHECKPOINT.md)
viết tay nên hay tụt lại phía sau.

## Quy ước

- Trao đổi: tiếng Việt · Mã nguồn, commit: tiếng Anh
- Commit theo Conventional Commits — `feat(unlock): verify check-in server-side`
- Nhánh `feat/…`, `fix/…`, `chore/…`. Không commit thẳng vào `main`.
