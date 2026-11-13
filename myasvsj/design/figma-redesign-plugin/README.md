# Plugin vẽ màn hình redesign Senpai ơi

Plugin này vẽ 35 màn hình còn lại (09–43) vào file Figma
[Senpai ơi – Mobile App Redesign](https://www.figma.com/design/vP84Lkpj3KEkKbuAyFudeE).
Nó chạy ngay trong Figma của bạn, không tốn lượt gọi MCP.

## Cách chạy

1. Mở **app Figma desktop**. Plugin đang phát triển chỉ chạy được trên app desktop, không chạy trên trình duyệt.
2. Mở file **Senpai ơi – Mobile App Redesign**.
3. Vào menu **Plugins → Development → Import plugin from manifest…** rồi chọn file `manifest.json` trong thư mục này.
4. Vào **Plugins → Development → Senpai ơi – Vẽ màn hình redesign** để chạy. Mất khoảng 1 phút.
5. Khi xong, Figma hiện thông báo "Xong! Đã vẽ 35 màn hình."

## Plugin làm gì

- Vẽ các màn 09–43 vào đúng nhóm (section) 2–9 trên trang "📱 Màn hình". Màu, chữ và component đều gắn với Design System.
- Xếp lại các nhóm theo chiều dọc, nên màn 02 hết đè lên màn 08.
- Làm đều chiều cao 4 thẻ tính năng và cho dòng chân trang xuống dòng ở màn 01.
- Xoá khung ẩn `__lib` trên trang Design System.

Bạn chạy lại bao nhiêu lần cũng được. Mỗi lần chạy, plugin xoá các màn 09–43 cũ rồi vẽ lại.

## Nếu có lỗi

Plugin không dừng giữa chừng. Màn nào lỗi thì bỏ qua màn đó, và một khung **"⚠️ Báo lỗi plugin"** sẽ hiện ở phía trên trang
"📱 Màn hình". Hãy copy chữ trong khung đó gửi cho Claude để sửa.
