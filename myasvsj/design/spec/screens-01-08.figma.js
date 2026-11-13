// Màn 01–06 (section 1) và 07–08 (section 2). Dùng helper trong design-system.figma.js (LIB).

// ===== 013 =====
const AF = Object.getPrototypeOf(async function () {}).constructor;
const H = await new AF('figma', (await figma.getNodeByIdAsync('3:3')).characters)(figma);
const SEC = await figma.getNodeByIdAsync('4:313');
const { T, I, F, add, fill, stroke, badge, avatar, iconTile, card, btn, chip, search, sectionHead, stars, progress, cover, screen, body, nav, inst, abs, divider } = H;
const X = k => 60 + k * 450, Y = 160;
const fitH = (s, b) => { b.layoutSizingVertical = 'HUG'; s.primaryAxisSizingMode = 'AUTO'; };
const brandHeader = (user) => { const logo = inst('Logo'); logo.rescale(0.85);
  return F('H', { name: 'AppBar/Brand', p: [6, 8, 6, 16], gap: 8, align: 'c' }, [logo, [T('Senpai ơi', 'Display/M', 'brand-text'), 'g'], inst('TopActions', { User: user })]); };
const phraseCard = (jp, romaji, vi, cat) => { const c = F('V', { name: 'HomePhraseCard', fill: 'ink', r: 20, p: 18, gap: 8, clip: true }, [
  [F('H', { gap: 8, align: 'c' }, [I('translate', 20, 'lantern'), [T('Câu tiếng Nhật hôm nay', 'Label/M', 'on-brand'), 'g'], F('H', { fill: 'surface', op: 0.14, r: 99, p: [3, 10], gap: 4, align: 'c' }, [I('storefront', 14, 'on-brand'), T(cat, 'Label/S', 'on-brand')])]), 'w'],
  [T(jp, 'JP/L', 'on-brand'), 'w'], T(romaji, 'Body/M', 'lantern'), [T(vi, 'Body/M', 'on-brand'), 'w'],
  F('H', { gap: 10, align: 'c', p: [6, 0, 0, 0] }, [F('H', { fill: 'brand', r: 99, p: [8, 16, 8, 12], gap: 6, align: 'c' }, [I('volume_up', 18, 'on-brand'), T('Nghe', 'Label/M', 'on-brand')]), F('H', { gap: 4, align: 'c' }, [I('school', 18, 'on-brand'), T('Học thêm chủ đề này', 'Label/M', 'on-brand')])])]);
  const deco = T('あ', 'JP/L', 'on-brand', { size: 120 }); deco.opacity = 0.06; abs(c, deco, 250, -10); return c; };
const out = {};

// ===== 01 Home guest =====
{ const s = screen(SEC, '01 · Trang chủ — Khách (home_screen + home_guest_view)', X(0), Y);
  add(s, [[brandHeader('Guest'), 'w']]);
  const hero = F('V', { name: 'Hero', fill: 'brand', r: 24, p: 20, gap: 14, clip: true });
  const deco = inst('Logo'); deco.rescale(4.2); deco.opacity = 0.16; abs(hero, deco, 214, -36);
  const tag = F('H', { name: 'eyebrow', fill: 'surface', op: 0.18, r: 99, p: [4, 10], gap: 6, align: 'c' }, [I('local_florist', 16, 'on-brand'), T('Cho du học sinh Việt mới đến Nhật', 'Label/S', 'on-brand')]);
  const p = T('Các senpai đã đánh dấu sẵn chỗ ăn rẻ, ga tàu, văn phòng quận. Mở bản đồ là thấy nơi nào đã có người Việt review, kèm câu tiếng Nhật để dùng ngay tại đó.', 'Body/M', 'on-brand'); p.opacity = 0.92;
  const sbox = F('H', { name: 'search', fill: 'surface', r: 999, p: [6, 6, 6, 16], gap: 8, align: 'c' }, [I('search', 22, 'muted'), [T('Tìm địa điểm, bài viết, sự kiện…', 'Body/S', 'muted', { lines: 1 }), 'g'], btn('Tìm', 'Primary', { size: 'S' })]);
  const reg = F('H', { name: 'btn/outline-white', stroke: 'on-brand', sw: 1.5, r: 14, h: 52, gap: 8, just: 'c', align: 'c' }, [I('person_add', 20, 'on-brand'), T('Đăng ký miễn phí', 'Label/M', 'on-brand')]);
  const note = T('Xem bản đồ, review và từ vựng không cần tài khoản.', 'Caption', 'on-brand'); note.opacity = 0.85;
  add(hero, [tag, [T('Ở Nhật, bạn không đi một mình.', 'Display/XL', 'on-brand'), 'w'], [p, 'w'], [sbox, 'w'], [btn('Xem bản đồ', 'Secondary', { icon: 'map' }), 'w'], [reg, 'w'], [note, 'w']]);
  const stat = (n, l) => [F('V', { name: 'stat', fill: 'surface', r: 16, stroke: 'line', p: 12, gap: 2 }, [T(n, 'Display/L', 'brand'), [T(l, 'Caption', 'muted'), 'w']]), 'g'];
  const stats = F('H', { name: 'Stats', gap: 10 }, [stat('1.240', 'địa điểm đã có review'), stat('3.580', 'review của người Việt'), stat('620', 'mẫu câu theo địa điểm')]);
  const quote = (q, who, tags, tone, place) => F('V', { name: 'QuoteCard', fill: 'surface', r: 20, stroke: 'line', p: 16, gap: 10, w: 280 }, [I('format_quote', 28, 'brand', true), [T(q, 'Body/M', 'ink'), 'w'],
    F('H', { gap: 8, align: 'c' }, [avatar(who[0], 28, tone), T(who, 'Label/M', 'ink'), badge(tags, tone)]), T('về ' + place, 'Caption', 'muted')]);
  const quotes = F('H', { name: 'Quotes', gap: 12 }, [quote('Gyomu Super ở đây rẻ hơn hẳn, thứ Ba có giảm giá rau. Nhân viên kiên nhẫn với người mới.', 'Hà Phương', 'Du học sinh', 'brand', 'Gyomu Super Minami-Senju'), quote('Làm thủ tục chuyển địa chỉ mất 40 phút, nhớ mang thẻ cư trú và hợp đồng nhà.', 'Quang Huy', 'Đã đi làm', 'ai', 'Arakawa Ward Office')]);
  const feat = (ic, tone, t, d) => F('V', { name: 'Feature', fill: 'surface', r: 18, stroke: 'line', p: 14, gap: 8, w: 173 }, [iconTile(ic, tone, 40), [T(t, 'Title/S', 'ink'), 'w'], [T(d, 'Body/S', 'muted'), 'w']]);
  const feats = F('H', { name: 'Features', gap: 12, wrap: true, rowGap: 12, w: 358 }, [feat('location_on', 'brand', 'Bản đồ có review', 'Nơi nào đã có review sẽ nở hoa trên bản đồ.'), feat('school', 'ai', 'Học tiếng Nhật theo chủ đề', 'Thanh toán, hỏi đường, khám bệnh… học đúng câu mình sắp dùng.'), feat('contact_support', 'lantern', 'Hỏi senpai', 'Đặt câu hỏi, Mentor trả lời, bạn chọn câu hay nhất.'), feat('celebration', 'ok', 'Lễ hội gần bạn', 'Sự kiện đang và sắp diễn ra hiện ngay trên bản đồ.')]);
  const foot = F('H', { name: 'Footer', gap: 6, just: 'c', align: 'c' }, [T('Điều khoản sử dụng', 'Caption', 'muted'), T('·', 'Caption', 'muted'), T('Chính sách bảo mật', 'Caption', 'muted'), T('·', 'Caption', 'muted'), T('Quy tắc cộng đồng', 'Caption', 'muted')]);
  const b = body(s, { p: [4, 16, 24, 16], gap: 20 }, [[hero, 'w'], [stats, 'w'], [sectionHead('Senpai nói gì', 'Xem thêm'), 'w'], quotes, [sectionHead('Senpai ơi giúp gì cho bạn'), 'w'], feats, [phraseCard('袋はいりません。', 'Fukuro wa irimasen.', 'Tôi không cần túi ạ.', 'Cửa hàng tiện lợi'), 'w'], [foot, 'w']]);
  nav(s, 'Trang chủ'); fitH(s, b); out.home_guest = s.id; }

