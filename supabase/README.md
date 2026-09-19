# Supabase

Postgres + PostGIS + Auth + Storage. Dựng ở phase F2, dùng thật ở F4.

```
supabase/
├─ migrations/   # schema — chạy lại từ đầu trên DB rỗng phải thành công
└─ functions/    # edge function xác thực check-in phía server
```

## Hai luật không được vi phạm

1. **Bật RLS cho mọi bảng có `user_id`.** DoD của F2 yêu cầu chứng minh bằng
   ảnh chụp: đọc `visit_state` của người dùng khác phải **bị từ chối**.
2. **Check-in xác thực ở server.** Client chỉ gửi yêu cầu, không tự quyết là đã
   đến nơi. DoD của F4: gửi thẳng request check-in giả bằng công cụ HTTP →
   server phải từ chối.

Mọi thao tác ghi phải **an toàn khi lặp lại** — mở khoá cùng một điểm hai lần
chỉ được ghi nhận một lần.

Schema phác thảo: mục 3 của [../docs/06-tech-stack.md](../docs/06-tech-stack.md).

## Edge function `check-in`

`POST /functions/v1/check-in`, cần header `Authorization: Bearer <JWT người dùng>`.

```json
{ "checkpointId": "ben-thanh-market", "lat": 10.7725509, "lon": 106.697868 }
```

| Kết quả | HTTP | Thân phản hồi |
|---------|------|---------------|
| Trong bán kính | 200 | `outcome: granted`, kèm `visit` và `distanceMeters` |
| Ngoài bán kính | 403 | `error: too_far`, kèm `distanceMeters` + `radiusMeters` |
| Không có checkpoint đó | 404 | `error: unknown_checkpoint` |
| Thiếu / sai phiên đăng nhập | 401 | `error: missing_authorization` \| `invalid_session` |
| Toạ độ hỏng, thiếu id, `method` lạ | 400 | `error: invalid_coordinates` \| … |

**`userId` không nằm trong thân request.** Nó lấy từ JWT đã xác thực chữ ký —
một trường trong body sẽ cho phép mở khoá hộ bản đồ của người khác.

### Vì sao luật khoảng cách nằm trong SQL

Hàm `public.record_check_in` giữ phép đo và phép ghi trong **một giao dịch**, và
chỉ `service_role` có quyền `EXECUTE`. Client có phiên đăng nhập hợp lệ vẫn
**không** gọi thẳng được — đã kiểm chứng: vai `authenticated` và `anon` đều nhận
`permission denied for function`. Cửa duy nhất là edge function.

Nếu để phép đo trong TypeScript thì edge function sẽ tính ra khoảng cách rồi
bảo bảng tin mình — cùng một hình dạng với việc tin client, chỉ lùi vào trong
một lớp.

### Cái nó KHÔNG chứng minh

Nó chứng minh **toạ độ được gửi lên** nằm trong bán kính, đo ở server. Nó
**không** chứng minh toạ độ đó là thật — một bản định vị bịa vẫn là một bản
định vị. Phát hiện bịa là việc riêng (cờ mock-location, kiểm tra tốc độ di
chuyển) và cố tình không nằm trong hàm hình học này. Tách hai thứ ra là cách
để không cái nào bị nhầm thành cái kia.

`qr` và `quiz` có trong enum nhưng edge function **từ chối** chúng: chưa có gì
phát hành hay kiểm tra mã QR, nên nhận vào là mở khoá không có kiểm chứng phía
sau — tệ hơn là chưa có.

### Chạy cục bộ

Edge runtime chỉ gắn thư mục `functions/` **lúc `supabase start`**. Thêm
function mới rồi mà gọi ra 502 thì không phải lỗi mã — chạy lại
`supabase stop && supabase start`.
