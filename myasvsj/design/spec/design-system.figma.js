// Design System của file Figma 'Senpai ơi – Mobile App Redesign': biến màu, kiểu chữ, hiệu ứng (phần 1)
const test = await figma.getNodeByIdAsync('1:2'); if (test) test.remove();
const p1 = figma.root.children[0]; p1.name = '📱 Màn hình';
const ds = figma.createPage(); ds.name = '🎨 Design System';

const hex = h => { h = h.replace('#',''); return { r: parseInt(h.slice(0,2),16)/255, g: parseInt(h.slice(2,4),16)/255, b: parseInt(h.slice(4,6),16)/255 }; };
const colors = {
  'bg':'#FBF4F3','surface':'#FFFFFF','surface-2':'#F8EEF0','ink':'#2F3E6E','muted':'#676E8A','line':'#EBDCE0',
  'brand':'#C2456E','brand-strong':'#A8365C','brand-soft':'#FCE9EF','brand-text':'#8E2B4E','on-brand':'#FFFFFF',
  'ai-soft':'#E6E9F4','lantern':'#E8A33C','lantern-soft':'#FDF0D8','lantern-text':'#7A4E00',
  'ok':'#2E7D5B','ok-soft':'#E1F2E9','warn':'#8A5800','warn-soft':'#FCEFD2','crit':'#B3261E','crit-soft':'#FBE1DF',
  'ink-deep':'#1E2A52','map-land':'#F3EEE6','map-park':'#DDEBD3','map-water':'#CFE3F2','map-road':'#FFFFFF'
};
const col = figma.variables.createVariableCollection('Senpai Color');
col.renameMode(col.modes[0].modeId, 'Light');
const mode = col.modes[0].modeId;
const varIds = {};
for (const [name, h] of Object.entries(colors)) {
  const v = figma.variables.createVariable(name, col, 'COLOR');
  v.setValueForMode(mode, hex(h));
  v.scopes = ['FRAME_FILL','SHAPE_FILL','TEXT_FILL','STROKE_COLOR','EFFECT_COLOR'];
  v.description = 'Web token --' + name + ' (' + h + ')';
  varIds[name] = v.id;
}