// ===== 02 Home member =====
{ const s = screen(SEC, '02 · Trang chủ — Thành viên (home_member_view)', X(1), Y);
  add(s, [[brandHeader('Member'), 'w']]);
  const greet = F('H', { name: 'Greeting', gap: 12, align: 'c' }, [iconTile('local_florist', 'brand', 52, 26), [F('V', { gap: 4 }, [[T('Chào Linh, dạo này ở Arakawa thế nào rồi?', 'Title/M', 'ink'), 'w'], F('H', { gap: 6, align: 'c' }, [badge('Mới đến', 'brand', 'flag'), F('H', { gap: 2, align: 'c' }, [T('1.250 điểm · Senpai bạc', 'Label/S', 'brand-text'), I('chevron_right', 16, 'brand-text')])])]), 'g']]);
  const next = card({ name: 'NextCard', r: 20, p: 16, gap: 12 }, [
    [F('H', { gap: 10, align: 'c' }, [iconTile('menu_book', 'lantern', 40), [F('V', { gap: 0 }, [T('Việc tiếp theo', 'Title/M', 'ink'), T('3/8 · Mới đến Nhật', 'Label/S', 'brand-text')]), 'g'], I('chevron_right', 22, 'muted')]), 'w'],
    progress(37, 326, 'brand'),
    [T('Đăng ký địa chỉ tại văn phòng quận', 'Title/S', 'ink'), 'w'], [T('2/5 việc · Tiếp theo: Mang thẻ cư trú tới quầy 住民登録', 'Body/S', 'muted'), 'w'],
    F('H', { gap: 6, align: 'c' }, [I('schedule', 16, 'crit'), T('Hạn: trong 14 ngày kể từ khi chuyển đến', 'Label/S', 'crit')]),
    chip('Arakawa Ward Office', false, 'location_on'),
    [F('H', { gap: 10 }, [[btn('Mở cẩm nang này', 'Primary', { size: 'M', icon: 'menu_book' }), 'g'], btn('Cả giai đoạn', 'Secondary', { size: 'M' })]), 'w']]);
  const post = (reason, ric, title, ex, who, likes, cmts) => F('V', { name: 'FeedPostCard', fill: 'surface-2', r: 14, p: 12, gap: 6 }, [badge(reason, 'brand', ric), [T(title, 'Title/S', 'ink'), 'w'], ex ? [T(ex, 'Body/S', 'muted', { lines: 2 }), 'w'] : null,
    [F('H', { gap: 4, align: 'c' }, [[T(who, 'Caption', 'muted'), 'g'], I('favorite', 16, 'brand', true), T(likes, 'Caption', 'muted'), H.sp(1, 6), I('chat_bubble', 16, 'muted'), T(cmts, 'Caption', 'muted')]), 'w']]);
  const forYou = card({ name: 'ForYou', fill: 'surface', r: 20, p: 16, gap: 12 }, [
    [sectionHead('Dành cho bạn', 'Xem tất cả', 'auto_awesome'), 'w'],
    [T('Bài viết và cẩm nang chọn riêng cho bạn, theo khu vực, giai đoạn và chủ đề bạn quan tâm.', 'Body/S', 'muted'), 'w'],
    [F('H', { name: 'FeedBasis', gap: 6, wrap: true, rowGap: 6, align: 'c' }, [T('Dựa trên', 'Label/S', 'muted'), badge('Arakawa', 'ai', 'location_on'), badge('Mới đến', 'ai', 'flag'), badge('Nhà ở', 'ai', 'interests'), F('H', { gap: 2, align: 'c' }, [I('tune', 16, 'brand-text'), T('Điều chỉnh', 'Label/S', 'brand-text')])]), 'w'],
    [post('Gần bạn · Arakawa', 'location_on', 'Thuê nhà không cần người bảo lãnh ở Tokyo: mình đã làm thế nào', 'Ba công ty nhận hồ sơ du học sinh, phí bảo lãnh khoảng 50% tiền nhà một tháng…', 'Minh Anh · 2 giờ trước', '24', '8'), 'w'],
    [post('Hợp giai đoạn · Mới đến', 'flag', 'Checklist 2 tuần đầu: SIM, ngân hàng, thẻ My Number', null, 'Tuấn · hôm qua', '41', '12'), 'w'],
    [btn('Xem tất cả bài viết dành cho bạn', 'Soft', { size: 'M', icon: 'arrow_forward' }), 'w']]);
  const rv = (ic, tone, name, n, ex, meta) => F('H', { name: 'ReviewRow', gap: 12 }, [iconTile(ic, tone, 40, 20), [F('V', { gap: 2 }, [[F('H', { gap: 6, align: 'c' }, [[T(name, 'Title/S', 'ink', { lines: 1 }), 'g'], stars(n, 14)]), 'w'], [T(ex, 'Body/S', 'ink', { lines: 2 }), 'w'], T(meta, 'Caption', 'muted')]), 'g']]);
  const reviews = card({ name: 'Reviews', r: 20, p: 16, gap: 14 }, [[sectionHead('Review mới quanh Arakawa', 'Tất cả', 'rate_review'), 'w'],
    [rv('shopping_cart', 'brand', 'Gyomu Super Minami-Senju', 4, 'Hà: Rau thứ Ba giảm 20%, có góc đồ châu Á, nước mắm Phú Quốc.', 'Arakawa · 3 giờ trước'), 'w'],
    [rv('train', 'ai', 'Ga Machiya (Chiyoda Line)', 5, 'Huy: Cửa A2 có thang máy, mua thẻ Suica ở máy màu xanh.', 'Arakawa · hôm qua'), 'w'],
    [rv('local_hospital', 'ok', 'Phòng khám Nishi-Nippori', 4, 'Mai: Bác sĩ nói chậm, có giấy hỏi bệnh tiếng Anh.', 'Arakawa · 2 ngày trước'), 'w']]);
  const ev = (d, m, t, sub) => F('H', { name: 'EventRow', gap: 12, align: 'c' }, [F('V', { name: 'date', fill: 'brand-soft', r: 14, w: 52, h: 56, just: 'c', align: 'c' }, [T(d, 'Display/M', 'brand-text'), T(m, 'Label/S', 'brand-text')]), [F('V', { gap: 2 }, [[T(t, 'Title/S', 'ink'), 'w'], T(sub, 'Caption', 'muted')]), 'g'], I('chevron_right', 22, 'muted')]);
  const events = card({ name: 'Events', r: 20, p: 16, gap: 12 }, [[sectionHead('Sự kiện 2 tuần tới', 'Tất cả', 'celebration'), 'w'], [ev('15', 'Th11', 'Tori-no-ichi — Chợ phiên Gà', 'Còn 7 ngày · Đền Ōtori, Asakusa'), 'w'], [ev('08', 'Th11', 'Lễ hội lá phong Rikugien', 'Đang diễn ra · Komagome'), 'w']]);
  const feat = card({ name: 'Featured', r: 20, p: 0, gap: 0, clip: true }, [[cover('Sakura', 358, 140, 0), 'w'], [F('V', { p: 16, gap: 6 }, [[F('H', { gap: 6, align: 'c' }, [badge('Bài nổi bật tuần này', 'lantern', 'star'), H.sp(1, 1), [T('5 phút đọc', 'Caption', 'muted', { align: 'RIGHT' }), 'g']]), 'w'], [T('Mùa hanami đầu tiên: 6 công viên ít đông người ở Tokyo', 'Title/M', 'ink'), 'w'], [T('Chọn giờ, mang gì và những phép lịch sự khi ngồi dưới gốc anh đào…', 'Body/S', 'muted', { lines: 2 }), 'w'], F('H', { gap: 6, align: 'c' }, [avatar('T', 24, 'lantern'), T('Thảo Vy', 'Label/S', 'ink'), badge('Đã đi làm', 'ai')])]), 'w']]);
  const b = body(s, { p: [4, 16, 24, 16], gap: 16 }, [[greet, 'w'], [search('Tìm địa điểm, bài viết, sự kiện…'), 'w'], [next, 'w'], [forYou, 'w'], [reviews, 'w'], [events, 'w'], [phraseCard('すみません、ゴミの日はいつですか？', 'Sumimasen, gomi no hi wa itsu desu ka?', 'Xin lỗi, ngày đổ rác là khi nào ạ?', 'Văn phòng quận'), 'w'], [feat, 'w']]);
  nav(s, 'Trang chủ'); fitH(s, b); out.home_member = s.id; }
