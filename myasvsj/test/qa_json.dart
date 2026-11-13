// JSON mẫu của Hỏi-Đáp và Câu hỏi thường gặp, CHÉP TỪ SERVER THẬT (curl http://localhost:8080, 08/11/2026):
// phần `data` của ApiResponse. Dùng cho test DAO (FakeServer) để bắt lệch tên trường giữa app và web.
import 'dart:convert';

Map<String, dynamic> _map(String json) => jsonDecode(json) as Map<String, dynamic>;
List<dynamic> _list(String json) => jsonDecode(json) as List<dynamic>;

/// GET /api/questions?size=3 (mentor@gmail.com đã đăng nhập, câu 8 là câu thử có ảnh).
Map<String, dynamic> questionListJson() => _map(r'''
{"items":[{"id":8,"status":"PUBLISHED","pinned":false,"solved":false,"unanswered":true,"title":"[TEST QA agent] Hỏi thử về gia hạn visa du học cần giấy tờ gì","excerpt":"Câu hỏi thử của agent qa, sẽ xóa ngay.","author":{"id":6,"displayName":"Lan Anh","avatarUrl":null,"tags":[{"name":"Mentor","color":"#C2456E"}]},"topics":[{"id":4,"name":"Visa và cư trú"},{"id":14,"name":"Khác"}],"places":[],"likeCount":0,"answerCount":0,"createdAt":"2026-11-07T18:52:32Z"},{"id":6,"status":"PUBLISHED","pinned":false,"solved":false,"unanswered":true,"title":"Mua SIM data giá rẻ ở đâu gần Nippori ạ?","excerpt":"Em mới sang được 3 ngày, cần SIM data rẻ để dùng bản đồ. Mọi người đang dùng nhà mạng nào và mua ở đâu ạ?","author":{"id":2,"displayName":"Trần Minh","avatarUrl":null,"tags":[]},"topics":[{"id":11,"name":"Mua sắm"},{"id":12,"name":"Ngân hàng và tiền"}],"places":[],"likeCount":3,"answerCount":0,"createdAt":"2026-11-06T18:36:45Z"}],"page":0,"size":3,"totalItems":2,"totalPages":1,"filtered":false}
''');

/// GET /api/questions/overview. `topAnswerers` của server lúc chép đang rỗng; phần tử ở đây ghép theo
/// QaDtos.Answerer(author, answerCount, bestCount) với author thật của user@gmail.com.
Map<String, dynamic> overviewJson() => _map(r'''
{"topics":[{"id":1,"name":"Kinh nghiệm"},{"id":2,"name":"Cảnh báo lừa đảo"},{"id":3,"name":"Thủ tục giấy tờ"},{"id":4,"name":"Visa và cư trú"},{"id":5,"name":"Nhà ở"},{"id":6,"name":"Việc làm thêm"},{"id":7,"name":"Ăn uống"},{"id":8,"name":"Đi lại"},{"id":9,"name":"Học tiếng Nhật"},{"id":10,"name":"Y tế"},{"id":11,"name":"Mua sắm"},{"id":12,"name":"Ngân hàng và tiền"},{"id":13,"name":"Sau khi về nước"},{"id":14,"name":"Khác"}],"stats":{"total":1,"unanswered":1,"solved":0},"popularTopics":[{"id":11,"name":"Mua sắm","postCount":1},{"id":12,"name":"Ngân hàng và tiền","postCount":1}],"topAnswerers":[{"author":{"id":2,"displayName":"Trần Minh","avatarUrl":null,"tags":[]},"answerCount":4,"bestCount":1}],"topAnswerersDays":30}
''');