const fontsNeeded = [['Be Vietnam Pro','Regular'],['Be Vietnam Pro','Medium'],['Be Vietnam Pro','SemiBold'],['Be Vietnam Pro','Bold'],['Bricolage Grotesque','Bold'],['Bricolage Grotesque','ExtraBold'],['Zen Maru Gothic','Medium'],['Zen Maru Gothic','Bold']];
await Promise.all(fontsNeeded.map(([family, style]) => figma.loadFontAsync({ family, style })));
const ts = [
  ['Display/XL','Bricolage Grotesque','ExtraBold',30,36,-0.5],
  ['Display/L','Bricolage Grotesque','Bold',24,30,-0.3],
  ['Display/M','Bricolage Grotesque','Bold',20,26,-0.2],
  ['Title/M','Be Vietnam Pro','SemiBold',17,24,0],
  ['Title/S','Be Vietnam Pro','SemiBold',15,21,0],
  ['Body/M','Be Vietnam Pro','Regular',15,22,0],
  ['Body/S','Be Vietnam Pro','Regular',13,19,0],
  ['Label/M','Be Vietnam Pro','SemiBold',14,20,0],
  ['Label/S','Be Vietnam Pro','Medium',12,16,0],
  ['Caption','Be Vietnam Pro','Regular',12,16,0],
  ['Overline','Be Vietnam Pro','Bold',11,14,0.6],
  ['JP/L','Zen Maru Gothic','Bold',26,34,0],
  ['JP/M','Zen Maru Gothic','Medium',17,24,0],
];
const styleIds = {};
for (const [name, family, style, size, lh, ls] of ts) {
  const s = figma.createTextStyle(); s.name = name;
  s.fontName = { family, style }; s.fontSize = size;
  s.lineHeight = { unit: 'PIXELS', value: lh }; s.letterSpacing = { unit: 'PIXELS', value: ls };
  styleIds[name] = s.id;
}
const shadow = figma.createEffectStyle(); shadow.name = 'Shadow/Card';
shadow.effects = [{ type:'DROP_SHADOW', color:{ r:0.184, g:0.243, b:0.431, a:0.08 }, offset:{x:0,y:4}, radius:16, spread:0, visible:true, blendMode:'NORMAL' }];
const shadow2 = figma.createEffectStyle(); shadow2.name = 'Shadow/Float';
shadow2.effects = [{ type:'DROP_SHADOW', color:{ r:0.761, g:0.271, b:0.431, a:0.28 }, offset:{x:0,y:8}, radius:20, spread:0, visible:true, blendMode:'NORMAL' }];
const shadow3 = figma.createEffectStyle(); shadow3.name = 'Shadow/Bar';
shadow3.effects = [{ type:'DROP_SHADOW', color:{ r:0.184, g:0.243, b:0.431, a:0.06 }, offset:{x:0,y:-2}, radius:12, spread:0, visible:true, blendMode:'NORMAL' }];
return { pages: figma.root.children.map(p => ({ id: p.id, name: p.name })), collection: col.id, varCount: Object.keys(varIds).length, styleCount: Object.keys(styleIds).length, effects: [shadow.id, shadow2.id, shadow3.id] };
// ===== phần 2: thư viện helper (LIB) + component StatusBar, Button, Chip, TextField, Cover, Logo =====
const LIB = String.raw`const vars = await figma.variables.getLocalVariablesAsync('COLOR');
const V = {}; for (const v of vars) V[v.name] = v;
const tstyles = await figma.getLocalTextStylesAsync();
const S = {}; for (const s of tstyles) S[s.name] = s;
const estyles = await figma.getLocalEffectStylesAsync();
const E = {}; for (const s of estyles) E[s.name] = s;
const FONTS = [['Be Vietnam Pro','Regular'],['Be Vietnam Pro','Medium'],['Be Vietnam Pro','SemiBold'],['Be Vietnam Pro','Bold'],['Bricolage Grotesque','Bold'],['Bricolage Grotesque','ExtraBold'],['Material Symbols Rounded','Regular'],['Material Icons Round','Regular'],['Zen Maru Gothic','Medium'],['Zen Maru Gothic','Bold'],['Inter','Regular']];
await Promise.all(FONTS.map(f => figma.loadFontAsync({ family: f[0], style: f[1] })));
const dsPage = figma.root.children.find(p => p.name.indexOf('Design System') >= 0);
await dsPage.loadAsync();
const CM = {};
for (const c of dsPage.findAllWithCriteria({ types: ['COMPONENT', 'COMPONENT_SET'] })) {
  if (c.type === 'COMPONENT_SET' || !c.parent || c.parent.type !== 'COMPONENT_SET') CM[c.name] = c;
}
function paint(name, op) {
  const v = V[name]; if (!v) throw new Error('no color ' + name);
  const p = figma.variables.setBoundVariableForPaint({ type: 'SOLID', color: { r: 0, g: 0, b: 0 } }, 'color', v);
  return op == null ? p : Object.assign({}, p, { opacity: op });
}
function fill(n, name, op) { n.fills = name ? [paint(name, op)] : []; return n; }
function stroke(n, name, w, align) { n.strokes = [paint(name)]; n.strokeWeight = w || 1; n.strokeAlign = align || 'INSIDE'; return n; }
function T(str, style, color, o) {
  o = o || {};
  const t = figma.createText();
  t.textStyleId = S[style || 'Body/M'].id;
  t.characters = String(str);
  fill(t, color || 'ink');
  t.name = o.name || String(str).slice(0, 24);
  if (o.align) t.textAlignHorizontal = o.align;
  if (o.w) { t.resize(o.w, t.height); t.textAutoResize = 'HEIGHT'; }
  if (o.lines) { t.textAutoResize = o.w ? 'HEIGHT' : t.textAutoResize; t.maxLines = o.lines; t.textTruncation = 'ENDING'; }
  if (o.deco) t.textDecoration = o.deco;
  if (o.size) t.fontSize = o.size;
  return t;
}
function I(name, size, color, filled) {
  size = size || 24;
  const t = figma.createText();
  t.fontName = { family: filled ? 'Material Icons Round' : 'Material Symbols Rounded', style: 'Regular' };
  t.characters = name; t.fontSize = size;
  t.lineHeight = { unit: 'PIXELS', value: size };
  t.textAlignHorizontal = 'CENTER'; t.textAlignVertical = 'CENTER';
  t.textAutoResize = 'NONE'; t.resize(size, size);
  fill(t, color || 'ink'); t.name = 'icon/' + name;
  return t;
}
function pad(f, p) {
  const a = Array.isArray(p) ? p : [p];
  const q = a.length === 1 ? [a[0], a[0], a[0], a[0]] : a.length === 2 ? [a[0], a[1], a[0], a[1]] : a;
  f.paddingTop = q[0]; f.paddingRight = q[1]; f.paddingBottom = q[2]; f.paddingLeft = q[3];
}
function add(parent, kids) {
  for (const k of kids || []) {
    if (!k) continue;
    const n = Array.isArray(k) ? k[0] : k; const fl = Array.isArray(k) ? (k[1] || '') : '';
    if (!n) continue;
    parent.appendChild(n);
    const horiz = parent.layoutMode === 'HORIZONTAL';
    if (fl.indexOf('w') >= 0 || (fl.indexOf('g') >= 0 && horiz)) { if (n.type === 'TEXT') n.textAutoResize = 'HEIGHT'; n.layoutSizingHorizontal = 'FILL'; }
    if (fl.indexOf('h') >= 0 || (fl.indexOf('g') >= 0 && !horiz)) n.layoutSizingVertical = 'FILL';
  }
  return parent;
}
function F(dir, o, kids) {
  o = o || {};
  const f = figma.createAutoLayout(dir === 'H' ? 'HORIZONTAL' : 'VERTICAL');
  f.name = o.name || (dir === 'H' ? 'Row' : 'Col');
  fill(f, o.fill || null, o.op);
  if (o.p != null) pad(f, o.p);
  f.itemSpacing = o.gap || 0;
  if (o.r != null) f.cornerRadius = o.r;
  if (o.stroke) stroke(f, o.stroke, o.sw || 1);
  if (o.align) f.counterAxisAlignItems = o.align === 'c' ? 'CENTER' : o.align === 'e' ? 'MAX' : o.align === 'b' ? 'BASELINE' : 'MIN';
  if (o.just) f.primaryAxisAlignItems = o.just === 'c' ? 'CENTER' : o.just === 'e' ? 'MAX' : o.just === 'sb' ? 'SPACE_BETWEEN' : 'MIN';
  if (o.wrap) { f.layoutWrap = 'WRAP'; f.counterAxisSpacing = o.rowGap != null ? o.rowGap : (o.gap || 0); }
  if (o.w || o.h) {
    f.resize(o.w || f.width, o.h || f.height);
    f.layoutSizingHorizontal = o.w ? 'FIXED' : 'HUG';
    f.layoutSizingVertical = o.h ? 'FIXED' : 'HUG';
  }
  if (o.clip != null) f.clipsContent = o.clip; else f.clipsContent = false;
  if (o.shadow) f.effectStyleId = E[o.shadow === true ? 'Shadow/Card' : o.shadow].id;
  if (o.opacity != null) f.opacity = o.opacity;
  add(f, kids);
  return f;
}
function grow(n) { n.layoutGrow = 1; return n; }
function abs(parent, n, x, y) { parent.appendChild(n); n.layoutPositioning = 'ABSOLUTE'; n.x = x; n.y = y; return n; }
function inst(name, props) {
  const c = CM[name]; if (!c) throw new Error('no component ' + name);
  const base = c.type === 'COMPONENT_SET' ? c.defaultVariant : c;
  const i = base.createInstance();
  if (props && c.type === 'COMPONENT_SET') i.setProperties(props);
  return i;
}
function setText(root, layerName, str) {
  const t = root.findOne(n => n.type === 'TEXT' && n.name === layerName);
  if (t) t.characters = String(str);
  return t;
}
function sp(h, w) { const f = figma.createFrame(); f.name = 'spacer'; f.fills = []; f.resize(w || 1, h || 1); return f; }
function divider(color) { const r = figma.createRectangle(); r.name = 'divider'; r.resize(10, 1); fill(r, color || 'line'); return r; }
function dot(size, color) { const e = figma.createEllipse(); e.resize(size, size); fill(e, color); e.name = 'dot'; return e; }
const TONES = { brand: ['brand-soft', 'brand-text'], lantern: ['lantern-soft', 'lantern-text'], ok: ['ok-soft', 'ok'], warn: ['warn-soft', 'warn'], crit: ['crit-soft', 'crit'], ai: ['ai-soft', 'ink'], neutral: ['surface-2', 'muted'], solid: ['brand', 'on-brand'], ink: ['ink', 'on-brand'] };
function badge(text, tone, icon) {
  const t = TONES[tone || 'brand'];
  const kids = [];
  if (icon) kids.push(I(icon, 14, t[1]));
  kids.push(T(text, 'Label/S', t[1]));
  return F('H', { name: 'badge', fill: t[0], p: [3, 8], r: 999, gap: 4, align: 'c' }, kids);
}
function avatar(initials, size, tone) {
  size = size || 40;
  const t = TONES[tone || 'brand'];
  const f = F('H', { name: 'avatar', fill: t[0], r: size / 2, w: size, h: size, just: 'c', align: 'c' }, [T(initials, size >= 56 ? 'Display/M' : (size >= 36 ? 'Label/M' : 'Label/S'), t[1])]);
  return f;
}
function iconTile(icon, tone, size, r) {
  size = size || 40; const t = TONES[tone || 'brand'];
  return F('H', { name: 'iconTile', fill: t[0], r: r != null ? r : 12, w: size, h: size, just: 'c', align: 'c' }, [I(icon, Math.round(size * 0.55), t[1])]);
}
function card(o, kids) { o = Object.assign({ fill: 'surface', r: 16, stroke: 'line', p: 14, gap: 10, name: 'card' }, o || {}); return F('V', o, kids); }
function btn(label, kind, o) {
  o = o || {};
  const i = inst('Button', { Kind: kind || 'Primary', Size: o.size || 'L' });
  setText(i, 'label', label);
  const ic = i.findOne(n => n.name === 'leading');
  if (ic && ic.type === 'TEXT') { if (o.icon) { ic.characters = o.icon; ic.visible = true; } else ic.visible = false; }
  return i;
}
function chip(label, on, icon) {
  const i = inst('Chip', { State: on ? 'On' : 'Off' });
  setText(i, 'label', label);
  const ic = i.findOne(n => n.name === 'leading');
  if (ic && ic.type === 'TEXT') { if (icon) { ic.characters = icon; ic.visible = true; } else ic.visible = false; }
  return i;
}
function chips(items, activeIdx, o) {
  o = o || {};
  return F('H', { name: 'chips', gap: 8, wrap: o.wrap, rowGap: 8 }, items.map((s, i) => chip(Array.isArray(s) ? s[0] : s, i === activeIdx || (o.multi && o.multi.indexOf(i) >= 0), Array.isArray(s) ? s[1] : null)));
}
function field(label, value, o) {
  o = o || {};
  const i = inst('TextField', { State: o.state || 'Default' });
  setText(i, 'value', value);
  const v = i.findOne(n => n.name === 'value');
  if (o.placeholder && v) fill(v, 'muted');
  const lead = i.findOne(n => n.name === 'leading'); const trail = i.findOne(n => n.name === 'trailing');
  if (lead && lead.type === 'TEXT') { if (o.icon) { lead.characters = o.icon; lead.visible = true; } else lead.visible = false; }
  if (trail && trail.type === 'TEXT') { if (o.trail) { trail.characters = o.trail; trail.visible = true; } else trail.visible = false; }
  if (o.multiline) { i.resize(i.width, o.multiline); }
  const kids = [];
  if (label) kids.push(T(label, 'Label/M', 'ink'));
  kids.push([i, 'w']);
  if (o.help) kids.push([T(o.help, 'Caption', o.state === 'Error' ? 'crit' : 'muted'), 'w']);
  return F('V', { name: 'field', gap: 6 }, kids);
}
function search(ph, o) {
  o = o || {};
  return F('H', { name: 'search', fill: o.fill || 'surface', stroke: o.noStroke ? null : 'line', r: 999, p: [0, 16], h: o.h || 48, gap: 10, align: 'c' }, [I('search', 22, 'muted'), [T(ph, 'Body/M', 'muted', { lines: 1 }), 'g'], o.trail ? I(o.trail, 22, 'brand') : null]);
}
function seg(items, active, o) {
  o = o || {};
  return F('H', { name: 'segmented', fill: 'surface-2', r: 999, p: 4, gap: 4 }, items.map((s, i) => [F('H', { name: 'seg', fill: i === active ? 'surface' : null, r: 999, p: [8, 12], just: 'c', align: 'c', shadow: i === active ? 'Shadow/Card' : null, gap: 6 }, [T(s, 'Label/M', i === active ? 'brand-text' : 'muted')]), 'g']));
}
function tabs(items, active) {
  return F('H', { name: 'tabs', gap: 20, p: [0, 16] }, items.map((s, i) => F('V', { name: 'tab', gap: 8, align: 'c' }, [T(s, 'Label/M', i === active ? 'brand-text' : 'muted'), F('H', { name: 'ind', fill: i === active ? 'brand' : null, r: 2, w: 24, h: 3 })])));
}
function stars(n, size, color) {
  size = size || 16; const kids = [];
  for (let k = 1; k <= 5; k++) kids.push(I(n >= k ? 'star' : (n >= k - 0.5 ? 'star_half' : 'star_border'), size, color || 'lantern', true));
  return F('H', { name: 'stars', gap: 1 }, kids);
}
function progress(pct, total, color, track, hgt) {
  hgt = hgt || 8;
  const tr = F('H', { name: 'progress', fill: track || 'surface-2', r: 99, h: hgt, w: total, clip: true });
  tr.appendChild(F('H', { name: 'bar', fill: color || 'brand', r: 99, h: hgt, w: Math.max(hgt, Math.round(total * pct / 100)) }));
  return tr;
}
function textarea(label, value, hgt, o) {
  o = o || {};
  const box = F('V', { name: 'textarea', fill: 'surface', stroke: o.focus ? 'brand' : 'line', sw: o.focus ? 2 : 1, r: 12, p: [12, 14], h: hgt || 120, gap: 6 }, [[T(value, 'Body/M', o.placeholder ? 'muted' : 'ink'), 'w']]);
  const kids = [];
  if (label) kids.push(T(label, 'Label/M', 'ink'));
  kids.push([box, 'w']);
  if (o.help) kids.push([F('H', { name: 'help', just: 'sb' }, [T(o.help, 'Caption', 'muted'), o.count ? T(o.count, 'Caption', 'muted') : null]), 'w']);
  return F('V', { name: 'field', gap: 6 }, kids);
}
function toggle(on) {
  const f = F('H', { name: 'switch', fill: on ? 'brand' : 'line', r: 99, w: 44, h: 26, p: 3, align: 'c', just: on ? 'e' : 'MIN' }, [F('H', { name: 'knob', fill: 'surface', r: 99, w: 20, h: 20 })]);
  return f;
}
function sectionHead(title, action, icon) {
  return F('H', { name: 'sectionHead', gap: 8, align: 'c' }, [icon ? I(icon, 20, 'brand') : null, [T(title, 'Title/M', 'ink'), 'g'], action ? F('H', { name: 'more', gap: 2, align: 'c' }, [T(action, 'Label/M', 'brand-text'), I('chevron_right', 18, 'brand-text')]) : null]);
}
function listRow(icon, title, sub, o) {
  o = o || {};
  const left = icon ? (typeof icon === 'string' ? iconTile(icon, o.tone || 'brand', 40) : icon) : null;
  const txt = F('V', { name: 'texts', gap: 2 }, [[T(title, o.titleStyle || 'Title/S', o.titleColor || 'ink'), 'w'], sub ? [T(sub, 'Body/S', 'muted', { lines: o.lines || 2 }), 'w'] : null]);
  const trail = o.trail === false ? null : (o.trail && typeof o.trail !== 'string' ? o.trail : I(o.trail || 'chevron_right', 22, 'muted'));
  return F('H', { name: 'listRow', gap: 12, align: 'c', p: o.p != null ? o.p : [12, 0], fill: o.fill || null, r: o.r }, [left, [txt, 'g'], trail]);
}
function group(rows, o) {
  o = o || {};
  const g = F('V', { name: 'group', fill: 'surface', r: 16, stroke: 'line', p: [4, 14] });
  rows.forEach((r, i) => { if (i > 0) add(g, [[divider(), 'w']]); add(g, [[r, 'w']]); });
  return g;
}
function cover(kind, w, h, r) {
  const f = figma.createFrame(); f.name = 'cover/' + kind; f.resize(w, h); f.clipsContent = true; f.cornerRadius = r || 0; f.fills = [];
  const c = inst('Cover', { Scene: kind });
  const s = Math.max(w / 320, h / 180);
  c.rescale(s);
  f.appendChild(c); c.x = (w - c.width) / 2; c.y = (h - c.height) / 2;
  return f;
}
function appBar(title, o) {
  o = o || {};
  const acts = (o.actions || []).map(a => F('H', { name: 'action', w: 40, h: 40, r: 20, just: 'c', align: 'c', fill: o.actionFill || null }, [I(a, 24, 'ink')]));
  if (o.large) {
    return F('V', { name: 'AppBar/Large', p: [8, 16, 8, 16], gap: 2, fill: o.fill || null }, [
      [F('H', { name: 'row', gap: 4, align: 'c' }, [[F('V', { name: 'titles', gap: 0 }, [o.over ? T(o.over, 'Overline', 'brand') : null, [T(title, 'Display/L', 'ink'), 'w']]), 'g']].concat(acts)), 'w']
    ]);
  }
  const back = o.back === false ? null : F('H', { name: 'back', w: 40, h: 40, r: 20, just: 'c', align: 'c' }, [I(o.close ? 'close' : 'arrow_back', 24, 'ink')]);
  const titles = F('V', { name: 'titles', gap: 0 }, [[T(title, 'Title/M', 'ink', { lines: 1 }), 'w'], o.sub ? [T(o.sub, 'Caption', 'muted', { lines: 1 }), 'w'] : null]);
  return F('H', { name: 'AppBar', p: [4, 8, 4, 4], h: 56, gap: 4, align: 'c', fill: o.fill || null }, [back, [titles, 'g']].concat(acts));
}
function screen(parent, name, x, y, o) {
  o = o || {};
  const s = figma.createFrame(); s.name = name; s.resize(390, 844); fill(s, o.bg || 'bg'); s.clipsContent = true;
  s.layoutMode = 'VERTICAL'; s.primaryAxisSizingMode = 'FIXED'; s.counterAxisSizingMode = 'FIXED'; s.itemSpacing = 0;
  parent.appendChild(s); s.x = x; s.y = y;
  const sb = inst('StatusBar', { Tone: o.dark ? 'Dark' : 'Light' });
  add(s, [[sb, 'w']]);
  return s;
}
function body(s, o, kids) {
  o = Object.assign({ name: 'Body', p: [8, 16, 24, 16], gap: 16, clip: true }, o || {});
  const b = F('V', o, kids);
  add(s, [[b, 'wh']]);
  return b;
}
function nav(s, active) {
  const n = inst('BottomNav', { Active: active });
  add(s, [[n, 'w']]);
  return n;
}
function fab(s, icon, label) {
  const f = F('H', { name: 'FAB', fill: 'brand', r: 18, p: label ? [0, 20, 0, 16] : 0, h: 56, w: label ? null : 56, gap: 8, align: 'c', just: 'c', shadow: 'Shadow/Float' }, [I(icon, 24, 'on-brand'), label ? T(label, 'Label/M', 'on-brand') : null]);
  s.appendChild(f); f.layoutPositioning = 'ABSOLUTE';
  f.x = 390 - 16 - f.width; f.y = s.height - (s.findChild(n => n.name === 'BottomNav') ? 80 : 34) - 16 - f.height;
  return f;
}
function bottomBar(s, kids, o) {
  o = o || {};
  const b = F('H', { name: 'BottomBar', fill: 'surface', p: [12, 16, 28, 16], gap: 12, align: 'c', shadow: 'Shadow/Bar' }, kids);
  add(s, [[b, 'w']]);
  return b;
}
function sheet(s, h, kids, o) {
  o = o || {};
  const scrim = figma.createRectangle(); scrim.name = 'scrim'; scrim.resize(390, 844); fill(scrim, 'ink-deep', 0.45);
  s.appendChild(scrim); scrim.layoutPositioning = 'ABSOLUTE'; scrim.x = 0; scrim.y = 0;
  const sh = F('V', { name: 'BottomSheet', fill: 'surface', p: [10, 20, 32, 20], gap: 16, w: 390, h: h });
  sh.topLeftRadius = 24; sh.topRightRadius = 24;
  add(sh, [[F('H', { name: 'handle-row', just: 'c' }, [F('H', { name: 'handle', fill: 'line', r: 99, w: 40, h: 4 })]), 'w']]);
  add(sh, kids);
  s.appendChild(sh); sh.layoutPositioning = 'ABSOLUTE'; sh.x = 0; sh.y = 844 - h;
  return sh;
}
function photo(kind, w, h, r) { return cover(kind, w, h, r); }
return { V, S, E, CM, paint, fill, stroke, T, I, F, add, grow, abs, inst, setText, sp, divider, dot, badge, avatar, iconTile, card, btn, chip, chips, field, search, seg, tabs, stars, progress, textarea, toggle, sectionHead, listRow, group, cover, photo, appBar, screen, body, nav, fab, bottomBar, sheet, TONES };
`;
const ds = await figma.getNodeByIdAsync('2:2');
await figma.setCurrentPageAsync(ds);
await figma.loadFontAsync({ family: 'Inter', style: 'Regular' });
const holder = figma.createFrame(); holder.name = '__lib (helper – sẽ xoá)'; holder.resize(400, 100); ds.appendChild(holder); holder.x = -3000; holder.y = 0;
const lt = figma.createText(); lt.characters = LIB; lt.name = 'lib'; lt.fontSize = 4; holder.appendChild(lt); holder.visible = false;
const AF = Object.getPrototypeOf(async function () {}).constructor;
const H = await new AF('figma', LIB)(figma);
const { T, I, F } = H;
const comp = (frame, name) => { const c = figma.createComponentFromNode(frame); c.name = name; return c; };
const layoutSet = (set, w, gap) => { set.layoutMode = 'HORIZONTAL'; set.layoutWrap = 'WRAP'; set.itemSpacing = gap; set.counterAxisSpacing = gap; set.paddingTop = set.paddingBottom = set.paddingLeft = set.paddingRight = 24; set.counterAxisAlignItems = 'CENTER'; set.resize(w, 100); set.primaryAxisSizingMode = 'FIXED'; set.counterAxisSizingMode = 'AUTO'; };
const X0 = 1600; let y = 0; const ids = {};
const place = (n) => { n.x = X0; n.y = y; y += n.height + 120; ids[n.name] = n.id; };

