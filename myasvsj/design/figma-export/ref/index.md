# Senpai ơi – Mobile App Redesign · reference renders

Rendered without Figma from the scripts that drew the file (`design/spec/*.figma.js`) by `node design/spec-render/render.js` on 2026-11-08 11:12.
Each PNG has a standalone HTML twin (same name) whose CSS mirrors the Figma auto-layout tree (`data-name` attributes = Figma layer names).
PNGs are 1× (device pixel = Figma pixel); screens are 390 px wide, tall screens keep the frame's real height.

## Screens (43/43)

| # | Figma frame name | Section | PNG | Size (px) |
|---|---|---|---|---|
| 01 | 01 · Trang chủ — Khách (home_screen + home_guest_view) | 1 · Trang chủ, Tìm kiếm, Thông báo, Thêm | [01-trang-chu-khach-home-screen-home-guest-view.png](01-trang-chu-khach-home-screen-home-guest-view.png) | 390 × 1836 |
| 02 | 02 · Trang chủ — Thành viên (home_member_view) | 1 · Trang chủ, Tìm kiếm, Thông báo, Thêm | [02-trang-chu-thanh-vien-home-member-view.png](02-trang-chu-thanh-vien-home-member-view.png) | 390 × 2400 |
| 03 | 03 · Tìm kiếm (global_search_screen) | 1 · Trang chủ, Tìm kiếm, Thông báo, Thêm | [03-tim-kiem-global-search-screen.png](03-tim-kiem-global-search-screen.png) | 390 × 844 |
| 04 | 04 · Dành cho bạn (for_you_screen) | 1 · Trang chủ, Tìm kiếm, Thông báo, Thêm | [04-danh-cho-ban-for-you-screen.png](04-danh-cho-ban-for-you-screen.png) | 390 × 844 |
| 05 | 05 · Thông báo (notification_screen) | 1 · Trang chủ, Tìm kiếm, Thông báo, Thêm | [05-thong-bao-notification-screen.png](05-thong-bao-notification-screen.png) | 390 × 844 |
| 06 | 06 · Thêm (more_screen) — thành viên | 1 · Trang chủ, Tìm kiếm, Thông báo, Thêm | [06-them-more-screen-thanh-vien.png](06-them-more-screen-thanh-vien.png) | 390 × 1159 |
| 07 | 07 · Bản đồ — danh sách kết quả (map_screen + map_result_panel) | 2 · Bản đồ & Địa điểm | [07-ban-do-danh-sach-ket-qua-map-screen-map-result-panel.png](07-ban-do-danh-sach-ket-qua-map-screen-map-result-panel.png) | 390 × 844 |
| 08 | 08 · Bản đồ — thẻ địa điểm (place_summary_sheet) | 2 · Bản đồ & Địa điểm | [08-ban-do-the-dia-diem-place-summary-sheet.png](08-ban-do-the-dia-diem-place-summary-sheet.png) | 390 × 844 |
| 09 | 09 · Chi tiết địa điểm (place_detail_screen) | 2 · Bản đồ & Địa điểm | [09-chi-tiet-dia-diem-place-detail-screen.png](09-chi-tiet-dia-diem-place-detail-screen.png) | 390 × 1376 |
| 10 | 10 · Viết review (review_form_screen) | 2 · Bản đồ & Địa điểm | [10-viet-review-review-form-screen.png](10-viet-review-review-form-screen.png) | 390 × 844 |
| 11 | 11 · Review mới (recent_reviews_screen) | 2 · Bản đồ & Địa điểm | [11-review-moi-recent-reviews-screen.png](11-review-moi-recent-reviews-screen.png) | 390 × 844 |
| 12 | 12 · Blog (blog_list_screen) | 3 · Blog | [12-blog-blog-list-screen.png](12-blog-blog-list-screen.png) | 390 × 844 |
| 13 | 13 · Bài viết (blog_detail_screen) | 3 · Blog | [13-bai-viet-blog-detail-screen.png](13-bai-viet-blog-detail-screen.png) | 390 × 1579 |
| 14 | 14 · Viết bài (blog_form_screen) | 3 · Blog | [14-viet-bai-blog-form-screen.png](14-viet-bai-blog-form-screen.png) | 390 × 1138 |
| 15 | 15 · Hỏi-Đáp (question_list_screen) | 4 · Hỏi-Đáp | [15-hoi-dap-question-list-screen.png](15-hoi-dap-question-list-screen.png) | 390 × 844 |
| 16 | 16 · Câu hỏi (question_detail_screen) | 4 · Hỏi-Đáp | [16-cau-hoi-question-detail-screen.png](16-cau-hoi-question-detail-screen.png) | 390 × 1113 |
| 17 | 17 · Đặt câu hỏi (question_form_screen) | 4 · Hỏi-Đáp | [17-dat-cau-hoi-question-form-screen.png](17-dat-cau-hoi-question-form-screen.png) | 390 × 1053 |
| 18 | 18 · Câu hỏi thường gặp (faq_screen) | 4 · Hỏi-Đáp | [18-cau-hoi-thuong-gap-faq-screen.png](18-cau-hoi-thuong-gap-faq-screen.png) | 390 × 844 |
| 19 | 19 · Lễ hội và sự kiện (event_list_screen) | 5 · Sự kiện & Cẩm nang | [19-le-hoi-va-su-kien-event-list-screen.png](19-le-hoi-va-su-kien-event-list-screen.png) | 390 × 844 |
| 20 | 20 · Chi tiết sự kiện (event_detail_screen) | 5 · Sự kiện & Cẩm nang | [20-chi-tiet-su-kien-event-detail-screen.png](20-chi-tiet-su-kien-event-detail-screen.png) | 390 × 1433 |
| 21 | 21 · Viết review sự kiện (event_review_form_screen) | 5 · Sự kiện & Cẩm nang | [21-viet-review-su-kien-event-review-form-screen.png](21-viet-review-su-kien-event-review-form-screen.png) | 390 × 844 |
| 22 | 22 · Cẩm nang (guide_list_screen) | 5 · Sự kiện & Cẩm nang | [22-cam-nang-guide-list-screen.png](22-cam-nang-guide-list-screen.png) | 390 × 844 |
| 23 | 23 · Chi tiết cẩm nang — tab Hướng dẫn chuẩn bị (guide_detail_screen) | 5 · Sự kiện & Cẩm nang | [23-chi-tiet-cam-nang-tab-huong-dan-chuan-bi-guide-detail-screen.png](23-chi-tiet-cam-nang-tab-huong-dan-chuan-bi-guide-detail-screen.png) | 390 × 896 |
| 24 | 24 · Cẩm nang của tôi (my_guides_screen) | 5 · Sự kiện & Cẩm nang | [24-cam-nang-cua-toi-my-guides-screen.png](24-cam-nang-cua-toi-my-guides-screen.png) | 390 × 844 |
| 25 | 25 · Nhật ngữ (phrase_screen) | 6 · Nhật ngữ | [25-nhat-ngu-phrase-screen.png](25-nhat-ngu-phrase-screen.png) | 390 × 844 |
| 26 | 26 · Danh sách mẫu câu (phrase_list_screen) | 6 · Nhật ngữ | [26-danh-sach-mau-cau-phrase-list-screen.png](26-danh-sach-mau-cau-phrase-list-screen.png) | 390 × 844 |
| 27 | 27 · Luyện tập (phrase_practice_screen) | 6 · Nhật ngữ | [27-luyen-tap-phrase-practice-screen.png](27-luyen-tap-phrase-practice-screen.png) | 390 × 844 |
| 28 | 28 · Thẻ ghi nhớ (flashcard_screen) | 6 · Nhật ngữ | [28-the-ghi-nho-flashcard-screen.png](28-the-ghi-nho-flashcard-screen.png) | 390 × 844 |
| 29 | 29 · Đưa cho nhân viên xem (phrase_staff_screen) | 6 · Nhật ngữ | [29-dua-cho-nhan-vien-xem-phrase-staff-screen.png](29-dua-cho-nhan-vien-xem-phrase-staff-screen.png) | 390 × 844 |
| 30 | 30 · Tin nhắn (conversation_list_screen) | 7 · Tin nhắn | [30-tin-nhan-conversation-list-screen.png](30-tin-nhan-conversation-list-screen.png) | 390 × 844 |
| 31 | 31 · Trò chuyện (chat_screen) | 7 · Tin nhắn | [31-tro-chuyen-chat-screen.png](31-tro-chuyen-chat-screen.png) | 390 × 844 |
| 32 | 32 · Đăng nhập (login_screen) | 8 · Tài khoản | [32-dang-nhap-login-screen.png](32-dang-nhap-login-screen.png) | 390 × 844 |
| 33 | 33 · Đăng ký — bước 2 Mã xác thực (register_screen) | 8 · Tài khoản | [33-dang-ky-buoc-2-ma-xac-thuc-register-screen.png](33-dang-ky-buoc-2-ma-xac-thuc-register-screen.png) | 390 × 844 |
| 34 | 34 · Quên mật khẩu — bước 2 (forgot_password_screen) | 8 · Tài khoản | [34-quen-mat-khau-buoc-2-forgot-password-screen.png](34-quen-mat-khau-buoc-2-forgot-password-screen.png) | 390 × 844 |
| 35 | 35 · Tôi (profile_screen) | 8 · Tài khoản | [35-toi-profile-screen.png](35-toi-profile-screen.png) | 390 × 1167 |
| 36 | 36 · Lịch sử điểm (point_history_screen) | 8 · Tài khoản | [36-lich-su-diem-point-history-screen.png](36-lich-su-diem-point-history-screen.png) | 390 × 844 |
| 37 | 37 · Đã lưu (saved_screen) | 8 · Tài khoản | [37-da-luu-saved-screen.png](37-da-luu-saved-screen.png) | 390 × 844 |
| 38 | 38 · Khu vực và giai đoạn (area_stage_screen) | 9 · Cài đặt cá nhân | [38-khu-vuc-va-giai-doan-area-stage-screen.png](38-khu-vuc-va-giai-doan-area-stage-screen.png) | 390 × 946 |
| 39 | 39 · Chủ đề quan tâm (interest_screen) | 9 · Cài đặt cá nhân | [39-chu-de-quan-tam-interest-screen.png](39-chu-de-quan-tam-interest-screen.png) | 390 × 844 |
| 40 | 40 · Xin tag định danh (tag_request_screen) | 9 · Cài đặt cá nhân | [40-xin-tag-dinh-danh-tag-request-screen.png](40-xin-tag-dinh-danh-tag-request-screen.png) | 390 × 893 |
| 41 | 41 · Đổi mật khẩu (change_password_screen) | 9 · Cài đặt cá nhân | [41-doi-mat-khau-change-password-screen.png](41-doi-mat-khau-change-password-screen.png) | 390 × 844 |
| 42 | 42 · Xóa tài khoản (delete_account_screen) | 9 · Cài đặt cá nhân | [42-xoa-tai-khoan-delete-account-screen.png](42-xoa-tai-khoan-delete-account-screen.png) | 390 × 844 |
| 43 | 43 · Điều khoản sử dụng (legal_screen) — nội dung mẫu | 9 · Cài đặt cá nhân | [43-dieu-khoan-su-dung-legal-screen-noi-dung-mau.png](43-dieu-khoan-su-dung-legal-screen-noi-dung-mau.png) | 390 × 844 |

