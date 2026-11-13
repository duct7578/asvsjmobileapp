import 'package:myasvsj/com.myasvsj.model/home_phrase.dart';
import 'package:myasvsj/com.myasvsj.model/home_quote.dart';

/// Trang chủ của khách (GuestHome của `GET /api/home`): số liệu, review "Hữu ích", mẫu câu trong ngày.
class HomeGuest {
  const HomeGuest({
    this.placesWithReviews = 0,
    this.reviewCount = 0,
    this.phraseCount = 0,
    this.quotes = const [],
    this.phrase,
  });

  /// Số địa điểm đã có review, số review, số mẫu câu (`stats`).
  final int placesWithReviews;
  final int reviewCount;
  final int phraseCount;

  /// Tối đa 2 review được thích nhiều nhất ("Senpai nói gì").
  final List<HomeQuote> quotes;

  /// Câu tiếng Nhật hôm nay; null khi chưa có mẫu câu nào.
  final HomePhrase? phrase;

  factory HomeGuest.fromJson(Map<String, dynamic> json) {
    final stats = (json['stats'] as Map<String, dynamic>?) ?? const {};
    return HomeGuest(
      placesWithReviews: (stats['placesWithReviews'] ?? 0) as int,
      reviewCount: (stats['reviews'] ?? 0) as int,
      phraseCount: (stats['phrases'] ?? 0) as int,
      quotes: [for (final q in (json['quotes'] as List?) ?? const []) HomeQuote.fromJson(q as Map<String, dynamic>)],
      phrase: HomePhrase.tryParse(json['phrase']),
    );
  }
}