// StatusBar
const sbs = ['Light', 'Dark'].map(tone => { const col = tone === 'Dark' ? 'on-brand' : 'ink';
  const f = F('H', { name: 'sb', p: [0, 24, 0, 28], h: 44, w: 390, just: 'sb', align: 'c' }, [T('9:41', 'Label/M', col, { name: 'time' }), F('H', { name: 'icons', gap: 5, align: 'c' }, [I('signal_cellular_alt', 18, col), I('wifi', 18, col), I('battery_full', 18, col)])]);
  if (tone === 'Dark') H.fill(f, 'ink'); return comp(f, 'Tone=' + tone); });
const sbSet = figma.combineAsVariants(sbs, ds); sbSet.name = 'StatusBar'; layoutSet(sbSet, 438, 16); place(sbSet);
sbSet.description = 'Thanh trạng thái hệ thống. Light trên nền sáng, Dark trên ảnh/nền tối.';

// Button
const kinds = { Primary: ['brand', 'on-brand', null], Secondary: ['surface', 'ink', 'line'], Soft: ['brand-soft', 'brand-text', null], Ghost: [null, 'brand-text', null], Danger: ['crit', 'on-brand', null] };
const sizes = { L: [52, 22, 'Label/M', 14, 20], M: [44, 18, 'Label/M', 12, 18], S: [34, 14, 'Label/S', 10, 16] };
const btns = [];
for (const k in kinds) for (const s in sizes) { const [bg, fg, st] = kinds[k]; const [h, px, ts, r, ic] = sizes[s];
  const lead = I('arrow_forward', ic, fg); lead.name = 'leading';
  const f = F('H', { name: 'b', fill: bg, stroke: st, sw: 1.5, p: [0, px], h: h, r: r, gap: 8, just: 'c', align: 'c' }, [lead, T('Nút bấm', ts, fg, { name: 'label' })]);
  btns.push(comp(f, 'Kind=' + k + ', Size=' + s)); }
