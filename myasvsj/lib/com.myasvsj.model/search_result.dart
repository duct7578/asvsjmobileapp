import 'package:myasvsj/com.myasvsj.model/search_event.dart';
import 'package:myasvsj/com.myasvsj.model/search_faq.dart';
import 'package:myasvsj/com.myasvsj.model/search_guide.dart';
import 'package:myasvsj/com.myasvsj.model/search_phrase.dart';
import 'package:myasvsj/com.myasvsj.model/search_place.dart';
import 'package:myasvsj/com.myasvsj.model/search_post.dart';
import 'package:myasvsj/com.myasvsj.model/search_question.dart';
import 'package:myasvsj/com.myasvsj.model/search_section.dart';

/// Kết quả "Tìm kiếm" (SiteSearch của `GET /api/search?q=`): một từ khóa tìm trong mọi phần của Senpai ơi,
/// mỗi phần tối đa 5 mục đầu kèm tổng số.
class SearchResult {
  const SearchResult({
    this.q = '',
    this.tooShort = false,
    this.total = 0,
    this.places = const SearchSection(),
    this.posts = const SearchSection(),
    this.questions = const SearchSection(),
    this.guides = const SearchSection(),
    this.events = const SearchSection(),
    this.phrases = const SearchSection(),
    this.faqs = const SearchSection(),
  });

  /// Từ khóa như server đã tìm (đã bỏ khoảng trắng hai đầu).
  final String q;

  /// Từ khóa có ít hơn 2 chữ hoặc số và không có chữ Nhật: server không tìm.
  final bool tooShort;

  /// Tổng số mục của mọi phần.
  final int total;

  final SearchSection<SearchPlace> places;
  final SearchSection<SearchPost> posts;
  final SearchSection<SearchQuestion> questions;
  final SearchSection<SearchGuide> guides;
  final SearchSection<SearchEvent> events;
  final SearchSection<SearchPhrase> phrases;
  final SearchSection<SearchFaq> faqs;

  /// Không phần nào tìm được gì.
  bool get isEmpty =>
      places.isEmpty &&
      posts.isEmpty &&
      questions.isEmpty &&
      guides.isEmpty &&
      events.isEmpty &&
      phrases.isEmpty &&
      faqs.isEmpty;

  factory SearchResult.fromJson(Map<String, dynamic> json) => SearchResult(
    q: (json['q'] ?? '') as String,
    tooShort: (json['tooShort'] ?? false) as bool,
    total: (json['total'] ?? 0) as int,
    places: SearchSection.fromJson(json['places'], SearchPlace.fromJson),
    posts: SearchSection.fromJson(json['posts'], SearchPost.fromJson),
    questions: SearchSection.fromJson(json['questions'], SearchQuestion.fromJson),
    guides: SearchSection.fromJson(json['guides'], SearchGuide.fromJson),
    events: SearchSection.fromJson(json['events'], SearchEvent.fromJson),
    phrases: SearchSection.fromJson(json['phrases'], SearchPhrase.fromJson),
    faqs: SearchSection.fromJson(json['faqs'], SearchFaq.fromJson),
  );
}
