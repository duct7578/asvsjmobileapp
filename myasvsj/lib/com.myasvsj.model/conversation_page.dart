import 'package:myasvsj/com.myasvsj.model/chat_counts.dart';
import 'package:myasvsj/com.myasvsj.model/conversation_item.dart';

/// Một trang của danh sách cuộc trò chuyện (30 một trang, tin mới nhất trước), kèm các con số
/// (ConversationList của web: `{items, hasMore, counts}`).
class ConversationPage {
  const ConversationPage({this.items = const [], this.hasMore = false, this.counts = const ChatCounts()});

  final List<ConversationItem> items;
  final bool hasMore;
  final ChatCounts counts;

  factory ConversationPage.fromJson(Map<String, dynamic> json) => ConversationPage(
    items: [
      for (final item in (json['items'] as List?) ?? const []) ConversationItem.fromJson(item as Map<String, dynamic>),
    ],
    hasMore: (json['hasMore'] ?? false) as bool,
    counts: json['counts'] is Map<String, dynamic>
        ? ChatCounts.fromJson(json['counts'] as Map<String, dynamic>)
        : const ChatCounts(),
  );
}