const bSet = figma.combineAsVariants(btns, ds); bSet.name = 'Button'; layoutSet(bSet, 560, 16); place(bSet);
bSet.description = 'Nút chính. Primary = hành động chính (màu brand #C2456E), Secondary = viền, Soft = nền hồng nhạt, Ghost = chữ, Danger = xoá.';

// Chip
const chipsArr = ['Off', 'On'].map(st => { const on = st === 'On'; const fg = on ? 'on-brand' : 'ink';
  const lead = I('check', 18, fg); lead.name = 'leading';
  const f = F('H', { name: 'c', fill: on ? 'brand' : 'surface', stroke: on ? null : 'line', p: [0, 14], h: 36, r: 999, gap: 6, align: 'c' }, [lead, T('Nhãn', 'Label/M', fg, { name: 'label' })]);
  return comp(f, 'State=' + st); });
const cSet = figma.combineAsVariants(chipsArr, ds); cSet.name = 'Chip'; layoutSet(cSet, 300, 16); place(cSet);
cSet.description = 'Chip lọc / chọn chủ đề. On = đang chọn.';

// TextField
const tfs = { Default: ['line', 1, 'muted', 'surface'], Focus: ['brand', 2, 'brand', 'surface'], Error: ['crit', 1.5, 'crit', 'surface'], Disabled: ['line', 1, 'muted', 'surface-2'] };
const tfArr = Object.keys(tfs).map(st => { const [sc, sw, icc, bg] = tfs[st];
  const lead = I('mail', 22, icc); lead.name = 'leading'; const trail = I('visibility', 22, 'muted'); trail.name = 'trailing';
  const f = F('H', { name: 't', fill: bg, stroke: sc, sw: sw, r: 12, p: [0, 14], h: 52, w: 326, gap: 10, align: 'c' }, [lead, [T('Nội dung', 'Body/M', st === 'Disabled' ? 'muted' : 'ink', { name: 'value' }), 'g'], trail]);
  return comp(f, 'State=' + st); });
