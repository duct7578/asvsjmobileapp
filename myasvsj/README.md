# Senpai ơi – mobile (myasvsj)

App Flutter của web "Senpai ơi" (đồ án PRM393). App không có database riêng và không dùng Firebase:
mọi dữ liệu đi qua REST API của web vào database MySQL của web. Kế hoạch đầy đủ nằm ở báo cáo
"Senpai ơi Mobile – Các giai đoạn phát triển".

## Chạy app

Cần Flutter 3.41 trở lên (đã thử 3.41.9 / Dart 3.11.5 và 3.44.2). Đừng nâng gói lên bản đòi Dart 3.12 (ví dụ
`wakelock_plus` 1.8) khi cả nhóm chưa cùng lên Flutter 3.44, vì `flutter pub get` trên 3.41 sẽ báo "version solving
failed". Đổi qua lại giữa hai bản Flutter thì `meta` và `test_api` trong `pubspec.lock` đổi theo: chuyện bình thường,
Flutter tự ghim hai gói này. Nhưng sau khi đổi bản Flutter trong cùng thư mục, hãy chạy `flutter clean` rồi
`flutter pub get` trước khi build: bộ nhớ đệm `.dart_tool/hooks_runner` do bản kia biên dịch sẽ làm build báo
"Invalid kernel binary format version".

1. Chạy server web (Spring Boot, cổng 8080).
2. Giả lập Android: `flutter run` (app gọi `http://10.0.2.2:8080`).
3. Máy thật cùng mạng Wi-Fi: `flutter run --dart-define=API_BASE_URL=http://<IP LAN của máy chạy server>:8080`.

Bản debug được gọi HTTP thường (`android/app/src/debug/AndroidManifest.xml`). Bản release chỉ gọi được HTTPS.

App chỉ có màn hình cho khách (Guest) và thành viên (User). Tài khoản Moderator / Academic Manager / Admin bị từ chối
khi đăng nhập trên app ("Tài khoản quản lý chỉ dùng trên trang web").

## Kiểm thử

| Loại | Thư mục | Lệnh | Cần gì |
| --- | --- | --- | --- |
| Unit + widget (DAO với server giả, Controller với DAO giả, màn hình) | `test/` | `flutter test` | không cần mạng |
| Live: DAO gọi server web thật | `test/live/` | `flutter test test/live --dart-define=LIVE_API=http://localhost:8080 --concurrency=1` | server web chạy ở máy, profile `local` (tài khoản mẫu mật khẩu `123456`) |
| Đầu-cuối: app thật trên giả lập | `integration_test/` | `flutter test integration_test/app_flow_test.dart -d emulator-5554` | server web + giả lập Android |
| Ảnh màn hình so với thiết kế Figma | `test/design_shots/` | `flutter test test/design_shots --dart-define=SHOTS=true` | không cần mạng; ảnh ra ở `design/flutter-shots/`, ảnh thiết kế ở `design/figma-export/ref/` |

Không có `--dart-define=LIVE_API` thì các test live tự bỏ qua, nên `flutter test` luôn chạy được.
Test live đăng ký tài khoản thử bằng cách đọc mã xác minh trong log của server (server dev không gửi email thật, xem
`test/live/auth_live_test.dart`, đổi đường dẫn log bằng `--dart-define=SERVER_LOG=…`). Nên chạy server cho test với
một database riêng (ví dụ `--spring.datasource.url=jdbc:mysql://localhost:3306/asvsj_mobile?createDatabaseIfNotExist=true…`)
để dữ liệu thử không lẫn vào database dev.

## Giao diện

Giao diện theo bản thiết kế Figma "Senpai ơi – Mobile App Redesign". Màu, kiểu chữ, theme và các khối dựng chung nằm ở
`lib/com.myasvsj.screen/senpai_colors.dart`, `senpai_text.dart`, `senpai_theme.dart`, `senpai_ui.dart`, `senpai_app_bar.dart`;
quy ước khi sửa màn hình ở `design/AGENT_GUIDE.md`. Ảnh thiết kế của 43 màn được vẽ lại từ `design/spec/` bằng
`node design/spec-render/render.js`.

Sau khi chạy test `integration_test`, build bản release bằng `flutter build apk --release` (không thêm `--no-pub`), để Flutter
sinh lại danh sách plugin không có `integration_test`.

## Màn hình theo nhóm

| Nhóm | Màn hình |
| --- | --- |
| Khung | `MainScreen` (Trang chủ · Bản đồ · Blog · Hỏi-Đáp · Thêm), `MoreScreen`, `NotificationHost` |
| Tài khoản | `LoginScreen`, `RegisterScreen`, `ForgotPasswordScreen`, `ChangePasswordScreen`, `DeleteAccountScreen`, `LegalScreen` |
| Tôi | `ProfileScreen`, `PointHistoryScreen`, `AreaStageScreen`, `InterestScreen`, `SavedScreen`, `TagRequestScreen` |
| Trang chủ | `HomeScreen`, `GlobalSearchScreen`, `ForYouScreen`, `RecentReviewsScreen` |
| Blog | `BlogListScreen`, `BlogDetailScreen`, `BlogFormScreen` |
| Hỏi-Đáp | `QuestionListScreen`, `QuestionDetailScreen`, `QuestionFormScreen`, `FaqScreen` |
| Sự kiện, Cẩm nang | `EventListScreen`, `EventDetailScreen`, `EventReviewFormScreen`, `GuideListScreen`, `GuideDetailScreen`, `MyGuidesScreen` |
| Bản đồ | `MapScreen`, `PlaceDetailScreen`, `ReviewFormScreen` |
| Nhật ngữ | `PhraseScreen`, `PhraseListScreen`, `FlashcardScreen`, `PhrasePracticeScreen`, `PhraseStaffScreen` |
| Thông báo, Tin nhắn | `NotificationScreen`, `ConversationListScreen`, `ChatScreen` |