/// PUT /api/questions/8/best-answer (mentor là người hỏi): câu trả lời 3 của user@gmail.com là câu hay nhất,
/// có phản hồi lồng 5 của mentor.
Map<String, dynamic> questionDetailJson() => _map(r'''
{"id":8,"type":"QA","status":"PUBLISHED","pinned":false,"edited":false,"title":"[TEST QA agent] Hỏi thử về gia hạn visa du học cần giấy tờ gì","content":"Câu hỏi thử của agent qa, sẽ xóa ngay.","author":{"id":6,"displayName":"Lan Anh","avatarUrl":null,"tags":[{"name":"Mentor","color":"#C2456E"}],"rankName":"Senpai tin cậy"},"topics":[{"id":4,"name":"Visa và cư trú"},{"id":14,"name":"Khác"}],"places":[],"media":[{"id":19,"type":"IMAGE","url":"/media/blog/2026/11/e79d08d7-9029-4c43-94ea-b7a039e76bd0.jpg","mimeType":"image/jpeg","width":772,"height":721}],"likeCount":0,"commentCount":2,"bestCommentId":3,"createdAt":"2026-11-07T18:52:32Z","viewer":{"signedIn":true,"author":true,"canInteract":true,"liked":false,"saved":false},"comments":[{"id":3,"parentId":null,"author":{"id":2,"displayName":"Trần Minh","avatarUrl":null,"tags":[],"rankName":"Người mới"},"content":"Câu trả lời thử của agent qa: cần hộ chiếu, thẻ cư trú, giấy xác nhận đang học.","edited":false,"removed":false,"best":true,"mine":false,"liked":true,"likeCount":1,"createdAt":"2026-11-07T18:52:52Z","replies":[{"id":5,"parentId":3,"author":{"id":6,"displayName":"Lan Anh","avatarUrl":null,"tags":[{"name":"Mentor","color":"#C2456E"}],"rankName":"Senpai tin cậy"},"content":"Cảm ơn bạn, mình hỏi thêm: có cần giấy xác nhận tài chính không?","edited":false,"removed":false,"best":false,"mine":true,"liked":false,"likeCount":0,"createdAt":"2026-11-07T18:53:01Z","replies":[]}]}],"reportReasons":[{"id":1,"label":"Lừa đảo"},{"id":2,"label":"Sai sự thật"},{"id":3,"label":"Xúc phạm"},{"id":4,"label":"Spam"}]}
''');

/// GET /api/questions/6 của khách.
Map<String, dynamic> guestDetailJson() => _map(r'''
{"id":6,"type":"QA","status":"PUBLISHED","pinned":false,"edited":false,"title":"Mua SIM data giá rẻ ở đâu gần Nippori ạ?","content":"Em mới sang được 3 ngày, cần SIM data rẻ để dùng bản đồ. Mọi người đang dùng nhà mạng nào và mua ở đâu ạ?","author":{"id":2,"displayName":"Trần Minh","avatarUrl":null,"tags":[],"rankName":"Người mới"},"topics":[{"id":11,"name":"Mua sắm"},{"id":12,"name":"Ngân hàng và tiền"}],"places":[],"media":[],"likeCount":3,"commentCount":0,"bestCommentId":null,"createdAt":"2026-11-06T18:36:45Z","viewer":{"signedIn":false,"author":false,"canInteract":false,"liked":false,"saved":false},"comments":[],"reportReasons":[{"id":1,"label":"Lừa đảo"},{"id":2,"label":"Sai sự thật"},{"id":3,"label":"Xúc phạm"},{"id":4,"label":"Spam"}]}
''');

/// GET /api/questions/compose (mentor@gmail.com).
Map<String, dynamic> composeJson() => _map(r'''
{"topics":[{"id":1,"name":"Kinh nghiệm","other":false,"scamWarning":false},{"id":2,"name":"Cảnh báo lừa đảo","other":false,"scamWarning":true},{"id":3,"name":"Thủ tục giấy tờ","other":false,"scamWarning":false},{"id":4,"name":"Visa và cư trú","other":false,"scamWarning":false},{"id":5,"name":"Nhà ở","other":false,"scamWarning":false},{"id":6,"name":"Việc làm thêm","other":false,"scamWarning":false},{"id":7,"name":"Ăn uống","other":false,"scamWarning":false},{"id":8,"name":"Đi lại","other":false,"scamWarning":false},{"id":9,"name":"Học tiếng Nhật","other":false,"scamWarning":false},{"id":10,"name":"Y tế","other":false,"scamWarning":false},{"id":11,"name":"Mua sắm","other":false,"scamWarning":false},{"id":12,"name":"Ngân hàng và tiền","other":false,"scamWarning":false},{"id":13,"name":"Sau khi về nước","other":false,"scamWarning":false},{"id":14,"name":"Khác","other":true,"scamWarning":false}],"limits":{"titleMax":150,"contentMax":5000,"topicsMax":3,"placesMax":5,"imagesMax":5,"imageMaxMb":20,"videosMax":1,"videoMaxSeconds":30,"videoMaxMb":50,"questionContentRequired":false},"quota":{"newAccount":false,"newAccountDays":7,"accountAgeDays":400,"postsUsed":0,"postsLimit":3,"pinsUsed":0,"pinsLimit":2,"videosUsed":0,"videosLimit":1},"canPostLinks":true}
''');