const tSet = figma.combineAsVariants(tfArr, ds); tSet.name = 'TextField'; layoutSet(tSet, 724, 16); place(tSet);
tSet.description = 'Ô nhập liệu cao 52, bo 12. Focus viền brand 2px.';

// Covers
const W = '<svg width="320" height="180" viewBox="0 0 320 180" fill="none" xmlns="http://www.w3.org/2000/svg">';
const flower = (x, yy, s, c) => '<g transform="translate(' + x + ' ' + yy + ') scale(' + s + ')"><circle cx="0" cy="-11" r="7" fill="' + c + '"/><circle cx="10.5" cy="-3.4" r="7" fill="' + c + '"/><circle cx="6.5" cy="9" r="7" fill="' + c + '"/><circle cx="-6.5" cy="9" r="7" fill="' + c + '"/><circle cx="-10.5" cy="-3.4" r="7" fill="' + c + '"/><circle r="4.5" fill="#E8A33C"/></g>';
const lantern = (x, yy, c) => '<rect x="' + (x - 6) + '" y="' + (yy - 22) + '" width="12" height="5" rx="1" fill="#1E2A52"/><ellipse cx="' + x + '" cy="' + yy + '" rx="14" ry="18" fill="' + c + '"/><rect x="' + (x - 6) + '" y="' + (yy + 16) + '" width="12" height="5" rx="1" fill="#1E2A52"/><circle cx="' + x + '" cy="' + yy + '" r="26" fill="' + c + '" opacity=".18"/>';
const scenes = {
  Fuji: W + '<defs><linearGradient id="a" x1="0" y1="0" x2="0" y2="180" gradientUnits="userSpaceOnUse"><stop stop-color="#FCE9EF"/><stop offset="1" stop-color="#FDF0D8"/></linearGradient></defs><rect width="320" height="180" fill="url(#a)"/><circle cx="238" cy="56" r="24" fill="#E8A33C"/><path d="M36 180L160 60L284 180Z" fill="#2F3E6E"/><path d="M160 60L191 90L178 84L168 95L158 84L146 93L129 90Z" fill="#FFFFFF"/><path d="M0 152C60 136 110 140 160 154C210 166 270 150 320 142V180H0Z" fill="#C2456E"/><path d="M0 166C70 156 130 170 200 168C250 166 290 160 320 162V180H0Z" fill="#A8365C"/><circle cx="60" cy="40" r="3" fill="#C2456E" opacity=".5"/><circle cx="96" cy="64" r="2" fill="#C2456E" opacity=".5"/><circle cx="276" cy="100" r="2.5" fill="#C2456E" opacity=".5"/></svg>',
  Torii: W + '<defs><linearGradient id="b" x1="0" y1="0" x2="0" y2="180" gradientUnits="userSpaceOnUse"><stop stop-color="#E6E9F4"/><stop offset="1" stop-color="#FCE9EF"/></linearGradient></defs><rect width="320" height="180" fill="url(#b)"/><circle cx="252" cy="48" r="18" fill="#FFFFFF" opacity=".85"/><rect y="152" width="320" height="28" fill="#F8EEF0"/><path d="M84 46C130 36 190 36 236 46L232 58C190 50 130 50 88 58Z" fill="#2F3E6E"/><path d="M92 58H228V66H92Z" fill="#C2456E"/><rect x="104" y="84" width="112" height="9" rx="2" fill="#C2456E"/><rect x="116" y="66" width="12" height="88" fill="#C2456E"/><rect x="192" y="66" width="12" height="88" fill="#C2456E"/><rect x="154" y="66" width="12" height="18" fill="#A8365C"/><rect x="112" y="148" width="20" height="6" rx="2" fill="#2F3E6E"/><rect x="188" y="148" width="20" height="6" rx="2" fill="#2F3E6E"/>' + flower(40, 40, 0.8, '#E07A9B') + flower(286, 120, 0.7, '#E07A9B') + '</svg>',
  Sakura: W + '<rect width="320" height="180" fill="#FCE9EF"/><path d="M-10 30C60 40 110 70 150 110C180 140 230 150 330 150" stroke="#2F3E6E" stroke-width="7" stroke-linecap="round"/><path d="M90 58C110 40 130 34 160 36" stroke="#2F3E6E" stroke-width="4" stroke-linecap="round"/><path d="M190 140C210 120 230 112 262 112" stroke="#2F3E6E" stroke-width="4" stroke-linecap="round"/>' + flower(60, 40, 1, '#C2456E') + flower(122, 74, 1.3, '#E07A9B') + flower(166, 36, 0.9, '#C2456E') + flower(152, 116, 1.1, '#E07A9B') + flower(222, 142, 1.2, '#C2456E') + flower(264, 108, 0.9, '#E07A9B') + '<ellipse cx="250" cy="40" rx="4" ry="6" fill="#E07A9B"/><ellipse cx="290" cy="64" rx="3" ry="5" fill="#C2456E"/><ellipse cx="40" cy="120" rx="4" ry="6" fill="#E07A9B"/><ellipse cx="90" cy="150" rx="3" ry="5" fill="#C2456E"/></svg>',
  City: W + '<defs><linearGradient id="c" x1="0" y1="0" x2="0" y2="180" gradientUnits="userSpaceOnUse"><stop stop-color="#FDF0D8"/><stop offset="1" stop-color="#FCE9EF"/></linearGradient></defs><rect width="320" height="180" fill="url(#c)"/><circle cx="72" cy="58" r="22" fill="#E8A33C" opacity=".9"/><path d="M0 110H30V80H54V100H80V70H104V96H130V84H160V110H230V76H256V94H286V64H320V180H0Z" fill="#D9DDEE"/><path d="M200 26L184 160H216Z" fill="#C2456E"/><rect x="190" y="84" width="20" height="5" fill="#FFFFFF"/><rect x="188" y="112" width="24" height="5" fill="#FFFFFF"/><path d="M0 130H24V104H52V124H70V94H98V130H124V112H150V140H176V160H230V118H262V132H290V108H320V180H0Z" fill="#2F3E6E"/><rect x="32" y="112" width="6" height="6" fill="#E8A33C"/><rect x="78" y="104" width="6" height="6" fill="#E8A33C"/><rect x="86" y="118" width="6" height="6" fill="#E8A33C"/><rect x="240" y="128" width="6" height="6" fill="#E8A33C"/><rect x="298" y="118" width="6" height="6" fill="#E8A33C"/><rect y="164" width="320" height="16" fill="#1E2A52"/></svg>',
  Food: W + '<rect width="320" height="180" fill="#FDF0D8"/><circle cx="160" cy="104" r="80" fill="#FCE9EF"/><path d="M130 56C122 44 138 36 130 24M160 52C152 40 168 32 160 20M190 56C182 44 198 36 190 24" stroke="#FFFFFF" stroke-width="4" stroke-linecap="round"/><path d="M80 94H240C240 138 204 162 160 162C116 162 80 138 80 94Z" fill="#C2456E"/><circle cx="120" cy="124" r="5" fill="#FFFFFF" opacity=".6"/><circle cx="160" cy="134" r="5" fill="#FFFFFF" opacity=".6"/><circle cx="200" cy="124" r="5" fill="#FFFFFF" opacity=".6"/><rect x="76" y="86" width="168" height="10" rx="5" fill="#A8365C"/><ellipse cx="160" cy="88" rx="80" ry="9" fill="#E8A33C"/><rect x="194" y="62" width="18" height="30" rx="2" fill="#2F3E6E"/><ellipse cx="134" cy="86" rx="15" ry="8" fill="#FFFFFF"/><circle cx="134" cy="86" r="5" fill="#F5C26B"/><path d="M214 28L118 86M232 34L130 90" stroke="#2F3E6E" stroke-width="5" stroke-linecap="round"/></svg>',
  Park: W + '<rect width="320" height="180" fill="#E1F2E9"/><circle cx="252" cy="48" r="20" fill="#FDF0D8"/><path d="M0 128C60 98 120 98 180 122C230 142 280 118 320 108V180H0Z" fill="#9CCBB0"/><rect x="66" y="96" width="8" height="34" fill="#7A4E00"/><circle cx="70" cy="88" r="22" fill="#2E7D5B"/><rect x="118" y="104" width="8" height="34" fill="#7A4E00"/><circle cx="122" cy="94" r="24" fill="#E07A9B"/><rect x="226" y="100" width="8" height="30" fill="#7A4E00"/><circle cx="230" cy="92" r="20" fill="#2E7D5B"/><path d="M0 150C80 136 160 150 240 146C280 144 300 140 320 140V180H0Z" fill="#2E7D5B"/><path d="M150 180C160 160 190 150 240 146" stroke="#FDF0D8" stroke-width="10" stroke-linecap="round"/></svg>',
  Festival: W + '<rect width="320" height="180" fill="#2F3E6E"/><circle cx="250" cy="30" r="2" fill="#FFFFFF"/><circle cx="40" cy="20" r="1.5" fill="#FFFFFF"/><circle cx="150" cy="16" r="1.5" fill="#FFFFFF"/><circle cx="292" cy="80" r="1.5" fill="#FFFFFF"/><circle cx="250" cy="118" r="28" stroke="#E8A33C" stroke-width="2" stroke-dasharray="3 6" opacity=".7"/><circle cx="64" cy="122" r="20" stroke="#E07A9B" stroke-width="2" stroke-dasharray="3 6" opacity=".7"/><path d="M0 40C80 70 240 70 320 40" stroke="#E6E9F4" stroke-width="2" opacity=".6"/>' + lantern(40, 72, '#C2456E') + lantern(100, 81, '#E8A33C') + lantern(160, 84, '#C2456E') + lantern(220, 81, '#E8A33C') + lantern(280, 72, '#C2456E') + '<path d="M0 180V160C20 150 30 162 44 154C60 146 70 160 86 152C104 144 112 158 130 150C150 142 160 156 178 150C196 144 206 158 224 150C240 144 254 156 270 150C290 142 302 156 320 150V180Z" fill="#1E2A52"/></svg>',
  Study: W + '<rect width="320" height="180" fill="#E6E9F4"/><circle cx="270" cy="40" r="44" fill="#FCE9EF"/><rect x="60" y="60" width="22" height="80" rx="3" fill="#C2456E"/><rect x="84" y="50" width="18" height="90" rx="3" fill="#E8A33C"/><rect x="104" y="66" width="24" height="74" rx="3" fill="#2E7D5B"/><rect x="130" y="56" width="16" height="84" rx="3" fill="#8E2B4E"/><path d="M150 140L178 66L194 72L166 146Z" fill="#2F3E6E"/><rect x="200" y="112" width="26" height="28" rx="5" fill="#FFFFFF"/><path d="M226 118C236 118 236 132 226 132" stroke="#FFFFFF" stroke-width="4"/><path d="M262 140V76" stroke="#2F3E6E" stroke-width="5"/><path d="M238 80H286L274 54H250Z" fill="#E8A33C"/><rect y="140" width="320" height="40" fill="#2F3E6E"/><rect y="140" width="320" height="6" fill="#1E2A52"/></svg>'
};
const covArr = Object.keys(scenes).map(k => { const n = figma.createNodeFromSvg(scenes[k]); n.name = 'art'; const f = figma.createFrame(); f.resize(320, 180); f.clipsContent = true; f.appendChild(n); n.x = 0; n.y = 0; return comp(f, 'Scene=' + k); });
const covSet = figma.combineAsVariants(covArr, ds); covSet.name = 'Cover'; layoutSet(covSet, 1400, 24); place(covSet);
covSet.description = 'Ảnh minh hoạ thay ảnh thật (bìa blog, sự kiện, địa điểm). Thay bằng ảnh thật khi có dữ liệu.';

