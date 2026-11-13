import 'package:flutter/material.dart';

import 'package:myasvsj/com.myasvsj.screen/blog_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/chat_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/event_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/event_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/event_review_form_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/guide_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/guide_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/map_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/notification_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/phrase_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/place_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/profile_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/question_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/question_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/saved_screen.dart';

/// Màn hình ứng với một đường dẫn web sạch của server (trường `link` của thông báo, kết quả tìm kiếm…).
///
/// | Đường dẫn                          | Màn hình                                        |
/// |------------------------------------|-------------------------------------------------|
/// | /blog, /blog/{id}                  | BlogListScreen, BlogDetailScreen                |
/// | /qa, /qa?q=…&tab=faq, /qa/{id}     | QuestionListScreen, QuestionDetailScreen        |
/// | /events, /events/{id}, …/review    | EventListScreen, EventDetailScreen, form review |
/// | /guides?category=, /guides/{id}    | GuideListScreen, GuideDetailScreen (?tab=preparation mở checklist) |
/// | /map, /map?place={id}              | MapScreen, PlaceDetailScreen                    |
/// | /phrases?topic=&category=&q=       | PhraseScreen                                    |
/// | /messages/{id}                     | ChatScreen                                      |
/// | /profile, /saved, /notifications   | Tôi, Đã lưu, Thông báo                          |
///
/// Trả về null khi app chưa có màn hình cho đường dẫn đó.
Widget? screenForLink(String? link) {
  if (link == null || link.isEmpty) {
    return null;
  }
  final uri = Uri.tryParse(link);
  if (uri == null) {
    return null;
  }
  final parts = uri.pathSegments.where((p) => p.isNotEmpty).toList();
  final id = parts.length >= 2 ? int.tryParse(parts[1]) : null;
  final first = parts.isEmpty ? '' : parts.first;
  final query = uri.queryParameters;
  switch (first) {
    case 'blog' when id != null:
      return BlogDetailScreen(blogId: id);
    case 'blog':
      return const BlogListScreen();
    case 'qa' when id != null:
      return QuestionDetailScreen(questionId: id);
    case 'qa':
      return QuestionListScreen(initialTab: query['tab'] == 'faq' ? 1 : 0, initialQuery: query['q'] ?? '');
    case 'events' when id != null && parts.length >= 3 && parts[2] == 'review':
      return EventReviewFormScreen(eventId: id);
    case 'events' when id != null:
      return EventDetailScreen(eventId: id);
    case 'events':
      return const EventListScreen();
    case 'guides' when id != null:
      return GuideDetailScreen(guideId: id, openChecklist: query['tab'] == 'preparation');
    case 'guides':
      return GuideListScreen(stage: query['category']);
    case 'messages' when id != null:
      return ChatScreen(conversationId: id);
    case 'map':
      final place = int.tryParse(query['place'] ?? '');
      return place == null ? const MapScreen() : PlaceDetailScreen(placeId: place);
    case 'phrases':
      return PhraseScreen(topicId: query['topic'], categoryId: query['category'], initialQuery: query['q'] ?? '');
    case 'profile':
      return const ProfileScreen();
    case 'saved':
      return const SavedScreen();
    case 'notifications':
      return const NotificationScreen();
  }
  return null;
}

/// Mở màn hình ứng với [link]; trả về false khi app chưa có màn hình cho đường dẫn đó.
Future<bool> openLink(BuildContext context, String? link) async {
  final screen = screenForLink(link);
  if (screen == null) {
    return false;
  }
  await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen));
  return true;
}
