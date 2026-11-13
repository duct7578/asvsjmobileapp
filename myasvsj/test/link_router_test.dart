// Unit test của link_router: đường dẫn web sạch (trường `link` của thông báo…) → đúng màn hình, đúng tham số.
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.screen/blog_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/chat_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/event_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/event_review_form_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/guide_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/guide_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/link_router.dart';
import 'package:myasvsj/com.myasvsj.screen/map_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/notification_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/phrase_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/place_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/profile_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/question_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/question_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/saved_screen.dart';

void main() {
  test('chi tiết theo id', () {
    expect((screenForLink('/blog/12') as BlogDetailScreen).blogId, 12);
    expect((screenForLink('/qa/3') as QuestionDetailScreen).questionId, 3);
    expect((screenForLink('/events/5') as EventDetailScreen).eventId, 5);
    expect((screenForLink('/messages/4') as ChatScreen).conversationId, 4);
    expect((screenForLink('/map?place=9') as PlaceDetailScreen).placeId, 9);
  });

  test('cẩm nang: tab chuẩn bị mở checklist, danh sách theo giai đoạn', () {
    final plain = screenForLink('/guides/7') as GuideDetailScreen;
    expect(plain.guideId, 7);
    expect(plain.openChecklist, isFalse);
    expect((screenForLink('/guides/7?tab=preparation') as GuideDetailScreen).openChecklist, isTrue);
    expect((screenForLink('/guides?category=ARR') as GuideListScreen).stage, 'ARR');
  });

  test('danh sách và tham số tìm', () {
    expect(screenForLink('/blog'), isA<BlogListScreen>());
    final faq = screenForLink('/qa?tab=faq&q=thuê nhà') as QuestionListScreen;
    expect(faq.initialTab, 1);
    expect(faq.initialQuery, 'thuê nhà');
    expect((screenForLink('/events/2/review') as EventReviewFormScreen).eventId, 2);
    expect(screenForLink('/map'), isA<MapScreen>());
    final phrases = screenForLink('/phrases?topic=konbini') as PhraseScreen;
    expect(phrases.topicId, 'konbini');
  });

  test('trang cá nhân', () {
    expect(screenForLink('/profile'), isA<ProfileScreen>());
    expect(screenForLink('/saved'), isA<SavedScreen>());
    expect(screenForLink('/notifications'), isA<NotificationScreen>());
  });

  test('đường dẫn app chưa có màn hình hoặc rỗng trả về null', () {
    expect(screenForLink(null), isNull);
    expect(screenForLink(''), isNull);
    expect(screenForLink('/scholarships'), isNull);
    expect(screenForLink('/blog/abc/edit'), isA<BlogListScreen>());
    expect(screenForLink('/map?place=abc'), isA<MapScreen>());
  });
}