// Logo
const logoSvg = '<svg width="40" height="40" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg"><rect width="40" height="40" rx="8" fill="#FBF4F3"/><g fill="#C2456E"><circle cx="20" cy="9" r="7"/><circle cx="30.5" cy="16.6" r="7"/><circle cx="26.5" cy="29" r="7"/><circle cx="13.5" cy="29" r="7"/><circle cx="9.5" cy="16.6" r="7"/></g><circle cx="20" cy="20" r="4.5" fill="#E8A33C"/></svg>';
const ln = figma.createNodeFromSvg(logoSvg); const lf = figma.createFrame(); lf.resize(40, 40); lf.fills = []; lf.appendChild(ln); ln.x = 0; ln.y = 0;
const logo = comp(lf, 'Logo'); logo.description = 'Logo hoa anh đào của web Senpai ơi.'; place(logo);
return { ids, holder: holder.id, libText: lt.id, libLen: LIB.length, nextY: y };
// ===== phần 3: component BottomNav, TopActions + trang Foundations =====
const ds = await figma.getNodeByIdAsync('2:2');
await figma.setCurrentPageAsync(ds);
await figma.loadFontAsync({ family: 'Inter', style: 'Regular' });
const lt = await figma.getNodeByIdAsync('3:3');
let LIB = lt.characters;
LIB = LIB.replace("s.resize(390, 844);", "s.resize(390, o.h || 844);");
LIB = LIB.replace("  if (o.large) {", "  if (o.top) acts.push(inst('TopActions', { User: o.top }));\n  if (o.large) {");
lt.characters = LIB;
const AF = Object.getPrototypeOf(async function () {}).constructor;
const H = await new AF('figma', LIB)(figma);
const { T, I, F, fill, add, avatar } = H;
const comp = (frame, name) => { const c = figma.createComponentFromNode(frame); c.name = name; return c; };
const layoutSet = (set, w, gap) => { set.layoutMode = 'HORIZONTAL'; set.layoutWrap = 'WRAP'; set.itemSpacing = gap; set.counterAxisSpacing = gap; set.paddingTop = set.paddingBottom = set.paddingLeft = set.paddingRight = 24; set.resize(w, 100); set.primaryAxisSizingMode = 'FIXED'; set.counterAxisSizingMode = 'AUTO'; };