## Design System (page “🎨 Design System”)

| Node | Type | Variants (in canvas order) | PNG | Size (px, incl. canvas margin) |
|---|---|---|---|---|
| StatusBar | COMPONENT_SET | Tone=Light<br>Tone=Dark | [ds-statusbar.png](ds-statusbar.png) | 486 × 216 |
| Button | COMPONENT_SET | Kind=Primary, Size=L<br>Kind=Primary, Size=M<br>Kind=Primary, Size=S<br>Kind=Secondary, Size=L<br>Kind=Secondary, Size=M<br>Kind=Secondary, Size=S<br>Kind=Soft, Size=L<br>Kind=Soft, Size=M<br>Kind=Soft, Size=S<br>Kind=Ghost, Size=L<br>Kind=Ghost, Size=M<br>Kind=Ghost, Size=S<br>Kind=Danger, Size=L<br>Kind=Danger, Size=M<br>Kind=Danger, Size=S | [ds-button.png](ds-button.png) | 608 × 436 |
| Chip | COMPONENT_SET | State=Off<br>State=On | [ds-chip.png](ds-chip.png) | 348 × 148 |
| TextField | COMPONENT_SET | State=Default<br>State=Focus<br>State=Error<br>State=Disabled | [ds-textfield.png](ds-textfield.png) | 772 × 232 |
| Cover | COMPONENT_SET | Scene=Fuji<br>Scene=Torii<br>Scene=Sakura<br>Scene=City<br>Scene=Food<br>Scene=Park<br>Scene=Festival<br>Scene=Study | [ds-cover.png](ds-cover.png) | 1448 × 496 |
| Logo | COMPONENT | – | [ds-logo.png](ds-logo.png) | 88 × 104 |
| BottomNav | COMPONENT_SET | Active=Trang chủ<br>Active=Bản đồ<br>Active=Blog<br>Active=Hỏi-Đáp<br>Active=Thêm | [ds-bottomnav.png](ds-bottomnav.png) | 486 × 586 |
| TopActions | COMPONENT_SET | User=Member<br>User=Guest | [ds-topactions.png](ds-topactions.png) | 308 × 208 |
| Foundations | FRAME | – | [ds-foundations.png](ds-foundations.png) | 1500 × 1598 |