return out;
// ===== 014 =====
const AF = Object.getPrototypeOf(async function () {}).constructor;
const H = await new AF('figma', (await figma.getNodeByIdAsync('3:3')).characters)(figma);
const SEC = await figma.getNodeByIdAsync('4:313');
const { T, I, F, add, fill, badge, avatar, iconTile, card, btn, chip, chips, search, sectionHead, stars, appBar, screen, body, nav, group, listRow, divider, paint, sp } = H;
const X = k => 60 + k * 450, Y = 160;
const out = {};
const hl = (txt, word, style, color) => { const t = T(txt, style || 'Title/S', color || 'ink'); const i = txt.toLowerCase().indexOf(word.toLowerCase());
  if (i >= 0) { t.setRangeFills(i, i + word.length, [paint('brand-text')]); t.setRangeFontName(i, i + word.length, { family: 'Be Vietnam Pro', style: 'Bold' }); t.setRangeTextDecoration(i, i + word.length, 'UNDERLINE'); } return t; };
const hitHead = (ic, title, n) => F('H', { name: 'hitHead', gap: 8, align: 'c' }, [iconTile(ic, 'brand', 28, 8), [T(title, 'Title/M', 'ink'), 'g'], badge(n, 'neutral')]);
const hit = (lead, title, sub, meta) => F('H', { name: 'hit', gap: 12, p: [10, 0], align: 'c' }, [lead, [F('V', { gap: 2 }, [[title, 'w'], sub ? [T(sub, 'Body/S', 'muted', { lines: 2 }), 'w'] : null, meta ? [F('H', { gap: 6, align: 'c', wrap: true }, meta), 'w'] : null]), 'g']]);

// 03 Global search
{ const s = screen(SEC, '03 · Tìm kiếm (global_search_screen)', X(2), Y);
  const bar = F('H', { name: 'SearchBar', p: [6, 16, 6, 4], gap: 4, align: 'c' }, [F('H', { w: 40, h: 40, just: 'c', align: 'c' }, [I('arrow_back', 24, 'ink')]), [F('H', { name: 'field', fill: 'surface', stroke: 'brand', sw: 2, r: 999, p: [0, 8, 0, 16], h: 48, gap: 8, align: 'c' }, [I('search', 22, 'brand'), [T('nhà ở', 'Body/M', 'ink'), 'g'], F('H', { w: 32, h: 32, r: 16, fill: 'surface-2', just: 'c', align: 'c' }, [I('close', 18, 'muted')])]), 'g']]);
  add(s, [[bar, 'w']]);
  const res = F('V', { name: 'Results', fill: 'surface', r: 20, stroke: 'line', p: [8, 16], gap: 0 });
  add(res, [[hitHead('location_on', 'Địa điểm', '5'), 'w'],
    [hit(iconTile('apartment', 'ai', 40, 20), hl('Leopalace21 Arakawa (văn phòng cho thuê nhà ở)', 'nhà ở'), 'レオパレス21 · 3-1 Arakawa, Arakawa-ku', [badge('Bất động sản', 'ai'), T('★ 4.1 · 12 review', 'Caption', 'lantern-text')]), 'w'],
    [divider(), 'w'],
    [hit(iconTile('home_work', 'ai', 40, 20), hl('Sakura House Nippori — nhà ở chung', 'nhà ở'), 'さくらハウス · Nishi-Nippori', [badge('Share house', 'ai'), T('Chưa có review', 'Caption', 'muted')]), 'w']]);
  const posts = F('V', { name: 'Results', fill: 'surface', r: 20, stroke: 'line', p: [8, 16], gap: 0 });
  add(posts, [[hitHead('forum', 'Bài viết', '8'), 'w'],
    [hit(null, hl('Kinh nghiệm tìm nhà ở Tokyo khi chưa có người bảo lãnh', 'nhà ở'), '…ba công ty nhận hồ sơ du học sinh, phí bảo lãnh khoảng 50% tiền nhà…', [badge('Nhà ở', 'brand'), T('Minh Anh · 2 giờ trước · ♥ 24 · 8 bình luận', 'Caption', 'muted')]), 'w'],
    [divider(), 'w'],
    [hit(null, hl('Hợp đồng nhà ở: đọc 重要事項説明 thế nào?', 'nhà ở'), null, [badge('Nhà ở', 'brand'), T('Quang Huy · 3 ngày trước', 'Caption', 'muted')]), 'w'],
    [F('H', { p: [8, 0, 10, 0], gap: 4, align: 'c' }, [T('Xem tất cả 8 bài viết trong Blog', 'Label/M', 'brand-text'), I('arrow_forward', 18, 'brand-text')]), 'w']]);
  const qa = F('V', { name: 'Results', fill: 'surface', r: 20, stroke: 'line', p: [8, 16], gap: 0 });
  add(qa, [[hitHead('contact_support', 'Hỏi-Đáp', '6'), 'w'], [hit(null, hl('Hết hợp đồng nhà ở có được lấy lại tiền đặt cọc không?', 'nhà ở'), null, [badge('Đã giải quyết', 'ok', 'check_circle'), T('Lan · 1 tuần trước · 5 trả lời', 'Caption', 'muted')]), 'w']]);
  const b = body(s, { p: [4, 16, 24, 16], gap: 14 }, [T('Tìm thấy 24 kết quả cho “nhà ở”.', 'Body/S', 'muted'), chips(['Tất cả 24', 'Địa điểm 5', 'Bài viết 8', 'Hỏi-Đáp 6', 'Cẩm nang 3'], 0), [res, 'w'], [posts, 'w'], [qa, 'w']]);
  out.search = s.id; }