// BottomNav
const tabsDef = [['Trang chủ', 'home'], ['Bản đồ', 'map'], ['Blog', 'article'], ['Hỏi-Đáp', 'question_answer'], ['Thêm', 'menu']];
const navs = tabsDef.map(([active]) => {
  const items = tabsDef.map(([label, icon]) => { const on = label === active;
    const ind = F('H', { name: 'indicator', fill: on ? 'brand-soft' : null, r: 999, w: 56, h: 32, just: 'c', align: 'c' }, [I(icon, 24, on ? 'brand-text' : 'muted', on)]);
    return [F('V', { name: 'item/' + label, gap: 4, align: 'c', p: [8, 0, 0, 0] }, [ind, T(label, on ? 'Label/M' : 'Label/S', on ? 'brand-text' : 'muted', { name: 'label' })]), 'g']; });
  const row = F('H', { name: 'items', p: [0, 6], h: 64 }, items);
  const handle = F('H', { name: 'gesture', h: 18, just: 'c', align: 'c' }, [F('H', { name: 'bar', fill: 'ink', op: 0.25, r: 99, w: 120, h: 4 })]);
  const bar = F('V', { name: 'nav', fill: 'surface', w: 390, stroke: 'line', shadow: 'Shadow/Bar' }, [[row, 'w'], [handle, 'w']]);
  bar.strokeTopWeight = 1; bar.strokeBottomWeight = 0; bar.strokeLeftWeight = 0; bar.strokeRightWeight = 0;
  return comp(bar, 'Active=' + active);
});
const navSet = figma.combineAsVariants(navs, ds); navSet.name = 'BottomNav'; layoutSet(navSet, 438, 16);
navSet.description = '5 tab gốc như main_screen.dart: Trang chủ, Bản đồ, Blog, Hỏi-Đáp, Thêm. Tab đang chọn: icon đặc trong viên thuốc brand-soft.';