/// GET /api/questions/8/edit (phần `options` giống [composeJson]).
Map<String, dynamic> editJson() => {
  ..._map(r'''
{"id":8,"type":"QA","status":"PUBLISHED","title":"[TEST QA agent] Hỏi thử về gia hạn visa du học cần giấy tờ gì","content":"Câu hỏi thử của agent qa, sẽ xóa ngay.","topicIds":[4,14],"places":[],"media":[{"id":19,"type":"IMAGE","url":"/media/blog/2026/11/e79d08d7-9029-4c43-94ea-b7a039e76bd0.jpg","scanStatus":"PASSED","sortOrder":0}]}
'''),
  'options': composeJson(),
};

/// GET /api/faqs?size=2.
Map<String, dynamic> faqPageJson() => _map(r'''
{"items":[{"id":10,"question":"Nếu bị mất hộ chiếu tại Nhật phải làm gì?","answer":"Bạn nên trình báo mất hộ chiếu với cảnh sát, sau đó liên hệ Đại sứ quán hoặc Tổng Lãnh sự quán Việt Nam tại Nhật để được hướng dẫn xin cấp lại hộ chiếu hoặc giấy tờ đi lại phù hợp.\n\nNên chuẩn bị bản sao hộ chiếu, giấy tờ tùy thân còn lại và giấy xác nhận từ cảnh sát nếu được yêu cầu.","topicCode":"OTHER","topicName":"Khác","published":true,"createdAt":"2026-11-07T18:36:40Z","updatedAt":"2026-11-07T18:36:40Z","resources":[]},{"id":9,"question":"Khi gặp tình huống khẩn cấp tại Nhật cần gọi số nào?","answer":"Tại Nhật Bản:\n- 110: Cảnh sát.\n- 119: Cứu hỏa và cấp cứu.\nKhi gọi, hãy cố gắng cung cấp vị trí, tình huống đang xảy ra và số điện thoại liên hệ. Nếu không nói tốt tiếng Nhật, hãy nhờ người xung quanh hỗ trợ khi có thể.","topicCode":"OTHER","topicName":"Khác","published":true,"createdAt":"2026-11-07T18:36:40Z","updatedAt":"2026-11-07T18:36:40Z","resources":[]}],"total":10,"page":0,"size":2,"totalPages":5}
''');

/// GET /api/faqs?q=xyzkhongco: không có câu nào.
Map<String, dynamic> faqEmptyPageJson() => _map(r'''
{"items":[],"total":0,"page":0,"size":10,"totalPages":0}
''');

/// GET /api/faqs/topics.
List<dynamic> faqTopicsJson() => _list(r'''
[{"code":"PREPARATION","title":"Chuẩn bị trước khi sang Nhật","count":3},{"code":"LIVING","title":"Sinh hoạt và đời sống","count":3},{"code":"STUDY_WORK","title":"Học tập và công việc","count":0},{"code":"PROCEDURES","title":"Thủ tục và giấy tờ","count":2},{"code":"LANGUAGE","title":"Ngôn ngữ và giao tiếp","count":0},{"code":"OTHER","title":"Khác","count":2}]
''');

/// GET /api/faqs/5: có liên kết "Xem thêm" tới cẩm nang 24.
Map<String, dynamic> faqEntryJson() => _map(r'''
{"id":5,"question":"Phân loại và đổ rác tại Nhật như thế nào?","answer":"Rác thường được chia thành các nhóm như rác cháy được (燃えるごみ), rác không cháy được (燃えないごみ), chai PET, lon và rác tái chế.\n\nMỗi địa phương có quy định riêng về loại rác, túi rác và ngày thu gom. Bạn nên xin lịch đổ rác tại cơ quan hành chính hoặc hỏi chủ nhà để thực hiện đúng.","topicCode":"LIVING","topicName":"Sinh hoạt và đời sống","published":true,"createdAt":"2026-11-07T18:36:40Z","updatedAt":"2026-11-07T18:36:40Z","resources":[{"kind":"GUIDE","targetId":24,"url":null,"label":"Xem chi tiết về phân loại rác tại Nhật"}]}
''');

/// GET /api/faqs/related?q=mua SIM data o dau.
List<dynamic> faqRelatedJson() => _list(r'''
[{"id":4,"question":"Làm thế nào để mua SIM điện thoại khi mới sang Nhật?","answer":"Bạn có thể đăng ký SIM tại cửa hàng của nhà mạng hoặc qua website. Thông thường cần giấy tờ xác minh danh tính, địa chỉ cư trú và phương thức thanh toán phù hợp.\n\nNên kiểm tra điện thoại có hỗ trợ băng tần tại Nhật, có bị khóa mạng không, và so sánh phí hằng tháng, dung lượng data trước khi đăng ký.","topicCode":"LIVING","topicName":"Sinh hoạt và đời sống","published":true,"createdAt":"2026-11-07T18:36:40Z","updatedAt":"2026-11-07T18:36:40Z","resources":[]}]
''');