// 04 For You
{ const s = screen(SEC, '04 · Dành cho bạn (for_you_screen)', X(3), Y);
  add(s, [[appBar('Dành cho bạn', { sub: 'Chọn riêng theo khu vực, giai đoạn, chủ đề' }), 'w']]);
  const basis = F('V', { name: 'FeedBasis', fill: 'ai-soft', r: 18, p: 14, gap: 10 }, [[F('H', { gap: 6, align: 'c' }, [I('auto_awesome', 18, 'brand'), [T('Dựa trên', 'Label/M', 'ink'), 'g'], F('H', { fill: 'surface', r: 99, p: [6, 12], gap: 4, align: 'c' }, [I('tune', 16, 'brand-text'), T('Điều chỉnh', 'Label/S', 'brand-text')])]), 'w'],
    [F('H', { gap: 6, wrap: true, rowGap: 6 }, [badge('Arakawa', 'brand', 'location_on'), badge('Mới đến', 'brand', 'flag'), badge('Nhà ở', 'brand', 'interests'), badge('Việc làm thêm', 'brand', 'interests'), badge('Ẩm thực', 'neutral', 'history')]), 'w']]);
  const post = (reason, ric, title, ex, who, likes, cmts, img) => card({ name: 'FeedPostCard', r: 18, p: 14, gap: 8 }, [[F('H', { gap: 6, align: 'c' }, [badge(reason, 'brand', ric), sp(1, 1)]), 'w'],
    [F('H', { gap: 12 }, [[F('V', { gap: 4 }, [[T(title, 'Title/S', 'ink'), 'w'], [T(ex, 'Body/S', 'muted', { lines: 3 }), 'w']]), 'g'], img ? H.cover(img, 76, 76, 12) : null]), 'w'],
    badge('Nhà ở', 'neutral', 'sell'),
    [F('H', { gap: 4, align: 'c' }, [[T(who, 'Caption', 'muted'), 'g'], I('favorite_border', 16, 'muted'), T(likes, 'Caption', 'muted'), sp(1, 6), I('chat_bubble', 16, 'muted'), T(cmts, 'Caption', 'muted')]), 'w']]);
  const b = body(s, { p: [4, 16, 24, 16], gap: 14 }, [[search('Tìm trong bài dành cho bạn'), 'w'], [T('36 bài viết của các thành viên khác, xếp theo khu vực, giai đoạn và chủ đề bạn quan tâm.', 'Body/S', 'muted'), 'w'], [basis, 'w'], chips(['Tất cả · 36', 'Gần bạn · 12', 'Hợp giai đoạn · 9', 'Chủ đề · 15'], 0),
    [post('Gần bạn · Arakawa', 'location_on', 'Thuê nhà không cần người bảo lãnh ở Tokyo', 'Ba công ty nhận hồ sơ du học sinh, phí bảo lãnh khoảng 50% tiền nhà một tháng. Mình kể lại từng bước…', 'Minh Anh · 2 giờ trước', '24', '8', 'City'), 'w'],
    [post('Hợp giai đoạn · Mới đến', 'flag', 'Checklist 2 tuần đầu: SIM, ngân hàng, My Number', 'Thứ tự làm giấy tờ để không phải chạy đi chạy lại văn phòng quận.', 'Tuấn · hôm qua', '41', '12', 'Study'), 'w'],
    [post('Chủ đề · Việc làm thêm', 'interests', 'Xin baito ở konbini: phỏng vấn hỏi những gì?', 'Những câu hay gặp và cách trả lời bằng tiếng Nhật đơn giản…', 'Hà Phương · 3 ngày trước', '57', '20', 'Food'), 'w']]);
  out.foryou = s.id; }