Đường dẫn web sạch (trường `link` của thông báo, `/blog/12`, `/qa/3`, `/map?place=9`…) được đổi sang màn hình ở
`lib/com.myasvsj.screen/link_router.dart`.

## Mô hình MVC

```text
lib/
├── main.dart                  khởi động app, cấp các Controller bằng Provider
├── com.myasvsj.screen/        View: màn hình và widget dùng chung
├── com.myasvsj.controller/    Controller: trạng thái và xử lý sự kiện
└── com.myasvsj.model/         Model: thực thể và lớp truy cập dữ liệu (DAO, ApiClient)
```

Luồng một thao tác: Screen → Controller → DAO → `ApiClient` → REST API của web → MySQL.
Kết quả đi ngược lại: DAO trả về thực thể, Controller gọi `notifyListeners()`, Screen tự vẽ lại.

- **Screen** chỉ vẽ giao diện và chuyển sự kiện bấm cho Controller. Screen không import `dio`, DAO hay `api_client.dart`.
- **Controller** kế thừa `ChangeNotifier`, giữ trạng thái (`isLoading`, `error`, dữ liệu), kiểm tra dữ liệu nhập,
  gọi DAO. Controller chỉ import `package:flutter/foundation.dart`, không import `material.dart`.
- **Model**: thực thể có `fromJson` / `toJson` theo JSON của web; DAO là lớp duy nhất gọi `ApiClient`.
- `main.dart` là nơi duy nhất ngoài Model biết tới DAO và `ApiClient`.
- Import luôn ghi theo tên gói, ví dụ `import 'package:myasvsj/com.myasvsj.model/blog.dart';`.

## Quy tắc đặt tên

Tên lớp viết PascalCase, tên file viết snake_case trùng tên lớp, mỗi file một lớp chính.

| Thành phần | Quy tắc tên | Ví dụ lớp → file |
| --- | --- | --- |
| Màn hình (View) | Thực thể + việc + `Screen` | `BlogListScreen` → `blog_list_screen.dart` |
| Widget dùng chung | Danh từ mô tả, không hậu tố | `BlogCard` → `blog_card.dart` |
| Controller | Thực thể + `Controller` | `BlogController` → `blog_controller.dart` |
| Thực thể (Model) | Danh từ số ít ứng với bảng | `Blog` (bảng `blogs`) → `blog.dart` |
| Truy cập dữ liệu (Model) | Thực thể + `Dao`; hàm `findAll`, `findById`, `create`, `update`, `delete` | `BlogDao` → `blog_dao.dart` |
| Hàm, biến | lowerCamelCase; hàm bắt đầu bằng động từ; thành phần riêng có `_` | `loadBlogs()`, `isLoading`, `_dao` |
| Hằng số | lowerCamelCase | `pageSize` |

Từ viết tắt dài hơn hai chữ viết như một từ (`BlogDao`, `ApiClient`). Tránh trùng lớp có sẵn của Flutter:
`AppNotification` thay cho `Notification`, `GlobalSearchController` thay cho `SearchController`.

## Mẫu CRUD bài viết

| Thao tác | Screen | Controller | DAO | API của web |
| --- | --- | --- | --- | --- |
| Tạo | `BlogFormScreen` (không có id) | `openForm()`, `saveBlog(...)` | `findComposeOptions()`, `create(blog, imagePaths:)` | `GET /api/blogs/compose`, `POST /api/blogs` (multipart: `post` + `images`) |
| Xem danh sách | `BlogListScreen` | `loadBlogs()` | `findAll(...)` → `PageResult<Blog>` | `GET /api/blogs` |
| Xem chi tiết | `BlogDetailScreen` | `loadBlog(id)` | `findById(id)` | `GET /api/blogs/{id}` |
| Sửa | `BlogFormScreen(blogId: id)` | `openForm(blogId: id)`, `saveBlog(...)` | `findForEdit(id)`, `update(blog, imagePaths:)` | `GET /api/blogs/{id}/edit`, `PUT /api/blogs/{id}` (multipart) |
| Xóa | `BlogDetailScreen` | `deleteBlog(id)` | `delete(id)` | `DELETE /api/blogs/{id}` |

Tính năng mới làm theo đúng mẫu này: thực thể và DAO trong Model, Controller, các màn hình trong Screen; test DAO
với server giả (`test/fake_api.dart`), unit test Controller với DAO giả (ví dụ `test/blog_fakes.dart`), widget test
màn hình, và test live với server thật (`test/live/`).
