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