// 05 Notifications
{ const s = screen(SEC, '05 · Thông báo (notification_screen)', X(4), Y);
  add(s, [[appBar('Thông báo', { actions: ['done_all'] }), 'w']]);
  const tile = (ic, tone, txt, time, unread) => F('H', { name: 'NotificationTile', fill: unread ? 'surface' : null, stroke: unread ? 'line' : null, r: 16, p: 12, gap: 12 }, [iconTile(ic, tone, 40, 20), [F('V', { gap: 4 }, [[T(txt, unread ? 'Label/M' : 'Body/S', 'ink'), 'w'], T(time, 'Caption', unread ? 'brand-text' : 'muted')]), 'g'], unread ? H.dot(10, 'brand') : null]);
  const b = body(s, { p: [4, 16, 24, 16], gap: 8 }, [
    [F('H', { name: 'summary', fill: 'brand-soft', r: 14, p: [10, 14], gap: 8, align: 'c' }, [I('notifications_active', 20, 'brand-text'), [T('5 thông báo chưa đọc.', 'Label/M', 'brand-text'), 'g'], T('Đọc hết', 'Label/S', 'brand-text', { deco: 'UNDERLINE' })]), 'w'],
    T('HÔM NAY', 'Overline', 'muted'),
    [tile('workspace_premium', 'lantern', 'Câu trả lời của bạn được chọn là hay nhất trong “Gia hạn visa du học cần giấy tờ gì?” · +5 điểm', '12 phút trước', true), 'w'],
    [tile('chat_bubble', 'brand', 'Minh Anh đã bình luận bài “Thuê nhà không cần người bảo lãnh”', '1 giờ trước', true), 'w'],
    [tile('place', 'brand', 'Ghim “Chùa Sensō-ji cổng sau” của bạn đã được duyệt · +15 điểm', '3 giờ trước', true), 'w'],
    T('HÔM QUA', 'Overline', 'muted'),
    [tile('check_circle', 'ok', 'Review “Gyomu Super Minami-Senju” đã được đăng.', 'hôm qua', true), 'w'],
    [tile('sell', 'ai', 'Bạn đã được cấp tag “Du học sinh”.', 'hôm qua', true), 'w'],
    [tile('block', 'crit', 'Ảnh trong bài “Đi Kamakura 1 ngày” vi phạm Quy tắc cộng đồng.', '2 ngày trước', false), 'w'],
    [tile('notifications', 'neutral', 'Chào mừng bạn đến Senpai ơi! Chọn khu vực để nhận gợi ý gần bạn.', '5 ngày trước', false), 'w'],
    [F('H', { just: 'c', p: [8, 0] }, [btn('Xem thêm', 'Ghost', { size: 'S' })]), 'w']]);
  out.notif = s.id; }

// 06 More
{ const s = screen(SEC, '06 · Thêm (more_screen) — thành viên', X(5), Y);
  add(s, [[appBar('Thêm', { large: true, top: 'Member' }), 'w']]);
  const me = F('H', { name: 'ProfileCard', fill: 'brand', r: 20, p: 16, gap: 12, align: 'c', clip: true }, [avatar('L', 52, 'lantern'), [F('V', { gap: 2 }, [T('Linh Nguyễn', 'Title/M', 'on-brand'), T('1.250 điểm · Senpai bạc · Arakawa', 'Caption', 'on-brand')]), 'g'], I('chevron_right', 24, 'on-brand')]);
  const deco = H.inst('Logo'); deco.rescale(2.5); deco.opacity = 0.15; H.abs(me, deco, 300, -20);
  const tile = (ic, tone, t, d) => F('V', { name: 'ExploreTile', fill: 'surface', r: 18, stroke: 'line', p: 14, gap: 8, w: 173, h: 128 }, [iconTile(ic, tone, 40), [T(t, 'Title/S', 'ink'), 'w'], d ? [T(d, 'Caption', 'muted', { lines: 2 }), 'w'] : null]);
  const grid = F('H', { name: 'Explore', gap: 12, wrap: true, rowGap: 12, w: 358 }, [tile('translate', 'brand', 'Nhật ngữ', 'Mẫu câu, từ vựng, thẻ ghi nhớ'), tile('festival', 'lantern', 'Lễ hội và sự kiện', 'Đang và sắp diễn ra'), tile('menu_book', 'ok', 'Cẩm nang', 'Theo từng giai đoạn'), tile('help', 'ai', 'Câu hỏi thường gặp', 'Moderator tổng hợp')]);
  const cnt = (n) => F('H', { gap: 6, align: 'c' }, [badge(n, 'solid'), I('chevron_right', 22, 'muted')]);
  const mine = group([listRow(iconTile('chat_bubble', 'brand', 36, 10), 'Tin nhắn', null, { trail: cnt('3') }), listRow(iconTile('notifications', 'brand', 36, 10), 'Thông báo', null, { trail: cnt('12') }), listRow(iconTile('bookmark', 'brand', 36, 10), 'Đã lưu', null), listRow(iconTile('checklist', 'brand', 36, 10), 'Cẩm nang của tôi', null)]);
  const legal = group([listRow(iconTile('gavel', 'neutral', 36, 10), 'Điều khoản sử dụng', null), listRow(iconTile('privacy_tip', 'neutral', 36, 10), 'Chính sách bảo mật', null), listRow(iconTile('groups', 'neutral', 36, 10), 'Quy tắc cộng đồng', null)]);
  const b = body(s, { p: [4, 16, 24, 16], gap: 14 }, [[me, 'w'], T('KHÁM PHÁ', 'Overline', 'muted'), grid, T('CỦA TÔI', 'Overline', 'muted'), [mine, 'w'], T('PHÁP LÝ', 'Overline', 'muted'), [legal, 'w'], [T('Senpai ơi · phiên bản 1.0.0', 'Caption', 'muted', { align: 'CENTER' }), 'w']]);
  nav(s, 'Thêm'); b.layoutSizingVertical = 'HUG'; s.primaryAxisSizingMode = 'AUTO'; out.more = s.id; }
return out;
// ===== 015 =====
const AF = Object.getPrototypeOf(async function () {}).constructor;
const H = await new AF('figma', (await figma.getNodeByIdAsync('3:3')).characters)(figma);
const SEC = await figma.getNodeByIdAsync('4:316');
const { T, I, F, add, fill, stroke, badge, iconTile, btn, chip, chips, stars, appBar, screen, nav, abs, divider, sp } = H;
const X = k => 60 + k * 450, Y = 160;
const out = {};
const mapSvg = '<svg width="390" height="760" viewBox="0 0 390 760" fill="none" xmlns="http://www.w3.org/2000/svg"><rect width="390" height="760" fill="#F3EEE6"/><path d="M318 -10C262 130 340 240 288 380C246 490 338 620 300 770" stroke="#CFE3F2" stroke-width="48" stroke-linecap="round"/><rect x="22" y="400" width="140" height="120" rx="20" fill="#DDEBD3"/><rect x="186" y="110" width="74" height="86" rx="16" fill="#DDEBD3"/><rect x="40" y="640" width="90" height="70" rx="14" fill="#DDEBD3"/><path d="M0 150H390M0 600H390M60 0V760M222 0V760M0 460C120 450 260 480 390 440M0 330H220" stroke="#FFFFFF" stroke-width="6"/><path d="M-10 270C120 260 240 290 400 250" stroke="#FFFFFF" stroke-width="16"/><path d="M128 -10C138 220 106 460 146 770" stroke="#FFFFFF" stroke-width="13"/><path d="M-10 690C120 640 260 600 400 550" stroke="#B7BCD0" stroke-width="4" stroke-dasharray="10 6"/></svg>';
const pinReview = (ic, n, big) => { const sz = big ? 52 : 44; const p = F('H', { name: 'pin/review', fill: 'brand', r: sz / 2, w: sz, h: sz, just: 'c', align: 'c', stroke: 'surface', sw: 3, shadow: 'Shadow/Float' }, [I(ic, big ? 26 : 22, 'on-brand', true)]);
  const b = F('H', { name: 'count', fill: 'lantern', r: 99, p: [1, 6], stroke: 'surface', sw: 1.5 }, [T(n, 'Overline', 'ink')]); p.appendChild(b); b.layoutPositioning = 'ABSOLUTE'; b.x = sz - 18; b.y = -6; return p; };
