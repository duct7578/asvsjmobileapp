// Cách hiện ngày của sự kiện, dùng chung cho các màn hình "Lễ hội và sự kiện".
import 'package:myasvsj/com.myasvsj.model/event.dart';
import 'package:myasvsj/com.myasvsj.screen/date_text.dart';

/// "8/9/2026 – 10/9/2026", hoặc một ngày khi sự kiện diễn ra trong ngày.
String eventDateRange(Event event) =>
    event.isOneDay ? formatDate(event.startDate) : '${formatDate(event.startDate)} – ${formatDate(event.endDate)}';