## Notes

- All 43 screens rendered.
- Script part `015` of screens-01-08 throws (LIB `abs()` sets `layoutPositioning` on the non-auto-layout map frame) exactly as it would in Figma; part `016` deletes its half-drawn 07 and redraws 07–08.
- Automatic check: every Material Symbols / Material Icons ligature resolved to a glyph (no icon rendered as a word).
- Rows wider than the screen and cut at the edge on purpose (horizontal-scroll chips / cards / tabs): 01, 03, 04, 11, 12, 15, 18, 22, 26, 37.
- Content that overflows its box **because of how the script sizes it** (Figma shows the same; worth fixing in the Flutter build rather than copying):
  - 09: segmented › seg › icon/translate sticks out of "seg" by 4px; segmented › seg › Từ vựng và mẫu câu sticks out of "seg" by 4px
  - 13: placeRow › Col › Saitama · 2-11-3 Miyashi sticks out of "Col" by 23px; placeRow › Col › Phố kẹo · Motomachi, Kaw sticks out of "Col" by 6px
  - 16: Body › ActionBar › action content overflows by 3px each side; ActionBar › action › icon/favorite sticks out of "action" by 9px; ActionBar › action › Thích · 14 sticks out of "action" by 9px; ActionBar › action › icon/flag sticks out of "action" by 5px; ActionBar › action › Báo cáo sticks out of "action" by 5px
  - 25: Body › Row › Button/Luyện tập content overflows by 11px each side; Row › Button/Luyện tập › leading sticks out of "Button/Luyện tập" by 29px; Row › Button/Luyện tập › label sticks out of "Button/Luyện tập" by 29px
  - 29: Row › Button/Nghe phát âm › leading sticks out of "Button/Nghe phát âm" by 2px; Row › Button/Nghe phát âm › label sticks out of "Button/Nghe phát âm" by 2px
- Section names come from the 09–43 plugin / earlier mock (the call that created the sections is not in `design/spec`).
- Screens 07–08 are the versions from script part `016` (it replaces the earlier `015` drawing), and the plugin's `polishHome` tweaks (equal-height feature tiles and wrapping footer on 01, `*_border` icon names in sections 1–2) are applied, as in the final file.
- Fonts: Be Vietnam Pro, Bricolage Grotesque, Zen Maru Gothic (assets/fonts), Material Symbols Rounded (pub cache copy) and Material Icons Round (google/material-design-icons) in `design/spec-render/fonts/`. Japanese glyphs missing from Be Vietnam Pro fall back to the system font, as Figma also substitutes them.
- Layout is computed by Chrome flexbox mimicking Figma auto-layout (HUG = max-content, FILL = flex 1 1 0 / stretch, FIXED = px); tiny sub-pixel differences from Figma's own text metrics are possible.