const pinSmall = (ic) => F('H', { name: 'pin/none', fill: 'surface', r: 17, w: 34, h: 34, just: 'c', align: 'c', stroke: 'line', sw: 2 }, [I(ic, 18, 'muted')]);
const pinEvent = (label) => F('V', { name: 'pin/event', gap: 4, align: 'c' }, [F('H', { fill: 'lantern', r: 22, w: 44, h: 44, just: 'c', align: 'c', stroke: 'surface', sw: 3, shadow: 'Shadow/Card' }, [I('celebration', 22, 'ink', true)]), F('H', { fill: 'ink', r: 99, p: [2, 8] }, [T(label, 'Label/S', 'on-brand')])]);
const pinScam = (ic) => { const p = F('H', { name: 'pin/scam', fill: 'surface', r: 20, w: 40, h: 40, just: 'c', align: 'c', stroke: 'crit', sw: 2 }, [I(ic, 20, 'crit')]); const b = F('H', { fill: 'crit', r: 99, w: 18, h: 18, just: 'c', align: 'c' }, [T('!', 'Label/S', 'on-brand')]); p.appendChild(b); b.layoutPositioning = 'ABSOLUTE'; b.x = 26; b.y = -4; return p; };
const me = () => { const f = figma.createFrame(); f.name = 'me'; f.resize(44, 44); f.fills = []; const halo = figma.createEllipse(); halo.resize(44, 44); fill(halo, 'ink', 0.15); const d = figma.createEllipse(); d.resize(16, 16); fill(d, 'ink'); stroke(d, 'surface', 3); f.appendChild(halo); f.appendChild(d); d.x = 14; d.y = 14; return f; };
const fabSmall = (ic) => F('H', { name: 'mapFab', fill: 'surface', r: 14, w: 44, h: 44, just: 'c', align: 'c', shadow: 'Shadow/Card' }, [I(ic, 22, 'ink')]);
const buildMap = (s, sel) => {
  const area = figma.createFrame(); area.name = 'MapArea'; area.clipsContent = true; area.fills = []; add(s, [[area, 'wh']]);
  nav(s, 'Bản đồ');
  const m = figma.createNodeFromSvg(mapSvg); m.name = 'OSM tiles'; area.appendChild(m); m.x = 0; m.y = 0;
  const sbx = F('H', { name: 'search', fill: 'surface', r: 999, p: [0, 8, 0, 16], h: 48, gap: 10, align: 'c', w: 358, shadow: 'Shadow/Card' }, [I('search', 22, 'muted'), [T('Tìm địa điểm', 'Body/M', 'muted'), 'g'], F('H', { fill: 'brand-soft', r: 16, w: 32, h: 32, just: 'c', align: 'c' }, [I('tune', 18, 'brand-text')])]);
  abs(area, sbx, 16, 12);
  const cats = chips([['Tất cả (86)', 'apps'], ['Siêu thị (24)', 'shopping_cart'], ['Ga tàu (12)', 'train'], ['Quán ăn (30)', 'restaurant']], 0); abs(area, cats, 16, 70);
  const evRow = F('H', { name: 'eventRow', fill: 'surface', r: 99, p: [4, 4, 4, 12], gap: 6, align: 'c', shadow: 'Shadow/Card' }, [I('celebration', 18, 'lantern-text'), T('Sự kiện:', 'Label/S', 'ink'), F('H', { fill: 'surface-2', r: 99, p: [4, 10] }, [T('Tắt', 'Label/S', 'muted')]), F('H', { fill: 'ink', r: 99, p: [4, 10] }, [T('15 ngày tới', 'Label/S', 'on-brand')]), F('H', { fill: 'surface-2', r: 99, p: [4, 10] }, [T('30 ngày tới', 'Label/S', 'muted')])]);
  abs(area, evRow, 16, 116);
  abs(area, fabSmall('my_location'), 330, 166); abs(area, fabSmall('info'), 330, 218);
  abs(area, pinReview('shopping_cart', '18', sel), 160, 300); abs(area, pinReview('restaurant', '9'), 54, 218); abs(area, pinReview('train', '31'), 236, 356);
  abs(area, pinSmall('local_hospital'), 92, 380); abs(area, pinSmall('account_balance'), 250, 230); abs(area, pinScam('real_estate_agent'), 40, 316);
  abs(area, pinEvent('Còn 7 ngày'), 266, 160); abs(area, me(), 176, 410);
  const attr = F('H', { fill: 'surface', op: 0.8, r: 6, p: [2, 6] }, [T('© OpenStreetMap', 'Caption', 'muted')]);
  return { area, attr };
};
// 07 Map + results
{ const s = screen(SEC, '07 · Bản đồ — danh sách kết quả (map_screen + map_result_panel)', X(0), Y);
  add(s, [[appBar('Bản đồ', { large: true, top: 'Member' }), 'w']]);
  const { area, attr } = buildMap(s, false);
  const row = (ic, tone, name, sub, right, dist) => F('H', { name: 'PlaceRow', gap: 12, p: [10, 0], align: 'c' }, [iconTile(ic, tone, 40, 20), [F('V', { gap: 2 }, [[T(name, 'Title/S', 'ink', { lines: 1 }), 'w'], [T(sub, 'Caption', 'muted', { lines: 1 }), 'w']]), 'g'], F('V', { gap: 2, align: 'e' }, [right, T(dist, 'Caption', 'muted')])]);
  const panel = F('V', { name: 'ResultPanel', fill: 'surface', p: [8, 16, 8, 16], gap: 0, w: 390, shadow: 'Shadow/Bar' }, [
    [F('H', { just: 'c', p: [0, 0, 6, 0] }, [F('H', { fill: 'line', r: 99, w: 40, h: 4 })]), 'w'],
    [F('H', { gap: 8, align: 'c', p: [0, 0, 4, 0] }, [[F('V', {}, [T('Địa điểm quanh đây', 'Title/M', 'ink'), T('24 địa điểm', 'Caption', 'muted')]), 'g'], F('H', { fill: 'surface-2', r: 16, w: 32, h: 32, just: 'c', align: 'c' }, [I('close', 18, 'muted')])]), 'w'],
    [row('shopping_cart', 'brand', 'Gyomu Super Minami-Senju', 'Siêu thị · 2-14-3 Minami-Senju', T('★ 4.2 · 18 review', 'Label/S', 'lantern-text'), '350 m'), 'w'], [divider(), 'w'],
    [row('train', 'ai', 'Ga Minami-Senju', 'Ga tàu · JR Jōban, Hibiya, TX', T('★ 4.6 · 31 review', 'Label/S', 'lantern-text'), '520 m'), 'w'], [divider(), 'w'],
    [row('local_hospital', 'neutral', 'Phòng khám Senju', 'Phòng khám · OSM', badge('OSM', 'neutral'), '780 m'), 'w']]);
  panel.topLeftRadius = 24; panel.topRightRadius = 24;
  area.appendChild(panel); panel.x = 0; panel.y = area.height - panel.height;
  out.map = s.id; }
