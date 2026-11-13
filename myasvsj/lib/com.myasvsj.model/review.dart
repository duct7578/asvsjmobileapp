import 'package:myasvsj/com.myasvsj.model/media_item.dart';

/// Review của chính mình cho form "Viết review" / "Sửa review", ứng với một dòng bảng `reviews`.
///
/// Địa điểm là [placeId] (địa điểm Senpai ơi) hoặc [externalPlaceId] (địa điểm OpenStreetMap chưa có trên Senpai ơi,
/// server thêm địa điểm khi lưu review).
class Review {
  const Review({
    this.id,
    this.placeId,
    this.externalPlaceId,
    this.placeName = '',
    this.rating = 0,
    this.content = '',
    this.status = 'PUBLISHED',
    this.media = const [],
    this.scanningMediaIds = const [],
  });

  /// null khi review chưa lưu.
  final int? id;
  final int? placeId;
  final String? externalPlaceId;
  final String placeName;

  /// 1–5 sao; 0 khi chưa chọn.
  final int rating;
  final String content;

  /// PUBLISHED, PROCESSING (ảnh đang được quét) hoặc REJECTED (ảnh vi phạm, cần sửa lại).
  final String status;

  /// Ảnh / video đang gắn. Khi sửa, đây là danh sách giữ lại (`keepMediaIds`), server bỏ những file không có ở đây.
  final List<MediaItem> media;

  /// Ảnh vừa tải lên còn đang được quét ("Đang quét").
  final List<int> scanningMediaIds;

  bool get isRejected => status == 'REJECTED';

  /// EditData của `GET /api/reviews/{id}/edit`:
  /// `{id, placeId, placeName, rating, content, status, media: [{id, type, url, scanStatus}], limits, quota}`.
  factory Review.fromEditJson(Map<String, dynamic> json) {
    final media = [for (final m in (json['media'] as List?) ?? const []) m as Map<String, dynamic>];
    return Review(
      id: json['id'] as int,
      placeId: json['placeId'] as int?,
      placeName: (json['placeName'] ?? '') as String,
      rating: (json['rating'] ?? 0) as int,
      content: (json['content'] ?? '') as String,
      status: (json['status'] ?? 'PUBLISHED') as String,
      media: [for (final m in media) MediaItem.fromJson(m)],
      scanningMediaIds: [
        for (final m in media)
          if (m['scanStatus'] != null && m['scanStatus'] != 'PASSED') m['id'] as int,
      ],
    );
  }

  /// Phần JSON "review" gửi lên `POST /api/reviews` (CreateRequest `{placeId | externalPlaceId, rating, content}`)
  /// và `PUT /api/reviews/{id}` (UpdateRequest `{rating, content, keepMediaIds}`).
  Map<String, dynamic> toJson() => id == null
      ? {
          if (placeId != null) 'placeId': placeId else 'externalPlaceId': externalPlaceId,
          'rating': rating,
          'content': content,
        }
      : {
          'rating': rating,
          'content': content,
          'keepMediaIds': [for (final m in media) m.id],
        };
}