// TopActions
const iconBtn = (icon, badgeText) => { const b = F('H', { name: 'iconBtn', w: 40, h: 40, r: 20, just: 'c', align: 'c' }, [I(icon, 24, 'ink')]);
  if (badgeText) { const bd = F('H', { name: 'badge', fill: 'brand', r: 99, p: [1, 5], align: 'c', just: 'c', stroke: 'surface', sw: 1.5, }, [T(badgeText, 'Overline', 'on-brand', { name: 'count' })]); b.appendChild(bd); bd.layoutPositioning = 'ABSOLUTE'; bd.x = 22; bd.y = 2; }
  return b; };
const tas = ['Member', 'Guest'].map(u => {
  const kids = [iconBtn('search'), iconBtn('chat_bubble', u === 'Member' ? '3' : null), iconBtn('notifications', u === 'Member' ? '12' : null)];
  kids.push(u === 'Member' ? F('H', { name: 'me', w: 40, h: 40, just: 'c', align: 'c' }, [avatar('L', 32, 'lantern')]) : iconBtn('login'));
  return comp(F('H', { name: 'ta', gap: 0, align: 'c' }, kids), 'User=' + u);
});
const taSet = figma.combineAsVariants(tas, ds); taSet.name = 'TopActions'; layoutSet(taSet, 260, 16);
taSet.description = 'Cụm icon trên 5 tab gốc: Tìm kiếm, Tin nhắn (badge chưa đọc + lời mời), Thông báo, Tôi/Đăng nhập.';

const existing = ds.children.filter(n => n.type === 'COMPONENT_SET' || n.type === 'COMPONENT');
let y = Math.max(...existing.map(n => n.y + n.height)) + 120;
navSet.x = 1600; navSet.y = y; y += navSet.height + 120; taSet.x = 1600; taSet.y = y;

// Foundations doc
const colors = [['brand', '#C2456E', 'Màu chủ đạo – nút chính, tab đang chọn'], ['brand-strong', '#A8365C', 'Nhấn / pressed'], ['brand-soft', '#FCE9EF', 'Nền chip, chỉ báo tab'], ['brand-text', '#8E2B4E', 'Chữ trên nền hồng'], ['ink', '#2F3E6E', 'Chữ chính, thẻ tối'], ['muted', '#676E8A', 'Chữ phụ'], ['bg', '#FBF4F3', 'Nền màn hình'], ['surface', '#FFFFFF', 'Thẻ'], ['surface-2', '#F8EEF0', 'Nền phụ'], ['line', '#EBDCE0', 'Viền'], ['lantern', '#E8A33C', 'Điểm nhấn đèn lồng, sao'], ['lantern-soft', '#FDF0D8', 'Nền nhắc nhở'], ['ok', '#2E7D5B', 'Thành công / đã giải quyết'], ['ok-soft', '#E1F2E9', ''], ['warn', '#8A5800', 'Cảnh báo'], ['crit', '#B3261E', 'Lỗi / xoá / lừa đảo'], ['crit-soft', '#FBE1DF', ''], ['ai-soft', '#E6E9F4', 'Gợi ý “Dành cho bạn”']];
const sw = colors.map(([n, h, d]) => { const r = figma.createRectangle(); r.resize(140, 72); r.cornerRadius = 12; fill(r, n); H.stroke(r, 'line');
  return F('V', { name: 'swatch/' + n, gap: 6, w: 140 }, [r, T(n, 'Label/M', 'ink'), T(h, 'Caption', 'muted'), d ? [T(d, 'Caption', 'muted'), 'w'] : null]); });
const swGrid = F('H', { name: 'colors', gap: 20, wrap: true, rowGap: 24, w: 1340 }, sw);
const typeRows = [['Display/XL', 'Ở Nhật, bạn không đi một mình.', 'Bricolage Grotesque ExtraBold 30/36'], ['Display/L', 'Trang chủ · Bản đồ · Blog', 'Bricolage Grotesque Bold 24/30'], ['Display/M', 'Câu tiếng Nhật hôm nay', 'Bricolage Grotesque Bold 20/26'], ['Title/M', 'Tiêu đề thẻ, AppBar', 'Be Vietnam Pro SemiBold 17/24'], ['Title/S', 'Tên địa điểm, tiêu đề bài', 'Be Vietnam Pro SemiBold 15/21'], ['Body/M', 'Nội dung chính của bài viết và review.', 'Be Vietnam Pro Regular 15/22'], ['Body/S', 'Trích đoạn, mô tả phụ', 'Be Vietnam Pro Regular 13/19'], ['Label/M', 'Nút, chip, tab', 'Be Vietnam Pro SemiBold 14/20'], ['Caption', '3 giờ trước · Shinjuku', 'Be Vietnam Pro Regular 12/16'], ['JP/L', 'すみません、駅はどこですか？', 'Zen Maru Gothic Bold 26/34']];
const typeCol = F('V', { name: 'type', gap: 14, w: 1340 }, typeRows.map(([s, ex, spec]) => [F('H', { name: 'type/' + s, gap: 24, align: 'c' }, [F('V', { w: 260, gap: 2 }, [T(s, 'Label/M', 'brand-text'), T(spec, 'Caption', 'muted')]), [T(ex, s, 'ink'), 'g']]), 'w']));
const logo = H.inst('Logo'); logo.rescale(1.6);
const doc = F('V', { name: 'Foundations', fill: 'surface', r: 32, p: 56, gap: 40, w: 1452 }, [
  F('H', { name: 'title', gap: 16, align: 'c' }, [logo, F('V', { gap: 2 }, [T('Senpai ơi — Mobile Design System', 'Display/XL', 'ink'), T('Màu, chữ và component lấy theo token của web (tokens.css). Mọi màu trong file đều gắn biến “Senpai Color”.', 'Body/M', 'muted')])]),
  T('Màu', 'Display/M', 'ink'), swGrid,
  T('Kiểu chữ', 'Display/M', 'ink'), typeCol,
  T('Quy ước', 'Display/M', 'ink'),
  [T('• Khung 390 × 844, lề 16, khoảng cách 8/12/16/24.  • Bo góc: thẻ 16, ô nhập 12, nút 14, chip tròn.  • Icon: Material Symbols Rounded (viền) và Material Icons Round (đặc, tab đang chọn, sao).  • Ảnh thật được thay bằng minh hoạ “Cover” cùng bảng màu.', 'Body/M', 'ink'), 'w']
]);
doc.x = 0; doc.y = 0;
return { navSet: navSet.id, taSet: taSet.id, doc: doc.id, libPatched: LIB.indexOf("inst('TopActions'") > 0 && LIB.indexOf('o.h || 844') > 0 };