// 08 Map + summary sheet
{ const s = screen(SEC, '08 · Bản đồ — thẻ địa điểm (place_summary_sheet)', X(1), Y);
  add(s, [[appBar('Bản đồ', { large: true, top: 'Member' }), 'w']]);
  const { area } = buildMap(s, true);
  const sh = F('V', { name: 'PlaceSummarySheet', fill: 'surface', p: [8, 20, 20, 20], gap: 12, w: 390, shadow: 'Shadow/Bar' }, [
    [F('H', { just: 'c' }, [F('H', { fill: 'line', r: 99, w: 40, h: 4 })]), 'w'],
    F('H', { gap: 6 }, [badge('Siêu thị', 'brand', 'shopping_cart'), badge('Nhóm Senpai ơi thêm', 'ai', 'verified')]),
    [F('V', { gap: 2 }, [[T('Gyomu Super Minami-Senju', 'Display/M', 'ink'), 'w'], [T('業務スーパー 南千住店 · Gyomu Super', 'Body/S', 'muted'), 'w']]), 'w'],
    F('H', { gap: 8, align: 'c' }, [stars(4, 18), T('4.2 · 18 review', 'Label/M', 'ink'), T('·  350 m', 'Label/M', 'muted')]),
    [F('H', { name: 'tip', fill: 'lantern-soft', r: 12, p: [10, 12], gap: 8, align: 'c' }, [I('tips_and_updates', 18, 'lantern-text'), [T('“Thứ Ba rau giảm 20%, có góc đồ châu Á.” — Hà', 'Body/S', 'lantern-text'), 'g']]), 'w'],
    [F('H', { gap: 10 }, [[btn('Xem chi tiết', 'Primary', { size: 'M', icon: 'info' }), 'g'], [btn('Chỉ đường', 'Secondary', { size: 'M', icon: 'directions' }), 'g']]), 'w']]);
  sh.topLeftRadius = 24; sh.topRightRadius = 24;
  area.appendChild(sh); sh.x = 0; sh.y = area.height - sh.height;
  out.mapSheet = s.id; }
return out;
// ===== 016 =====
const AF = Object.getPrototypeOf(async function () {}).constructor;
const H = await new AF('figma', (await figma.getNodeByIdAsync('3:3')).characters)(figma);
const SEC = await figma.getNodeByIdAsync('4:316');
const removed = [];
for (const c of [...SEC.children]) if (c.type === 'FRAME' && /^0[78] ·/.test(c.name)) { removed.push(c.id); c.remove(); }
const { T, I, F, add, fill, stroke, badge, iconTile, btn, chips, stars, appBar, screen, nav, divider } = H;
const abs = (parent, n, x, y) => { parent.appendChild(n); n.x = x; n.y = y; return n; };
const X = k => 60 + k * 450, Y = 160;
const out = { removed };
const mapSvg = '<svg width="390" height="760" viewBox="0 0 390 760" fill="none" xmlns="http://www.w3.org/2000/svg"><rect width="390" height="760" fill="#F3EEE6"/><path d="M318 -10C262 130 340 240 288 380C246 490 338 620 300 770" stroke="#CFE3F2" stroke-width="48" stroke-linecap="round"/><rect x="22" y="400" width="140" height="120" rx="20" fill="#DDEBD3"/><rect x="186" y="110" width="74" height="86" rx="16" fill="#DDEBD3"/><rect x="40" y="640" width="90" height="70" rx="14" fill="#DDEBD3"/><path d="M0 150H390M0 600H390M60 0V760M222 0V760M0 460C120 450 260 480 390 440M0 330H220" stroke="#FFFFFF" stroke-width="6"/><path d="M-10 270C120 260 240 290 400 250" stroke="#FFFFFF" stroke-width="16"/><path d="M128 -10C138 220 106 460 146 770" stroke="#FFFFFF" stroke-width="13"/><path d="M-10 690C120 640 260 600 400 550" stroke="#B7BCD0" stroke-width="4" stroke-dasharray="10 6"/></svg>';
const pinReview = (ic, n, big) => { const sz = big ? 52 : 44; const p = F('H', { name: 'pin/review', fill: 'brand', r: sz / 2, w: sz, h: sz, just: 'c', align: 'c', stroke: 'surface', sw: 3, shadow: 'Shadow/Float' }, [I(ic, big ? 26 : 22, 'on-brand', true)]);
  const b = F('H', { name: 'count', fill: 'lantern', r: 99, p: [1, 6], stroke: 'surface', sw: 1.5 }, [T(n, 'Overline', 'ink')]); p.appendChild(b); b.layoutPositioning = 'ABSOLUTE'; b.x = sz - 18; b.y = -6; return p; };
const pinSmall = (ic) => F('H', { name: 'pin/none', fill: 'surface', r: 17, w: 34, h: 34, just: 'c', align: 'c', stroke: 'line', sw: 2 }, [I(ic, 18, 'muted')]);
const pinEvent = (label) => F('V', { name: 'pin/event', gap: 4, align: 'c' }, [F('H', { fill: 'lantern', r: 22, w: 44, h: 44, just: 'c', align: 'c', stroke: 'surface', sw: 3, shadow: 'Shadow/Card' }, [I('celebration', 22, 'ink', true)]), F('H', { fill: 'ink', r: 99, p: [2, 8] }, [T(label, 'Label/S', 'on-brand')])]);
const pinScam = (ic) => { const p = F('H', { name: 'pin/scam', fill: 'surface', r: 20, w: 40, h: 40, just: 'c', align: 'c', stroke: 'crit', sw: 2 }, [I(ic, 20, 'crit')]); const b = F('H', { fill: 'crit', r: 99, w: 18, h: 18, just: 'c', align: 'c' }, [T('!', 'Label/S', 'on-brand')]); p.appendChild(b); b.layoutPositioning = 'ABSOLUTE'; b.x = 26; b.y = -4; return p; };
const me = () => { const f = figma.createFrame(); f.name = 'me'; f.resize(44, 44); f.fills = []; const halo = figma.createEllipse(); halo.resize(44, 44); fill(halo, 'ink', 0.15); const d = figma.createEllipse(); d.resize(16, 16); fill(d, 'ink'); stroke(d, 'surface', 3); f.appendChild(halo); f.appendChild(d); d.x = 14; d.y = 14; return f; };
const fabSmall = (ic) => F('H', { name: 'mapFab', fill: 'surface', r: 14, w: 44, h: 44, just: 'c', align: 'c', shadow: 'Shadow/Card' }, [I(ic, 22, 'ink')]);
const buildMap = (s, sel) => {
  const area = figma.createFrame(); area.name = 'MapArea'; area.clipsContent = true; area.fills = []; add(s, [[area, 'wh']]);
  nav(s, 'Bản đồ');
  const m = figma.createNodeFromSvg(mapSvg); m.name = 'OSM tiles'; abs(area, m, 0, 0);
  const sbx = F('H', { name: 'search', fill: 'surface', r: 999, p: [0, 8, 0, 16], h: 48, gap: 10, align: 'c', w: 358, shadow: 'Shadow/Card' }, [I('search', 22, 'muted'), [T('Tìm địa điểm', 'Body/M', 'muted'), 'g'], F('H', { fill: 'brand-soft', r: 16, w: 32, h: 32, just: 'c', align: 'c' }, [I('tune', 18, 'brand-text')])]);
  abs(area, sbx, 16, 12);
  abs(area, chips([['Tất cả (86)', 'apps'], ['Siêu thị (24)', 'shopping_cart'], ['Ga tàu (12)', 'train'], ['Quán ăn (30)', 'restaurant']], 0), 16, 70);
  const evRow = F('H', { name: 'eventRow', fill: 'surface', r: 99, p: [4, 4, 4, 12], gap: 6, align: 'c', shadow: 'Shadow/Card' }, [I('celebration', 18, 'lantern-text'), T('Sự kiện:', 'Label/S', 'ink'), F('H', { fill: 'surface-2', r: 99, p: [4, 10] }, [T('Tắt', 'Label/S', 'muted')]), F('H', { fill: 'ink', r: 99, p: [4, 10] }, [T('15 ngày tới', 'Label/S', 'on-brand')]), F('H', { fill: 'surface-2', r: 99, p: [4, 10] }, [T('30 ngày tới', 'Label/S', 'muted')])]);
  abs(area, evRow, 16, 116);
  abs(area, fabSmall('my_location'), 330, 166); abs(area, fabSmall('info'), 330, 218);
  abs(area, pinReview('shopping_cart', '18', sel), 160, 300); abs(area, pinReview('restaurant', '9'), 54, 218); abs(area, pinReview('train', '31'), 236, 356);
  abs(area, pinSmall('local_hospital'), 92, 380); abs(area, pinSmall('account_balance'), 250, 236); abs(area, pinScam('real_estate_agent'), 40, 316);
  abs(area, pinEvent('Còn 7 ngày'), 262, 160); abs(area, me(), 176, 410);
  return area;
};
{ const s = screen(SEC, '07 · Bản đồ — danh sách kết quả (map_screen + map_result_panel)', X(0), Y);
  add(s, [[appBar('Bản đồ', { large: true, top: 'Member' }), 'w']]);
  const area = buildMap(s, false);
  const row = (ic, tone, name, sub, right, dist) => F('H', { name: 'PlaceRow', gap: 12, p: [10, 0], align: 'c' }, [iconTile(ic, tone, 40, 20), [F('V', { gap: 2 }, [[T(name, 'Title/S', 'ink', { lines: 1 }), 'w'], [T(sub, 'Caption', 'muted', { lines: 1 }), 'w']]), 'g'], F('V', { gap: 2, align: 'e' }, [right, T(dist, 'Caption', 'muted')])]);
  const panel = F('V', { name: 'ResultPanel', fill: 'surface', p: [8, 16, 8, 16], gap: 0, w: 390, shadow: 'Shadow/Bar' }, [
    [F('H', { just: 'c', p: [0, 0, 6, 0] }, [F('H', { fill: 'line', r: 99, w: 40, h: 4 })]), 'w'],
    [F('H', { gap: 8, align: 'c', p: [0, 0, 4, 0] }, [[F('V', {}, [T('Địa điểm quanh đây', 'Title/M', 'ink'), T('24 địa điểm', 'Caption', 'muted')]), 'g'], F('H', { fill: 'surface-2', r: 16, w: 32, h: 32, just: 'c', align: 'c' }, [I('close', 18, 'muted')])]), 'w'],
    [row('shopping_cart', 'brand', 'Gyomu Super Minami-Senju', 'Siêu thị · 2-14-3 Minami-Senju', T('★ 4.2 · 18 review', 'Label/S', 'lantern-text'), '350 m'), 'w'], [divider(), 'w'],
    [row('train', 'ai', 'Ga Minami-Senju', 'Ga tàu · JR Jōban, Hibiya, TX', T('★ 4.6 · 31 review', 'Label/S', 'lantern-text'), '520 m'), 'w'], [divider(), 'w'],
    [row('local_hospital', 'neutral', 'Phòng khám Senju', 'Phòng khám · OpenStreetMap', badge('OSM', 'neutral'), '780 m'), 'w']]);
  panel.topLeftRadius = 24; panel.topRightRadius = 24;
  abs(area, panel, 0, area.height - panel.height);
  out.map = s.id; }
{ const s = screen(SEC, '08 · Bản đồ — thẻ địa điểm (place_summary_sheet)', X(1), Y);
  add(s, [[appBar('Bản đồ', { large: true, top: 'Member' }), 'w']]);
  const area = buildMap(s, true);
  const sh = F('V', { name: 'PlaceSummarySheet', fill: 'surface', p: [8, 20, 20, 20], gap: 12, w: 390, shadow: 'Shadow/Bar' }, [
    [F('H', { just: 'c' }, [F('H', { fill: 'line', r: 99, w: 40, h: 4 })]), 'w'],
    F('H', { gap: 6 }, [badge('Siêu thị', 'brand', 'shopping_cart'), badge('Nhóm Senpai ơi thêm', 'ai', 'verified')]),
    [F('V', { gap: 2 }, [[T('Gyomu Super Minami-Senju', 'Display/M', 'ink'), 'w'], [T('業務スーパー 南千住店 · Gyomu Super', 'Body/S', 'muted'), 'w']]), 'w'],
    F('H', { gap: 8, align: 'c' }, [stars(4, 18), T('4.2 · 18 review', 'Label/M', 'ink'), T('·  350 m', 'Label/M', 'muted')]),
    [F('H', { name: 'tip', fill: 'lantern-soft', r: 12, p: [10, 12], gap: 8, align: 'c' }, [I('tips_and_updates', 18, 'lantern-text'), [T('“Thứ Ba rau giảm 20%, có góc đồ châu Á.” — Hà', 'Body/S', 'lantern-text'), 'g']]), 'w'],
    [F('H', { gap: 10 }, [[btn('Xem chi tiết', 'Primary', { size: 'M', icon: 'info' }), 'g'], [btn('Chỉ đường', 'Secondary', { size: 'M', icon: 'directions' }), 'g']]), 'w']]);
  sh.topLeftRadius = 24; sh.topRightRadius = 24;
  abs(area, sh, 0, area.height - sh.height);
  out.mapSheet = s.id; }
return out;