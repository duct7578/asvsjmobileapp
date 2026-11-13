// Senpai ơi – plugin vẽ phần còn lại của bản redesign mobile.
// Chạy trong file Figma "Senpai ơi – Mobile App Redesign" (đã có trang Design System và biến Senpai Color).
'use strict';

let V = {}, S = {}, E = {}, CM = {};
const LINK_T = [], LINK_E = [];
const ERRORS = [];

async function initLib() {
  const vars = await figma.variables.getLocalVariablesAsync('COLOR');
  for (const v of vars) V[v.name] = v;
  for (const s of await figma.getLocalTextStylesAsync()) S[s.name] = s;
  for (const s of await figma.getLocalEffectStylesAsync()) E[s.name] = s;
  const fonts = [['Be Vietnam Pro', 'Regular'], ['Be Vietnam Pro', 'Medium'], ['Be Vietnam Pro', 'SemiBold'], ['Be Vietnam Pro', 'Bold'], ['Bricolage Grotesque', 'Bold'], ['Bricolage Grotesque', 'ExtraBold'], ['Material Symbols Rounded', 'Regular'], ['Material Icons Round', 'Regular'], ['Zen Maru Gothic', 'Medium'], ['Zen Maru Gothic', 'Bold'], ['Inter', 'Regular']];
  await Promise.all(fonts.map(f => figma.loadFontAsync({ family: f[0], style: f[1] })));
  const dsPage = figma.root.children.find(p => p.name.indexOf('Design System') >= 0);
  if (!dsPage) throw new Error('Không thấy trang "🎨 Design System". Hãy mở đúng file Senpai ơi – Mobile App Redesign.');
  await dsPage.loadAsync();
  for (const c of dsPage.findAllWithCriteria({ types: ['COMPONENT', 'COMPONENT_SET'] })) {
    if (c.type === 'COMPONENT_SET' || !c.parent || c.parent.type !== 'COMPONENT_SET') CM[c.name] = c;
  }
  const need = ['StatusBar', 'Button', 'Chip', 'TextField', 'Cover', 'Logo', 'BottomNav', 'TopActions'];
  const miss = need.filter(n => !CM[n]);
  if (miss.length) throw new Error('Thiếu component: ' + miss.join(', '));
  if (!V.brand || !S['Body/M']) throw new Error('Thiếu biến màu hoặc kiểu chữ của Senpai ơi.');
}

function AL(dir) {
  const f = figma.createFrame();
  f.layoutMode = dir; f.primaryAxisSizingMode = 'AUTO'; f.counterAxisSizingMode = 'AUTO';
  f.fills = []; f.clipsContent = false;
  return f;
}
function paint(name, op) {
  const v = V[name]; if (!v) throw new Error('no color ' + name);
  if (op != null) {
    const col = v.valuesByMode[Object.keys(v.valuesByMode)[0]];
    return { type: 'SOLID', color: { r: col.r, g: col.g, b: col.b }, opacity: op };
  }
  return figma.variables.setBoundVariableForPaint({ type: 'SOLID', color: { r: 0, g: 0, b: 0 } }, 'color', v);
}
function fill(n, name, op) { n.fills = name ? [paint(name, op)] : []; return n; }
function stroke(n, name, w, align) { n.strokes = [paint(name)]; n.strokeWeight = w || 1; n.strokeAlign = align || 'INSIDE'; return n; }
function T(str, style, color, o) {
  o = o || {};
  const st = S[style || 'Body/M']; if (!st) throw new Error('no text style ' + style);
  const t = figma.createText();
  t.fontName = st.fontName; t.fontSize = st.fontSize; t.lineHeight = st.lineHeight; t.letterSpacing = st.letterSpacing;
  t.characters = String(str);
  if (!o.nolink && !o.size && !o.deco) LINK_T.push([t, st.id]);
  fill(t, color || 'ink');
  t.name = o.name || String(str).slice(0, 24);
  if (o.align) t.textAlignHorizontal = o.align;
  if (o.w) { t.resize(o.w, t.height); t.textAutoResize = 'HEIGHT'; }
  if (o.lines) { if (o.w) t.textAutoResize = 'HEIGHT'; t.maxLines = o.lines; t.textTruncation = 'ENDING'; }
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
  const f = AL(dir === 'H' ? 'HORIZONTAL' : 'VERTICAL');
  f.name = o.name || (dir === 'H' ? 'Row' : 'Col');
  fill(f, o.fill || null, o.op);
  if (o.p != null) pad(f, o.p);
  f.itemSpacing = o.gap || 0;
  if (o.r != null) f.cornerRadius = o.r;
  if (o.stroke) stroke(f, o.stroke, o.sw || 1);
  if (o.dash) f.dashPattern = o.dash;
  if (o.align) f.counterAxisAlignItems = o.align === 'c' ? 'CENTER' : o.align === 'e' ? 'MAX' : o.align === 'b' ? 'BASELINE' : 'MIN';
  if (o.just) f.primaryAxisAlignItems = o.just === 'c' ? 'CENTER' : o.just === 'e' ? 'MAX' : o.just === 'sb' ? 'SPACE_BETWEEN' : 'MIN';
  if (o.wrap) { f.layoutWrap = 'WRAP'; f.counterAxisSpacing = o.rowGap != null ? o.rowGap : (o.gap || 0); }
  if (o.w || o.h) {
    f.resize(o.w || f.width || 1, o.h || f.height || 1);
    f.layoutSizingHorizontal = o.w ? 'FIXED' : 'HUG';
    f.layoutSizingVertical = o.h ? 'FIXED' : 'HUG';
  }
  f.clipsContent = o.clip != null ? o.clip : false;
  if (o.shadow) { const es = E[o.shadow === true ? 'Shadow/Card' : o.shadow]; f.effects = es.effects; LINK_E.push([f, es.id]); }
  if (o.opacity != null) f.opacity = o.opacity;
  add(f, kids);
  return f;
}
function abs(parent, n, x, y) { parent.appendChild(n); if (parent.layoutMode && parent.layoutMode !== 'NONE') n.layoutPositioning = 'ABSOLUTE'; n.x = x; n.y = y; return n; }
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
  return F('H', { name: 'badge', fill: t[0], p: [3, 8], r: 999, gap: 4, align: 'c' }, [icon ? I(icon, 14, t[1]) : null, T(text, 'Label/S', t[1])]);
}
function outlineBadge(text, color, icon) {
  return F('H', { name: 'badge/outline', stroke: color || 'line', p: [2, 8], r: 999, gap: 4, align: 'c' }, [icon ? I(icon, 14, color || 'muted') : null, T(text, 'Label/S', color || 'muted')]);
}
function avatar(initials, size, tone) {
  size = size || 40; const t = TONES[tone || 'brand'];
  return F('H', { name: 'avatar', fill: t[0], r: size / 2, w: size, h: size, just: 'c', align: 'c' }, [T(initials, size >= 56 ? 'Display/M' : (size >= 36 ? 'Label/M' : 'Label/S'), t[1])]);
}
function iconTile(icon, tone, size, r) {
  size = size || 40; const t = TONES[tone || 'brand'];
  return F('H', { name: 'iconTile', fill: t[0], r: r != null ? r : 12, w: size, h: size, just: 'c', align: 'c' }, [I(icon, Math.round(size * 0.55), t[1])]);
}
function card(o, kids) { o = Object.assign({ fill: 'surface', r: 16, stroke: 'line', p: 14, gap: 10, name: 'card' }, o || {}); return F('V', o, kids); }
function btn(label, kind, o) {
  o = o || {};
  const i = inst('Button', { Kind: kind || 'Primary', Size: o.size || 'L' });
  i.name = 'Button/' + label;
  setText(i, 'label', label);
  const ic = i.findOne(n => n.name === 'leading');
  if (ic && ic.type === 'TEXT') { if (o.icon) { ic.characters = o.icon; ic.visible = true; } else ic.visible = false; }
  return i;
}
function chip(label, on, icon) {
  const i = inst('Chip', { State: on ? 'On' : 'Off' });
  i.name = 'Chip/' + label;
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
  i.name = 'TextField/' + (label || value);
  setText(i, 'value', value);
  const v = i.findOne(n => n.name === 'value');
  if (o.placeholder && v) fill(v, 'muted');
  const lead = i.findOne(n => n.name === 'leading'); const trail = i.findOne(n => n.name === 'trailing');
  if (lead && lead.type === 'TEXT') { if (o.icon) { lead.characters = o.icon; lead.visible = true; } else lead.visible = false; }
  if (trail && trail.type === 'TEXT') { if (o.trail) { trail.characters = o.trail; trail.visible = true; } else trail.visible = false; }
  const kids = [];
  if (label) kids.push(T(label, 'Label/M', 'ink'));
  kids.push([i, 'w']);
  if (o.help) kids.push([T(o.help, 'Caption', o.state === 'Error' ? 'crit' : 'muted'), 'w']);
  return F('V', { name: 'field', gap: 6 }, kids);
}
function textarea(label, value, hgt, o) {
  o = o || {};
  const box = F('V', { name: 'textarea', fill: 'surface', stroke: o.focus ? 'brand' : 'line', sw: o.focus ? 2 : 1, r: 12, p: [12, 14], h: hgt || 120, gap: 6 }, [[T(value, 'Body/M', o.placeholder ? 'muted' : 'ink'), 'w']]);
  const kids = [];
  if (label) kids.push(T(label, 'Label/M', 'ink'));
  kids.push([box, 'w']);
  if (o.help || o.count) kids.push([F('H', { name: 'help', gap: 8 }, [[T(o.help || '', 'Caption', 'muted'), 'g'], o.count ? T(o.count, 'Caption', 'muted') : null]), 'w']);
  return F('V', { name: 'field', gap: 6 }, kids);
}
function search(ph, o) {
  o = o || {};
  return F('H', { name: 'search', fill: o.fill || 'surface', stroke: o.noStroke ? null : 'line', r: 999, p: [0, 16], h: o.h || 48, gap: 10, align: 'c' }, [I('search', 22, 'muted'), [T(ph, 'Body/M', o.value ? 'ink' : 'muted', { lines: 1 }), 'g'], o.trail ? I(o.trail, 22, 'brand') : null]);
}
function seg(items, active) {
  return F('H', { name: 'segmented', fill: 'surface-2', r: 999, p: 4, gap: 4 }, items.map((s, i) => {
    const lab = Array.isArray(s) ? s[0] : s; const ic = Array.isArray(s) ? s[1] : null; const on = i === active;
    return [F('H', { name: 'seg', fill: on ? 'surface' : null, r: 999, p: [8, 10], just: 'c', align: 'c', shadow: on ? 'Shadow/Card' : null, gap: 6 }, [ic ? I(ic, 18, on ? 'brand-text' : 'muted') : null, T(lab, 'Label/M', on ? 'brand-text' : 'muted')]), 'g'];
  }));
}
function tabs(items, active) {
  const f = F('H', { name: 'tabs', gap: 0, p: [0, 16], stroke: 'line' }, items.map((s, i) => [F('V', { name: 'tab', gap: 10, align: 'c', p: [10, 0, 0, 0] }, [F('H', { gap: 6, align: 'c' }, [T(Array.isArray(s) ? s[0] : s, 'Label/M', i === active ? 'brand-text' : 'muted'), Array.isArray(s) && s[1] ? badge(s[1], 'solid') : null]), F('H', { name: 'ind', fill: i === active ? 'brand' : null, r: 2, w: 48, h: 3 })]), 'g']));
  f.strokeTopWeight = 0; f.strokeLeftWeight = 0; f.strokeRightWeight = 0; f.strokeBottomWeight = 1;
  return f;
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
function toggle(on) {
  return F('H', { name: 'switch', fill: on ? 'brand' : 'line', r: 99, w: 44, h: 26, p: 3, align: 'c', just: on ? 'e' : 'MIN' }, [F('H', { name: 'knob', fill: 'surface', r: 99, w: 20, h: 20 })]);
}
function checkbox(on, label, o) {
  o = o || {};
  const box = F('H', { name: 'checkbox', fill: on ? 'brand' : 'surface', stroke: on ? null : 'muted', sw: 1.5, r: 6, w: 22, h: 22, just: 'c', align: 'c' }, [on ? I('check', 18, 'on-brand') : null]);
  if (!label) return box;
  return F('H', { name: 'check', gap: 10, align: o.top ? 'MIN' : 'c' }, [box, [T(label, o.style || 'Body/S', 'ink'), 'g']]);
}
function radio(on, label) {
  const r = F('H', { name: 'radio', stroke: on ? 'brand' : 'muted', sw: 2, r: 99, w: 22, h: 22, just: 'c', align: 'c' }, [on ? F('H', { fill: 'brand', r: 99, w: 12, h: 12 }) : null]);
  return label ? F('H', { name: 'radioRow', gap: 10, align: 'c' }, [r, [T(label, 'Body/M', 'ink'), 'g']]) : r;
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
function group(rows) {
  const g = F('V', { name: 'group', fill: 'surface', r: 16, stroke: 'line', p: [4, 14] });
  rows.forEach((r, i) => { if (i > 0) add(g, [[divider(), 'w']]); add(g, [[r, 'w']]); });
  return g;
}
function cover(kind, w, h, r) {
  const f = figma.createFrame(); f.name = 'cover/' + kind; f.resize(w, h); f.clipsContent = true; f.cornerRadius = r || 0; f.fills = [];
  const c = inst('Cover', { Scene: kind });
  c.rescale(Math.max(w / 320, h / 180));
  f.appendChild(c); c.x = (w - c.width) / 2; c.y = (h - c.height) / 2;
  return f;
}
function appBar(title, o) {
  o = o || {};
  const acts = (o.actions || []).map(a => F('H', { name: 'action', w: 40, h: 40, r: 20, just: 'c', align: 'c' }, [I(a, 24, a === 'delete' ? 'crit' : 'ink')]));
  if (o.top) { const ta = inst('TopActions', { User: o.top }); ta.name = 'TopActions'; acts.push(ta); }
  if (o.large) {
    return F('V', { name: 'AppBar/Large', p: [8, 8, 8, 16], gap: 2, fill: o.fill || null }, [
      [F('H', { name: 'row', gap: 4, align: 'c' }, [[F('V', { name: 'titles', gap: 0 }, [o.over ? T(o.over, 'Overline', 'brand') : null, [T(title, 'Display/L', 'ink'), 'w']]), 'g']].concat(acts)), 'w']
    ]);
  }
  const back = o.back === false ? null : F('H', { name: 'back', w: 40, h: 40, r: 20, just: 'c', align: 'c' }, [I(o.close ? 'close' : 'arrow_back', 24, 'ink')]);
  const titles = F('V', { name: 'titles', gap: 0 }, [[T(title, 'Title/M', 'ink', { lines: 1 }), 'w'], o.sub ? [T(o.sub, 'Caption', 'muted', { lines: 1 }), 'w'] : null]);
  return F('H', { name: 'AppBar', p: [4, 8, 4, 4], h: 56, gap: 4, align: 'c', fill: o.fill || null }, [back, o.lead || null, [titles, 'g']].concat(acts));
}
function screen(parent, name, x, y, o) {
  o = o || {};
  const s = figma.createFrame(); s.name = name; s.resize(390, o.h || 844); fill(s, o.bg || 'bg'); s.clipsContent = true;
  s.layoutMode = 'VERTICAL'; s.primaryAxisSizingMode = 'FIXED'; s.counterAxisSizingMode = 'FIXED'; s.itemSpacing = 0;
  parent.appendChild(s); s.x = x; s.y = y;
  const sb = inst('StatusBar', { Tone: o.dark ? 'Dark' : 'Light' }); sb.name = 'StatusBar';
  add(s, [[sb, 'w']]);
  return s;
}
function body(s, o, kids) {
  o = Object.assign({ name: 'Body', p: [8, 16, 24, 16], gap: 16, clip: true }, o || {});
  const b = F('V', o, kids);
  add(s, [[b, 'wh']]);
  return b;
}
function fitH(s, b) { b.layoutSizingVertical = 'HUG'; s.primaryAxisSizingMode = 'AUTO'; }
function nav(s, active) { const n = inst('BottomNav', { Active: active }); n.name = 'BottomNav'; add(s, [[n, 'w']]); return n; }
function fab(s, icon, label) {
  const f = F('H', { name: 'FAB', fill: 'brand', r: 18, p: label ? [0, 20, 0, 16] : 0, h: 56, w: label ? null : 56, gap: 8, align: 'c', just: 'c', shadow: 'Shadow/Float' }, [I(icon, 24, 'on-brand'), label ? T(label, 'Label/M', 'on-brand') : null]);
  s.appendChild(f); f.layoutPositioning = 'ABSOLUTE';
  const hasNav = !!s.findChild(n => n.name === 'BottomNav');
  f.x = 390 - 16 - f.width; f.y = s.height - (hasNav ? 82 : 34) - 16 - f.height;
  return f;
}
function bottomBar(s, kids) {
  const b = F('H', { name: 'BottomBar', fill: 'surface', p: [12, 16, 28, 16], gap: 12, align: 'c', shadow: 'Shadow/Bar' }, kids);
  add(s, [[b, 'w']]);
  return b;
}
function overlay(s, kids, o) {
  // scrim + floating dialog / bottom sheet over a screen
  o = o || {};
  const scrim = figma.createRectangle(); scrim.name = 'scrim'; scrim.resize(390, s.height); fill(scrim, 'ink-deep', 0.45);
  abs(s, scrim, 0, 0);
  const box = F('V', { name: o.sheet ? 'BottomSheet' : 'Dialog', fill: 'surface', r: o.sheet ? 0 : 24, p: o.sheet ? [10, 20, 32, 20] : 24, gap: 14, w: o.sheet ? 390 : 342 }, kids);
  if (o.sheet) { box.topLeftRadius = 24; box.topRightRadius = 24; box.insertChild(0, F('H', { name: 'handle-row', just: 'c', w: 350 }, [F('H', { name: 'handle', fill: 'line', r: 99, w: 40, h: 4 })])); }
  abs(s, box, o.sheet ? 0 : 24, 0);
  box.y = o.sheet ? s.height - box.height : Math.round((s.height - box.height) / 2);
  return box;
}
function photoPicker(label, n, max, kinds) {
  const thumbs = (kinds || []).map(k => { const c = cover(k, 80, 80, 12); const x = F('H', { name: 'remove', fill: 'ink', r: 99, w: 22, h: 22, just: 'c', align: 'c' }, [I('close', 14, 'on-brand')]); c.appendChild(x); x.x = 54; x.y = 4; return c; });
  const addBtn = (ic, tip) => F('V', { name: 'pick/' + tip, stroke: 'brand', sw: 1.5, dash: [6, 4], r: 12, w: 80, h: 80, just: 'c', align: 'c', gap: 4, fill: 'brand-soft' }, [I(ic, 24, 'brand-text'), T(tip, 'Label/S', 'brand-text')]);
  return F('V', { name: 'PhotoPicker', gap: 8 }, [T(label + ' (' + n + '/' + max + ')', 'Label/M', 'ink'), F('H', { gap: 10, wrap: true, rowGap: 10 }, thumbs.concat([addBtn('photo_camera', 'Chụp ảnh'), addBtn('photo_library', 'Chọn ảnh')]))]);
}
function note(icon, text, tone) {
  const t = TONES[tone || 'lantern'];
  return F('H', { name: 'note', fill: t[0], r: 14, p: [10, 12], gap: 10 }, [I(icon, 20, t[1]), [T(text, 'Body/S', t[1]), 'g']]);
}
function metaRow(items) { return F('H', { name: 'meta', gap: 4, align: 'c' }, items); }
function iconStat(ic, n, color, filled) { return F('H', { name: 'stat', gap: 4, align: 'c' }, [I(ic, 18, color || 'muted', filled), T(n, 'Label/S', color || 'muted')]); }
function linkText(t, icon) { return F('H', { name: 'link', gap: 4, align: 'c' }, [icon ? I(icon, 18, 'brand-text') : null, T(t, 'Label/M', 'brand-text')]); }
function authorLine(init, tone, name, tags, time) {
  return F('H', { name: 'author', gap: 8, align: 'c' }, [avatar(init, 32, tone), [F('V', { gap: 0 }, [F('H', { gap: 6, align: 'c' }, [T(name, 'Label/M', 'ink')].concat((tags || []).map(t => badge(t, 'ai')))), time ? T(time, 'Caption', 'muted') : null]), 'g']]);
}
function placeChip(name) { return F('H', { name: 'placeChip', fill: 'surface', stroke: 'line', r: 99, p: [5, 12, 5, 8], gap: 4, align: 'c' }, [I('location_on', 16, 'brand'), T(name, 'Label/S', 'ink')]); }
function topicChip(name) { return F('H', { name: 'topicChip', fill: 'surface-2', r: 99, p: [4, 10, 4, 8], gap: 4, align: 'c' }, [I('sell', 14, 'muted'), T(name, 'Label/S', 'muted')]); }
// ---------- helpers dùng chung cho các màn ----------
function pill(ic, label) { return F('H', { name: 'pill', fill: 'surface', stroke: 'line', r: 99, p: [0, 10, 0, 12], h: 36, gap: 4, align: 'c' }, [I(ic, 18, 'ink'), T(label, 'Label/M', 'ink'), I('arrow_drop_down', 20, 'muted')]); }
function info(ic, t) { return F('H', { name: 'info', gap: 8, align: 'c' }, [I(ic, 18, 'muted'), [T(t, 'Body/S', 'ink'), 'g']]); }
function inputChip(name, ic) { return F('H', { name: 'inputChip', fill: 'brand-soft', r: 99, p: [6, 8, 6, 10], gap: 6, align: 'c' }, [I(ic || 'location_on', 16, 'brand-text'), T(name, 'Label/S', 'brand-text'), I('close', 16, 'brand-text')]); }
function actionBtn(ic, label, on) { return F('H', { name: 'action', p: [10, 6], r: 12, gap: 6, just: 'c', align: 'c' }, [I(ic, 20, on ? 'brand' : 'ink', on), T(label, 'Label/M', on ? 'brand-text' : 'ink')]); }
function actionBar(items) { return F('H', { name: 'ActionBar', fill: 'surface', stroke: 'line', r: 16, p: [2, 4], gap: 2 }, items.map(a => [a, 'g'])); }
function sendBtn() { return F('H', { name: 'send', fill: 'brand', r: 99, w: 40, h: 40, just: 'c', align: 'c' }, [I('send', 20, 'on-brand')]); }
function composer(hint) { return F('H', { name: 'composer', fill: 'surface-2', r: 999, p: [0, 4, 0, 16], h: 48, gap: 8, align: 'c' }, [[T(hint, 'Body/S', 'muted', { lines: 1 }), 'g'], sendBtn()]); }
function dropdownField(label, value) { return F('V', { name: 'dropdown', gap: 6 }, [label ? T(label, 'Label/S', 'muted') : null, [F('H', { fill: 'surface', stroke: 'line', r: 12, p: [0, 12], h: 48, gap: 6, align: 'c' }, [[T(value, 'Body/M', 'ink', { lines: 1 }), 'g'], I('expand_more', 22, 'muted')]), 'w']]); }
function tabsScroll(items, active) {
  const f = F('H', { name: 'tabs', gap: 22, p: [0, 16], stroke: 'line', clip: true }, items.map((s, i) => F('V', { name: 'tab', gap: 10, align: 'c', p: [10, 0, 0, 0] }, [T(s, 'Label/M', i === active ? 'brand-text' : 'muted'), F('H', { name: 'ind', fill: i === active ? 'brand' : null, r: 2, w: 40, h: 3 })])));
  f.strokeTopWeight = 0; f.strokeLeftWeight = 0; f.strokeRightWeight = 0; f.strokeBottomWeight = 1;
  return f;
}
function stepper(steps, current) {
  const kids = [];
  steps.forEach((label, i) => {
    const done = i < current, cur = i === current;
    if (i > 0) kids.push([F('V', { name: 'connector', p: [15, 0, 0, 0] }, [[F('H', { fill: i <= current ? 'brand' : 'line', h: 2, w: 10 }), 'w']]), 'g']);
    kids.push(F('V', { name: 'step', gap: 6, align: 'c', w: 76 }, [F('H', { fill: done ? 'brand' : cur ? 'brand-soft' : 'surface-2', stroke: cur ? 'brand' : null, sw: 2, r: 99, w: 32, h: 32, just: 'c', align: 'c' }, [done ? I('check', 18, 'on-brand') : T(String(i + 1), 'Label/M', cur ? 'brand-text' : 'muted')]), [T(label, 'Label/S', done || cur ? 'brand-text' : 'muted', { align: 'CENTER' }), 'w']]));
  });
  return F('H', { name: 'Stepper', gap: 0 }, kids);
}
function ratingPicker(n, label) {
  const row = F('H', { name: 'stars', gap: 4, align: 'c' }, []);
  for (let k = 1; k <= 5; k++) add(row, [I(n >= k ? 'star' : 'star_border', 40, n >= k ? 'lantern' : 'muted', true)]);
  add(row, [H_sp(1, 6), F('V', { gap: 0 }, [T(n + '/5', 'Title/M', 'ink'), T(label, 'Caption', 'muted')])]);
  return F('V', { name: 'RatingPicker', gap: 8 }, [T('Đánh giá *', 'Label/M', 'ink'), row]);
}
function H_sp(h, w) { return sp(h, w); }
function overlayBadge(frame, text) {
  const b = F('H', { name: 'more', fill: 'ink', op: 0.75, r: 99, p: [4, 10], align: 'c' }, [T(text, 'Label/S', 'on-brand')]);
  frame.appendChild(b); b.x = frame.width - b.width - 8; b.y = frame.height - b.height - 8;
  return frame;
}
function comment(init, tone, name, time, text, likes, indent) {
  const bubble = F('V', { name: 'bubble', fill: 'surface', stroke: 'line', r: 16, p: [10, 12], gap: 2 }, [F('H', { gap: 6, align: 'c' }, [T(name, 'Label/M', 'ink'), T(time, 'Caption', 'muted')]), [T(text, 'Body/S', 'ink'), 'w']]);
  const acts = F('H', { name: 'acts', gap: 16, p: [0, 0, 0, 12] }, [T('Thích · ' + likes, 'Label/S', 'muted'), T('Trả lời', 'Label/S', 'muted'), T('Nhắn tin', 'Label/S', 'muted')]);
  return F('H', { name: 'Comment', gap: 10, p: [0, 0, 0, indent || 0] }, [avatar(init, 32, tone), [F('V', { gap: 6 }, [[bubble, 'w'], acts]), 'g']]);
}

// ================= SECTION 2 · Bản đồ & Địa điểm =================
function s09(sec, x, y) {
  const s = screen(sec, '09 · Chi tiết địa điểm (place_detail_screen)', x, y);
  add(s, [[appBar('Gyomu Super Minami-Senju', { actions: ['map'] }), 'w']]);
  const small2 = overlayBadge(cover('Park', 110, 76, 14), '+6');
  const photos = F('H', { name: 'Photos', gap: 8 }, [cover('Food', 240, 160, 18), F('V', { gap: 8 }, [cover('City', 110, 76, 14), small2])]);
  const bar = (n, pct, c) => F('H', { name: 'bar', gap: 8, align: 'c' }, [T(String(n), 'Caption', 'muted'), progress(pct, 150, 'lantern'), T(String(c), 'Caption', 'muted')]);
  const rating = card({ name: 'Rating', r: 20, p: 16, gap: 10 }, [
    F('H', { gap: 20, align: 'c' }, [F('V', { gap: 2, align: 'c' }, [T('4.2', 'Display/XL', 'ink'), stars(4, 16), T('18 review', 'Caption', 'muted')]), F('V', { gap: 4 }, [bar(5, 55, 10), bar(4, 30, 5), bar(3, 10, 2), bar(2, 5, 1), bar(1, 0, 0)])]),
    [T('18 review từ người dùng Senpai ơi', 'Caption', 'muted'), 'w']]);
  const tile = (ic, label) => [F('V', { name: 'actionTile', fill: 'surface', stroke: 'line', r: 14, p: [10, 6], gap: 4, align: 'c' }, [I(ic, 22, 'ink'), [T(label, 'Label/S', 'ink', { align: 'CENTER' }), 'w']]), 'g'];
  const review = (init, tone, name, meta, n, tagsB, text, imgs, time, likes) => card({ name: 'PlaceReviewCard', r: 18, p: 14, gap: 10 }, [
    [F('H', { gap: 10, align: 'c' }, [avatar(init, 40, tone), [F('V', { gap: 1 }, [T(name, 'Label/M', 'ink'), T(meta, 'Caption', 'muted')]), 'g'], I('more_vert', 20, 'muted')]), 'w'],
    [F('H', { gap: 6, align: 'c', wrap: true, rowGap: 6 }, [stars(n, 16)].concat(tagsB)), 'w'],
    [T(text, 'Body/M', 'ink'), 'w'],
    imgs ? F('H', { gap: 8 }, imgs.map(k => cover(k, 88, 88, 12))) : null,
    [F('H', { gap: 14, align: 'c' }, [[T(time, 'Caption', 'muted'), 'g'], iconStat('thumb_up', 'Thích (' + likes + ')'), iconStat('flag', 'Báo cáo')]), 'w']]);
  const b = body(s, { gap: 16 }, [photos,
    [F('H', { gap: 6, wrap: true, rowGap: 6 }, [badge('Siêu thị', 'brand', 'shopping_cart'), badge('Nhóm Senpai ơi thêm', 'ai', 'verified')]), 'w'],
    [F('V', { gap: 4 }, [[T('Gyomu Super Minami-Senju', 'Display/L', 'ink'), 'w'], [T('業務スーパー 南千住店 · Gyomu Super · 2-14-3 Minami-Senju, Arakawa-ku', 'Body/S', 'muted'), 'w']]), 'w'],
    [rating, 'w'],
    [btn('Viết review', 'Primary', { icon: 'rate_review' }), 'w'],
    [F('H', { gap: 8 }, [tile('bookmark', 'Lưu'), tile('directions', 'Chỉ đường'), tile('block', 'Báo đã đóng cửa (1/5)')]), 'w'],
    [seg([['Review', 'rate_review'], ['Từ vựng và mẫu câu', 'translate']], 0), 'w'],
    [review('H', 'brand', 'Hà Phương', 'Du học sinh · Senpai bạc', 4, [badge('Còn mới', 'ok'), badge('Hữu ích', 'lantern', 'verified')], 'Rau và thịt rẻ hơn konbini nhiều. Thứ Ba rau giảm 20%. Có góc đồ châu Á: nước mắm, bánh phở khô, sả cây đông lạnh.', ['Food', 'City'], '3 giờ trước', 12), 'w'],
    [review('Q', 'ai', 'Quang Huy', 'Đã đi làm · Senpai vàng', 4, [badge('Hơn 1 năm, cần xác minh lại', 'warn')], 'Quầy tự thanh toán có tiếng Anh. Túi nilon tính phí 3 yên, nhớ mang túi.', null, '14/3/2025 · đã sửa', 5), 'w'],
    [F('H', { just: 'c' }, [btn('Xem thêm review', 'Ghost', { size: 'S' })]), 'w']]);
  fitH(s, b);
}
function s10(sec, x, y) {
  const s = screen(sec, '10 · Viết review (review_form_screen)', x, y);
  add(s, [[appBar('Viết review', { close: true }), 'w']]);
  const place = F('H', { name: 'place', fill: 'surface', stroke: 'line', r: 16, p: 12, gap: 12, align: 'c' }, [iconTile('shopping_cart', 'brand', 44, 22), [F('V', { gap: 0 }, [T('Gyomu Super Minami-Senju', 'Title/S', 'ink'), T('Siêu thị · Arakawa-ku', 'Caption', 'muted')]), 'g']]);
  body(s, { gap: 16 }, [[place, 'w'],
    [note('info', 'Tài khoản mới (dưới 7 ngày): hôm nay còn 2/3 lượt đăng bài viết hoặc review.', 'lantern'), 'w'],
    ratingPicker(4, 'Rất tốt'),
    [textarea('Nội dung *', 'Siêu thị rộng, giá rẻ hơn konbini nhiều. Thứ Ba rau giảm 20%, có góc đồ châu Á: nước mắm, bánh phở khô…', 110, { focus: true, help: 'Ít nhất 20 ký tự', count: '118/2000' }), 'w'],
    [photoPicker('Ảnh (không bắt buộc)', 2, 5, ['Food', 'City']), 'w'],
    [T('Tối đa 5 ảnh. Ảnh được quét tự động trước khi hiện cho mọi người.', 'Caption', 'muted'), 'w']]);
  bottomBar(s, [[btn('Đăng review', 'Primary', { icon: 'send' }), 'g']]);
}
function s11(sec, x, y) {
  const s = screen(sec, '11 · Review mới (recent_reviews_screen)', x, y);
  add(s, [[appBar('Review mới'), 'w']]);
  const rc = (ic, tone, name, sub, n, tagsB, text, photo, author, atone, tag, meta) => card({ name: 'RecentReviewCard', r: 18, p: 14, gap: 10 }, [
    [F('H', { gap: 10, align: 'c' }, [iconTile(ic, tone, 44, 22), [F('V', { gap: 0 }, [T(name, 'Title/S', 'ink'), T(sub, 'Caption', 'muted')]), 'g']]), 'w'],
    [F('H', { gap: 6, align: 'c', wrap: true, rowGap: 6 }, [stars(n, 16)].concat(tagsB)), 'w'],
    [T(text, 'Body/M', 'ink', { lines: 4 }), 'w'],
    photo ? overlayBadge(cover(photo, 330, 150, 14), '+2') : null,
    [F('H', { gap: 6, align: 'c' }, [avatar(author[0], 24, atone), T(author, 'Label/S', 'ink'), badge(tag, 'ai'), [T(meta, 'Caption', 'muted', { align: 'RIGHT' }), 'g']]), 'w'],
    [divider(), 'w'],
    linkText('Xem trên bản đồ', 'map')]);
  body(s, { gap: 14 }, [[T('12 review quanh Arakawa, mới nhất trước. Bấm vào một review để xem địa điểm.', 'Body/S', 'muted'), 'w'],
    chips(['Quanh Arakawa · 12', 'Cả tỉnh Tokyo · 140', 'Tất cả · 560'], 0),
    [rc('ramen_dining', 'lantern', 'Ramen Ichiran Ueno', 'Quán ăn · Taitō-ku', 5, [badge('Gần bạn', 'brand', 'location_on'), badge('Hữu ích', 'ok', 'verified')], 'Ngồi buồng riêng, gọi món bằng phiếu có tiếng Anh. Tầm 21h vẫn phải xếp hàng 15 phút.', 'Food', 'Minh Anh', 'brand', 'Du học sinh', '2 giờ trước · ♥ 9'), 'w'],
    [rc('local_laundry_service', 'ai', 'Coin Laundry Machiya', 'Giặt là · Arakawa-ku', 3, [badge('Gần bạn', 'brand', 'location_on')], 'Máy sấy 10 phút 100 yên, có máy đổi tiền. Buổi tối hơi đông.', null, 'Khánh', 'ai', 'Du học sinh', 'hôm qua · ♥ 3'), 'w']]);
}

// ================= SECTION 3 · Blog =================
function blogCard(o) {
  return card({ name: 'BlogCard', r: 18, p: 14, gap: 10 }, [
    [F('H', { gap: 6, align: 'c' }, [o.pinned ? badge('Đã ghim', 'lantern', 'push_pin') : null, [T(o.time, 'Caption', 'muted', { align: 'RIGHT' }), 'g']]), 'w'],
    [F('H', { gap: 12 }, [[F('V', { gap: 4 }, [[T(o.title, 'Title/S', 'ink', { lines: 2 }), 'w'], [T(o.ex, 'Body/S', 'muted', { lines: 3 }), 'w']]), 'g'], o.img ? cover(o.img, 84, 84, 12) : null]), 'w'],
    [F('H', { gap: 6, wrap: true, rowGap: 6 }, o.topics.map(topicChip).concat(o.places.map(placeChip))), 'w'],
    [F('H', { gap: 6, align: 'c' }, [avatar(o.author[0], 28, o.tone), T(o.author, 'Label/S', 'ink'), badge(o.tag, 'ai'), [sp(1, 1), 'g'], iconStat('favorite', o.likes), iconStat('chat_bubble', o.cmts)]), 'w']]);
}
function s12(sec, x, y) {
  const s = screen(sec, '12 · Blog (blog_list_screen)', x, y);
  add(s, [[appBar('Blog', { large: true, top: 'Member' }), 'w']]);
  const feat = (rank, kind, title, author, likes, cmts) => F('V', { name: 'FeaturedCard', fill: 'surface', stroke: 'line', r: 18, w: 250, clip: true }, [cover(kind, 250, 96, 0), [F('V', { p: 12, gap: 6 }, [badge('#' + rank, 'lantern', 'star'), [T(title, 'Title/S', 'ink', { lines: 2 }), 'w'], [F('H', { gap: 6, align: 'c' }, [[T(author, 'Caption', 'muted'), 'g'], iconStat('favorite', likes, 'brand', true), iconStat('chat_bubble', cmts)]), 'w']]), 'w']]);
  const stats = F('H', { name: 'Stats', fill: 'surface', stroke: 'line', r: 16, p: [12, 14], gap: 12, align: 'c' }, [iconTile('insights', 'ai', 36, 10), [F('V', { gap: 0 }, [T('Thống kê cộng đồng', 'Title/S', 'ink'), T('Chủ đề phổ biến, Senpai viết nhiều', 'Caption', 'muted')]), 'g'], I('expand_more', 24, 'muted')]);
  body(s, { p: [4, 16, 24, 16], gap: 14 }, [[search('Tìm theo tiêu đề, nội dung hoặc địa điểm'), 'w'],
    F('H', { gap: 8, align: 'c' }, [pill('sort', 'Mới nhất'), chip('Tất cả', true), chip('Nhà ở'), chip('Thủ tục'), chip('Du lịch')]),
    [F('V', { gap: 2 }, [sectionHead('Bài nổi bật tuần này', null, 'local_florist'), T('Tự động chọn theo lượt thích và bình luận', 'Caption', 'muted')]), 'w'],
    F('H', { gap: 12 }, [feat(1, 'Torii', 'Đi Kawagoe một ngày: tiểu Edo cách Tokyo 30 phút', 'Thảo Vy', '128', '36'), feat(2, 'City', 'Thuê nhà không cần người bảo lãnh', 'Minh Anh', '96', '41')]),
    [stats, 'w'],
    T('248 bài', 'Label/M', 'muted'),
    [blogCard({ pinned: true, time: '2 giờ trước', title: 'Hướng dẫn mở tài khoản Yuucho cho du học sinh mới', ex: 'Mang thẻ cư trú, số điện thoại Nhật và giấy chứng nhận đi học. Mình đi bưu điện Arakawa, mất 40 phút…', img: 'Study', topics: ['Ngân hàng'], places: ['Bưu điện Arakawa'], author: 'Tuấn', tone: 'lantern', tag: 'Du học sinh', likes: '56', cmts: '14' }), 'w'],
    [blogCard({ time: 'hôm qua', title: 'Đi Kawagoe một ngày: tiểu Edo cách Tokyo 30 phút', ex: 'Từ Ikebukuro đi Tobu Tojo Line khoảng 30 phút. Mua vé Kawagoe Discount Pass 700 yên…', img: 'Torii', topics: ['Du lịch'], places: ['Kawagoe'], author: 'Thảo Vy', tone: 'brand', tag: 'Đã đi làm', likes: '128', cmts: '36' }), 'w']]);
  nav(s, 'Blog');
  fab(s, 'edit', 'Viết bài');
}
function s13(sec, x, y) {
  const s = screen(sec, '13 · Bài viết (blog_detail_screen)', x, y);
  add(s, [[appBar('Bài viết', { actions: ['more_vert'] }), 'w']]);
  const author = F('H', { name: 'AuthorLine', gap: 10, align: 'c' }, [avatar('V', 44, 'brand'), [F('V', { gap: 4 }, [F('H', { gap: 4, align: 'c' }, [T('Thảo Vy', 'Title/S', 'ink'), I('workspace_premium', 16, 'lantern')]), F('H', { gap: 6 }, [badge('Đã đi làm', 'ai'), badge('Senpai vàng', 'lantern', 'military_tech')]), T('hôm qua · đã sửa', 'Caption', 'muted')]), 'g'], btn('Nhắn tin', 'Soft', { size: 'S', icon: 'chat' })]);
  const placeRow = (ic, name, sub) => F('H', { name: 'placeRow', gap: 10, p: [8, 0], align: 'c' }, [iconTile(ic, 'brand', 40, 20), [F('V', { gap: 0 }, [T(name, 'Title/S', 'ink'), T(sub, 'Caption', 'muted')]), 'g'], linkText('Chỉ đường', 'directions')]);
  const places = card({ name: 'RelatedPlaces', r: 18, p: 14, gap: 4 }, [[sectionHead('Địa điểm liên quan', null, 'map'), 'w'], [placeRow('temple_buddhist', 'Đền Hikawa Kawagoe', 'Saitama · 2-11-3 Miyashita-machi'), 'w'], [divider(), 'w'], [placeRow('cookie', 'Kashiya Yokocho', 'Phố kẹo · Motomachi, Kawagoe'), 'w']]);
  const b = body(s, { gap: 16 }, [cover('Torii', 358, 200, 20),
    [F('H', { gap: 6, wrap: true, rowGap: 6 }, [badge('Đã ghim', 'lantern', 'push_pin'), topicChip('Du lịch'), topicChip('Kinh nghiệm')]), 'w'],
    [T('Đi Kawagoe một ngày: tiểu Edo cách Tokyo 30 phút', 'Display/L', 'ink'), 'w'],
    [author, 'w'],
    [T('Từ Ikebukuro đi Tobu Tojo Line khoảng 30 phút là tới Kawagoe. Mình mua vé Kawagoe Discount Pass 700 yên, đi khứ hồi và được giảm giá vài quán.', 'Body/M', 'ink'), 'w'],
    F('H', { gap: 8 }, [cover('Torii', 175, 130, 14), cover('Food', 175, 130, 14)]),
    [T('Phố Kurazukuri buổi sáng còn vắng, chụp ảnh rất đẹp. Đến trưa nên ghé Kashiya Yokocho mua kẹo truyền thống và khoai lang nướng.', 'Body/M', 'ink'), 'w'],
    [places, 'w'],
    [actionBar([actionBtn('favorite', 'Thích · 88', true), actionBtn('bookmark', 'Lưu'), actionBtn('flag', 'Báo cáo')]), 'w'],
    [sectionHead('Bình luận (21)'), 'w'],
    [comment('H', 'ok', 'Hoàng', '2 giờ trước', 'Pass 700 yên có dùng cho xe buýt vòng quanh phố cổ không chị?', 3, 0), 'w'],
    [comment('V', 'brand', 'Thảo Vy', '1 giờ trước', 'Không em ơi, xe buýt Koedo Loop mua vé ngày riêng 500 yên nhé.', 5, 42), 'w'],
    [comment('L', 'lantern', 'Linh', '30 phút trước', 'Lưu lại cho mùa lá đỏ, cảm ơn chị!', 1, 0), 'w']]);
  bottomBar(s, [[composer('Chia sẻ thêm kinh nghiệm hoặc góp ý'), 'g']]);
  fitH(s, b);
}
function s14(sec, x, y) {
  const s = screen(sec, '14 · Viết bài (blog_form_screen)', x, y);
  add(s, [[appBar('Viết bài', { close: true }), 'w']]);
  const b = body(s, { gap: 18 }, [[note('info', 'Tài khoản mới, hôm nay: 1/3 bài viết và review.', 'lantern'), 'w'],
    [field('Tiêu đề *', 'Đi Kawagoe một ngày: tiểu Edo cách Tokyo 30 phút', { state: 'Focus' }), 'w'],
    [F('V', { gap: 8 }, [T('Chủ đề * (2/3)', 'Label/M', 'ink'), [chips(['Du lịch', 'Kinh nghiệm', 'Nhà ở', 'Thủ tục', 'Ẩm thực', 'Việc làm thêm', 'Cảnh báo lừa đảo', 'Khác'], -1, { wrap: true, multi: [0, 1] }), 'w'], [T('Chọn từ 1 đến 3 chủ đề. Không có chủ đề phù hợp thì chọn “Khác”.', 'Caption', 'muted'), 'w']]), 'w'],
    [F('V', { gap: 8 }, [T('Địa điểm liên quan (2/5)', 'Label/M', 'ink'), [F('H', { gap: 8, wrap: true, rowGap: 8 }, [inputChip('Đền Hikawa Kawagoe'), inputChip('Kashiya Yokocho', 'travel_explore')]), 'w'], [field(null, 'Tìm địa điểm (không bắt buộc)', { placeholder: true, icon: 'search' }), 'w']]), 'w'],
    [textarea('Nội dung *', 'Từ Ikebukuro đi Tobu Tojo Line khoảng 30 phút là tới Kawagoe. Mình mua vé Kawagoe Discount Pass 700 yên…', 140, { help: 'Chỉ tài khoản có tag định danh mới chèn được link.', count: '412/10000' }), 'w'],
    [photoPicker('Ảnh (không bắt buộc)', 2, 10, ['Torii', 'Food']), 'w'],
    [T('Tối đa 10 ảnh, mỗi ảnh không quá 10 MB. App chưa đăng được video.', 'Caption', 'muted'), 'w']]);
  bottomBar(s, [[btn('Đăng bài', 'Primary', { icon: 'send' }), 'g']]);
  fitH(s, b);
}

// ================= SECTION 4 · Hỏi-Đáp =================
function countBox(n, state) {
  if (state === 'solved') return F('V', { name: 'count', fill: 'ok', r: 14, w: 52, h: 64, just: 'c', align: 'c', gap: 0 }, [I('check', 18, 'on-brand'), T(n, 'Label/M', 'on-brand'), T('trả lời', 'Caption', 'on-brand', { size: 10 })]);
  if (state === 'none') return F('V', { name: 'count', fill: 'lantern-soft', r: 14, w: 52, h: 64, just: 'c', align: 'c' }, [T(n, 'Title/M', 'lantern-text'), T('trả lời', 'Caption', 'lantern-text', { size: 10 })]);
  return F('V', { name: 'count', stroke: 'line', fill: 'surface', r: 14, w: 52, h: 64, just: 'c', align: 'c' }, [T(n, 'Title/M', 'ink'), T('trả lời', 'Caption', 'muted', { size: 10 })]);
}
function qCard(o) {
  return card({ name: 'QuestionCard', r: 18, p: 14, gap: 0 }, [[F('H', { gap: 12 }, [countBox(o.n, o.state), [F('V', { gap: 6 }, [
    [F('H', { gap: 6, wrap: true, rowGap: 6 }, o.badges), 'w'],
    [T(o.title, 'Title/S', 'ink', { lines: 3 }), 'w'],
    [T(o.text, 'Body/S', 'muted', { lines: 2 }), 'w'],
    [F('H', { gap: 6, wrap: true, rowGap: 6 }, o.topics.map(topicChip).concat((o.places || []).map(placeChip))), 'w'],
    [F('H', { gap: 6, align: 'c' }, [avatar(o.author[0], 22, o.tone), T(o.author, 'Label/S', 'ink'), T('· ' + o.time, 'Caption', 'muted'), [sp(1, 1), 'g'], iconStat('favorite', o.likes)]), 'w']]), 'g']]), 'w']]);
}
function s15(sec, x, y) {
  const s = screen(sec, '15 · Hỏi-Đáp (question_list_screen)', x, y);
  add(s, [[appBar('Hỏi-Đáp', { large: true, top: 'Member' }), 'w'], [tabs(['Câu hỏi', 'Câu hỏi thường gặp'], 0), 'w']]);
  const stat3 = (n, l, c) => [F('V', { gap: 0, align: 'c' }, [T(n, 'Display/M', c), T(l, 'Caption', 'muted')]), 'g'];
  body(s, { p: [12, 16, 24, 16], gap: 14 }, [[search('Tìm câu hỏi theo nội dung hoặc địa điểm'), 'w'],
    chips(['Tất cả', 'Chưa ai trả lời', 'Chưa giải quyết', 'Đã giải quyết'], 0),
    F('H', { gap: 8 }, [pill('sell', 'Chủ đề (2)'), pill('sort', 'Mới nhất')]),
    [F('H', { name: 'Stats', fill: 'ai-soft', r: 18, p: 14, gap: 8 }, [stat3('1.204', 'câu hỏi', 'ink'), stat3('86', 'chưa ai trả lời', 'lantern-text'), stat3('932', 'đã giải quyết', 'ok')]), 'w'],
    T('1.204 câu hỏi', 'Label/M', 'muted'),
    [qCard({ n: '5', state: 'solved', badges: [badge('Đã giải quyết', 'ok', 'check_circle')], title: 'Gia hạn visa du học cần mang những giấy tờ gì?', text: 'Visa mình hết hạn tháng 1, trường đã cấp giấy chứng nhận đi học. Cần thêm sổ ngân hàng không?', topics: ['Visa'], places: ['Cục XNC Tokyo'], author: 'Lan', tone: 'brand', time: '1 tuần trước', likes: '14' }), 'w'],
    [qCard({ n: '0', state: 'none', badges: [badge('Chưa ai trả lời', 'lantern', 'hourglass_empty')], title: 'Đổi bằng lái Việt Nam sang bằng Nhật ở Saitama mất bao lâu?', text: 'Mình đã dịch bằng ở JAF, giờ cần đặt lịch ở trung tâm Kōnosu thế nào?', topics: ['Giấy tờ'], author: 'Khánh', tone: 'ai', time: '3 giờ trước', likes: '2' }), 'w'],
    [qCard({ n: '3', state: 'answered', badges: [badge('Đã ghim', 'lantern', 'push_pin')], title: 'Làm thêm quá 28 tiếng/tuần vào kỳ nghỉ có bị sao không?', text: 'Kỳ nghỉ dài được làm 40 tiếng/tuần, nhưng nghỉ ngắn thì tính thế nào?', topics: ['Việc làm thêm'], author: 'Phúc', tone: 'ok', time: 'hôm qua', likes: '9' }), 'w']]);
  nav(s, 'Hỏi-Đáp');
  fab(s, 'contact_support', 'Đặt câu hỏi');
}
function s16(sec, x, y) {
  const s = screen(sec, '16 · Câu hỏi (question_detail_screen)', x, y);
  add(s, [[appBar('Câu hỏi', { actions: ['more_vert'] }), 'w']]);
  const best = card({ name: 'BestAnswer', stroke: 'brand', sw: 2, r: 18, p: 14, gap: 10 }, [badge('Câu trả lời hay nhất', 'ok', 'verified'),
    [authorLine('H', 'ok', 'Quang Huy', ['Đã đi làm'], '6 ngày trước'), 'w'],
    [T('Mang: hộ chiếu, thẻ cư trú, giấy chứng nhận đi học, bảng điểm và tỷ lệ đi học, ảnh 4×3, tem 4.000 yên (mua sau khi được duyệt). Sổ ngân hàng không bắt buộc nhưng nên mang. Đi Shinagawa trước 8h30 cho đỡ đông.', 'Body/M', 'ink'), 'w'],
    F('H', { gap: 16, align: 'c' }, [iconStat('thumb_up', 'Thích · 21', 'brand-text'), T('Trả lời', 'Label/S', 'muted'), T('Nhắn tin', 'Label/S', 'muted'), T('Báo cáo', 'Label/S', 'muted')]),
    [F('V', { name: 'reply', fill: 'surface-2', r: 14, p: [10, 12], gap: 2 }, [F('H', { gap: 6, align: 'c' }, [T('Lan', 'Label/S', 'ink'), T('· 5 ngày trước', 'Caption', 'muted')]), [T('Cảm ơn anh, em đi hôm qua mất 2 tiếng là xong!', 'Body/S', 'ink'), 'w']]), 'w']]);
  const other = card({ name: 'AnswerTile', r: 18, p: 14, gap: 10 }, [[authorLine('M', 'lantern', 'Mai', ['Du học sinh'], '5 ngày trước'), 'w'], [T('Nếu có làm thêm thì mang thêm giấy xác nhận thu nhập, nhiều bạn bị hỏi.', 'Body/M', 'ink'), 'w'], F('H', { gap: 16, align: 'c' }, [iconStat('thumb_up', 'Thích · 4'), T('Trả lời', 'Label/S', 'muted'), T('Báo cáo', 'Label/S', 'muted')])]);
  const box = F('H', { name: 'AnswerBox', fill: 'surface', stroke: 'line', r: 16, p: [0, 6, 0, 14], h: 52, gap: 8, align: 'c' }, [[T('Viết câu trả lời của bạn', 'Body/S', 'muted'), 'g'], sendBtn()]);
  const b = body(s, { gap: 16 }, [[F('H', { gap: 6 }, [badge('Hỏi đáp', 'ai', 'help'), badge('Đã giải quyết', 'ok', 'check_circle')]), 'w'],
    [T('Gia hạn visa du học cần mang những giấy tờ gì?', 'Display/L', 'ink'), 'w'],
    [F('H', { gap: 10, align: 'c' }, [[authorLine('L', 'brand', 'Lan', ['Du học sinh'], '1 tuần trước · đã sửa'), 'g'], btn('Nhắn tin', 'Soft', { size: 'S', icon: 'chat' })]), 'w'],
    [F('H', { gap: 6, wrap: true, rowGap: 6 }, [topicChip('Visa'), placeChip('Cục xuất nhập cảnh Tokyo')]), 'w'],
    [T('Visa của mình hết hạn ngày 20/1. Trường đã cấp giấy chứng nhận đi học và bảng điểm. Mình có cần mang thêm sổ ngân hàng hay giấy xác nhận làm thêm không ạ? Nộp ở Shinagawa có phải xếp hàng lâu không?', 'Body/M', 'ink'), 'w'],
    [actionBar([actionBtn('favorite', 'Thích · 14'), actionBtn('bookmark', 'Đã lưu', true), actionBtn('chat_bubble', 'Trả lời'), actionBtn('flag', 'Báo cáo')]), 'w'],
    [sectionHead('Câu trả lời (5)'), 'w'], [box, 'w'], [best, 'w'], [other, 'w']]);
  fitH(s, b);
}
function faqMini(q, topic) { return F('H', { name: 'faqMini', fill: 'surface', r: 12, p: [10, 12], gap: 8, align: 'c' }, [[F('V', { gap: 0 }, [[T(q, 'Label/M', 'ink'), 'w'], T(topic, 'Caption', 'muted')]), 'g'], I('chevron_right', 20, 'muted')]); }
function s17(sec, x, y) {
  const s = screen(sec, '17 · Đặt câu hỏi (question_form_screen)', x, y);
  add(s, [[appBar('Đặt câu hỏi', { close: true }), 'w']]);
  const sug = F('V', { name: 'Suggestions', fill: 'ai-soft', r: 18, p: 14, gap: 8 }, [[F('H', { gap: 8, align: 'c' }, [I('quiz', 20, 'ink'), [T('Có thể đã có câu trả lời', 'Title/S', 'ink'), 'g']]), 'w'], [T('Những câu hỏi thường gặp này giống điều bạn định hỏi. Nếu chưa đúng ý, bạn cứ đăng câu hỏi.', 'Body/S', 'muted'), 'w'], [faqMini('Đổi bằng lái nước ngoài (外免切替) cần giấy tờ gì?', 'Giấy tờ'), 'w'], [faqMini('Thi lý thuyết đổi bằng có tiếng Việt không?', 'Giấy tờ'), 'w']]);
  const b = body(s, { gap: 16 }, [[T('Hỏi cộng đồng, các senpai đã trải qua sẽ trả lời bạn.', 'Body/M', 'muted'), 'w'],
    [field('Câu hỏi *', 'Đổi bằng lái Việt Nam sang bằng Nhật ở Saitama mất bao lâu?', { state: 'Focus' }), 'w'],
    [sug, 'w'],
    [F('V', { gap: 8 }, [T('Chủ đề * (1/3)', 'Label/M', 'ink'), [chips(['Giấy tờ', 'Visa', 'Nhà ở', 'Việc làm thêm', 'Học tập', 'Khác'], 0, { wrap: true }), 'w']]), 'w'],
    [textarea('Mô tả chi tiết (không bắt buộc)', 'Thêm bối cảnh để mọi người trả lời đúng: bạn đang ở đâu, đã thử những gì', 100, { placeholder: true, help: 'Chỉ tài khoản có tag định danh mới chèn được link.' }), 'w'],
    [photoPicker('Ảnh (không bắt buộc)', 0, 4, []), 'w']]);
  bottomBar(s, [btn('Hủy', 'Secondary'), [btn('Đăng câu hỏi', 'Primary', { icon: 'send' }), 'g']]);
  fitH(s, b);
}
function s18(sec, x, y) {
  const s = screen(sec, '18 · Câu hỏi thường gặp (faq_screen)', x, y);
  add(s, [[appBar('Câu hỏi thường gặp'), 'w']]);
  const closed = (q, topic) => card({ name: 'FaqTile', r: 16, p: 14, gap: 0 }, [[F('H', { gap: 12, align: 'c' }, [iconTile('quiz', 'neutral', 36, 10), [F('V', { gap: 0 }, [[T(q, 'Title/S', 'ink'), 'w'], T(topic, 'Caption', 'muted')]), 'g'], I('expand_more', 24, 'muted')]), 'w']]);
  const open = card({ name: 'FaqTile/open', r: 18, p: 14, gap: 10, stroke: 'brand' }, [
    [F('H', { gap: 12, align: 'c' }, [iconTile('quiz', 'brand', 36, 10), [F('V', { gap: 0 }, [[T('Đổ rác ở Nhật phân loại thế nào?', 'Title/S', 'ink'), 'w'], T('Đời sống', 'Caption', 'muted')]), 'g'], I('expand_less', 24, 'muted')]), 'w'],
    [divider(), 'w'],
    [T('Rác cháy được (giấy, đồ ăn) đổ 2 lần mỗi tuần; rác không cháy, chai PET, lon, chai thủy tinh đổ riêng theo lịch của quận. Bỏ rác trước 8 giờ sáng đúng ngày, dùng túi trong suốt hoặc túi quy định.', 'Body/M', 'ink'), 'w'],
    F('V', { gap: 4 }, [T('Xem thêm', 'Label/S', 'muted'), linkText('Lịch đổ rác quận Arakawa (PDF)', 'open_in_new')]),
    [F('H', { gap: 8, align: 'c' }, [[T('Cập nhật 2/10/2026', 'Caption', 'muted'), 'g'], btn('Mở riêng câu này', 'Ghost', { size: 'S' })]), 'w']]);
  body(s, { gap: 12 }, [[T('Những thắc mắc phổ biến được Moderator tổng hợp và kiểm tra, nhiều câu lấy từ câu trả lời hay nhất của cộng đồng.', 'Body/S', 'muted'), 'w'],
    [search('Tìm câu hỏi thường gặp, ví dụ: mua SIM, đổ rác'), 'w'],
    chips(['Tất cả (64)', 'Giấy tờ (18)', 'Nhà ở (12)', 'Đời sống (20)'], 0),
    T('64 câu hỏi thường gặp', 'Label/M', 'muted'),
    [open, 'w'], [closed('Mua SIM giá rẻ khi chưa có thẻ ngân hàng?', 'Đời sống'), 'w'], [closed('Chuyển nhà thì phải báo những đâu?', 'Giấy tờ'), 'w'],
    [F('V', { name: 'AskCard', fill: 'brand-soft', r: 18, p: 16, gap: 8 }, [T('Chưa thấy câu trả lời?', 'Title/M', 'brand-text'), [T('Hỏi cộng đồng, các senpai đã trải qua sẽ trả lời bạn.', 'Body/S', 'brand-text'), 'w'], btn('Đặt câu hỏi', 'Primary', { size: 'M', icon: 'contact_support' })]), 'w']]);
}
// ================= SECTION 5 · Sự kiện & Cẩm nang =================
function stateChip(ic, label, color) { return F('H', { name: 'stateChip', fill: 'surface', r: 99, p: [4, 10], gap: 4, align: 'c', shadow: 'Shadow/Card' }, [I(ic, 16, color), T(label, 'Label/S', color)]); }
function eventCard(o) {
  const cv = cover(o.kind, 358, 130, 0);
  const ch = stateChip(o.state[0], o.state[1], o.state[2]); cv.appendChild(ch); ch.x = 12; ch.y = 12;
  return card({ name: 'EventCard', r: 20, p: 0, gap: 0, clip: true }, [cv, [F('V', { p: 14, gap: 6 }, [
    [T(o.title, 'Title/M', 'ink'), 'w'], [info('event', o.dates), 'w'], [info('location_on', o.place), 'w'], [info('payments', o.cost), 'w'],
    [F('H', { gap: 6, align: 'c', p: [4, 0, 0, 0] }, [o.rating ? stars(o.rating, 14) : null, T(o.ratingText, 'Caption', 'muted'), [sp(1, 1), 'g'], linkText('Viết review', 'rate_review')]), 'w']]), 'w']]);
}
function s19(sec, x, y) {
  const s = screen(sec, '19 · Lễ hội và sự kiện (event_list_screen)', x, y);
  add(s, [[appBar('Lễ hội và sự kiện'), 'w']]);
  const head = (t, n) => F('H', { gap: 8, align: 'c' }, [T(t, 'Title/M', 'ink'), badge(n, 'solid')]);
  body(s, { gap: 14 }, [[search('Tìm sự kiện hoặc nơi tổ chức'), 'w'],
    [T('Do Moderator đăng. Sự kiện đang hoặc sắp diễn ra cũng hiện trên bản đồ. Ai đã đi có thể viết review và đăng ảnh cho năm đó.', 'Body/S', 'muted'), 'w'],
    head('Đang diễn ra', '2'),
    [eventCard({ kind: 'Festival', state: ['celebration', 'Đang diễn ra', 'ok'], title: 'Lễ hội lá phong Rikugien — chiếu sáng đêm', dates: '1/11 – 7/12/2026', place: 'Vườn Rikugien, Komagome', cost: '300 yên', rating: 4.5, ratingText: '4.5 · 32 review' }), 'w'],
    head('Trong 30 ngày tới', '5'),
    [eventCard({ kind: 'Torii', state: ['schedule', 'Còn 7 ngày', 'brand-text'], title: 'Tori-no-ichi — Chợ phiên Gà', dates: '15/11 và 27/11/2026', place: 'Đền Ōtori, Asakusa', cost: 'Miễn phí', ratingText: 'Chưa có review' }), 'w']]);
}
function s20(sec, x, y) {
  const s = screen(sec, '20 · Chi tiết sự kiện (event_detail_screen)', x, y);
  add(s, [[appBar('Lễ hội lá phong Rikugien'), 'w']]);
  const rv = card({ name: 'EventReviewTile', r: 18, p: 14, gap: 10 }, [
    [F('H', { gap: 10, align: 'c' }, [avatar('N', 40, 'ok'), [F('V', { gap: 2 }, [T('Ngọc', 'Label/M', 'ink'), F('H', { gap: 6 }, [badge('Du học sinh', 'ai'), badge('Năm 2025', 'neutral')])]), 'g']]), 'w'],
    F('H', { gap: 8, align: 'c' }, [stars(5, 14), T('1 năm trước', 'Caption', 'muted')]),
    [T('Ánh đèn chiếu lên hồ đẹp lắm, nên đi ngày thường. Có quầy trà matcha 600 yên ngay cạnh hồ.', 'Body/M', 'ink'), 'w'],
    F('H', { gap: 8 }, [cover('Festival', 88, 88, 12), cover('Park', 88, 88, 12)]),
    F('H', { gap: 16, align: 'c' }, [iconStat('thumb_up', 'Thích · 7'), T('Báo cáo', 'Label/S', 'muted')])]);
  const tipText = T('Mẹo từ Moderator: Đi sau 19h để xem chiếu sáng, xếp hàng ở cổng Somei ít đông hơn cổng chính.', 'Body/S', 'lantern-text', { nolink: true });
  tipText.setRangeFontName(0, 16, { family: 'Be Vietnam Pro', style: 'Bold' });
  const content = F('V', { name: 'Content', p: [16, 16, 0, 16], gap: 16 }, [
    badge('Đang diễn ra', 'ok', 'celebration'),
    [T('Lễ hội lá phong Rikugien — chiếu sáng đêm', 'Display/L', 'ink'), 'w'],
    [card({ name: 'Info', r: 16, p: 14, gap: 10 }, [[info('event', '1/11 – 7/12/2026 · 9:00 – 21:00'), 'w'], [info('location_on', 'Vườn Rikugien, 6-16-3 Hon-Komagome, Bunkyō'), 'w'], [info('payments', '300 yên (sinh viên 150 yên)'), 'w']]), 'w'],
    [btn('Chỉ đường', 'Secondary', { icon: 'directions' }), 'w'],
    [sectionHead('Album từ review (24 ảnh)', 'Xem tất cả', 'photo_library'), 'w'],
    F('H', { gap: 8 }, [cover('Festival', 110, 110, 14), cover('Park', 110, 110, 14), overlayBadge(cover('Sakura', 110, 110, 14), '+21')]),
    [F('H', { name: 'Tip', fill: 'lantern-soft', r: 16, p: 14, gap: 10 }, [I('tips_and_updates', 22, 'lantern-text'), [tipText, 'g']]), 'w'],
    [card({ name: 'Rating', r: 18, p: 16, gap: 0 }, [F('H', { gap: 14, align: 'c' }, [T('4.5', 'Display/XL', 'ink'), F('V', { gap: 4 }, [stars(4.5, 18), T('32 review, gồm cả các năm trước', 'Caption', 'muted')])])]), 'w'],
    [btn('Viết review năm 2026', 'Primary', { icon: 'rate_review' }), 'w'],
    [sectionHead('Review (32)'), 'w'],
    [rv, 'w']]);
  const b = body(s, { p: [0, 0, 24, 0], gap: 0 }, [cover('Festival', 390, 210, 0), [content, 'w']]);
  fitH(s, b);
}
function s21(sec, x, y) {
  const s = screen(sec, '21 · Viết review sự kiện (event_review_form_screen)', x, y);
  add(s, [[appBar('Viết review', { close: true }), 'w']]);
  body(s, { gap: 16 }, [[F('V', { gap: 2 }, [[T('Lễ hội lá phong Rikugien — chiếu sáng đêm', 'Title/M', 'ink'), 'w'], [T('Review cho lần tổ chức năm 2026 · 1/11 – 7/12', 'Body/S', 'muted'), 'w']]), 'w'],
    [note('info', 'Tài khoản mới, hôm nay: 1/3 bài viết và review · 0/1 ghim · 0/1 video.', 'lantern'), 'w'],
    ratingPicker(5, 'Tuyệt vời'),
    [textarea('Nội dung *', 'Không khí, chi phí, nên đi giờ nào', 110, { placeholder: true, focus: true, help: 'Chỉ tài khoản có tag định danh mới chèn được link.', count: '0/2000' }), 'w'],
    [photoPicker('Ảnh', 1, 6, ['Festival']), 'w'],
    [T('Chữ được lọc từ khóa ngay. Ảnh được quét sau khi đăng; trong lúc đó review ở trạng thái “đang xử lý” và chỉ bạn thấy.', 'Caption', 'muted'), 'w']]);
  bottomBar(s, [[btn('Đăng review', 'Primary', { icon: 'send' }), 'g']]);
}
function guideCard(kind, topic, title, summary, meta) {
  return card({ name: 'GuideCard', r: 18, p: 12, gap: 0 }, [[F('H', { gap: 12 }, [cover(kind, 88, 88, 14), [F('V', { gap: 4 }, [T(topic, 'Overline', 'brand'), [T(title, 'Title/S', 'ink', { lines: 2 }), 'w'], [T(summary, 'Body/S', 'muted', { lines: 2 }), 'w'], T(meta, 'Caption', 'muted')]), 'g']]), 'w']]);
}
function s22(sec, x, y) {
  const s = screen(sec, '22 · Cẩm nang (guide_list_screen)', x, y);
  add(s, [[appBar('Cẩm nang'), 'w']]);
  body(s, { gap: 14 }, [[T('Hướng dẫn thiết thực cho việc học tập và cuộc sống tại Nhật Bản.', 'Body/S', 'muted'), 'w'],
    [search('Tìm theo tiêu đề, chủ đề hoặc từ khóa…', { trail: 'arrow_forward' }), 'w'],
    F('V', { gap: 8 }, [T('GIAI ĐOẠN', 'Overline', 'muted'), chips(['Tất cả', 'Sắp sang Nhật', 'Mới đến', 'Sắp về nước', 'Đã về nước'], 2)]),
    F('V', { gap: 8 }, [T('CHỦ ĐỀ', 'Overline', 'muted'), chips(['Tất cả', 'Giấy tờ', 'Nhà ở', 'Tài chính', 'Y tế'], 0)]),
    [F('H', { gap: 8, align: 'c' }, [[T('18 cẩm nang phù hợp', 'Label/M', 'muted'), 'g'], pill('sort', 'Mới nhất')]), 'w'],
    [guideCard('City', 'GIẤY TỜ', 'Đăng ký địa chỉ tại văn phòng quận', 'Làm trong 14 ngày sau khi chuyển đến: mang thẻ cư trú, hộ chiếu…', 'Mới đến · 12/9/2026'), 'w'],
    [guideCard('Study', 'TÀI CHÍNH', 'Mở tài khoản ngân hàng khi mới sang', 'Yuucho, ngân hàng lớn hay ngân hàng online: chọn sao cho dễ.', 'Mới đến · 3/9/2026'), 'w'],
    [guideCard('Park', 'Y TẾ', 'Bảo hiểm y tế quốc dân 国民健康保険', 'Đóng bao nhiêu, cách xin giảm phí cho du học sinh…', 'Mới đến · 28/8/2026'), 'w']]);
}
function taskRow(done, title, notes) {
  return F('H', { name: 'task', gap: 12, p: [12, 0] }, [checkbox(done), [F('V', { gap: 2 }, [[T(title, 'Title/S', done ? 'muted' : 'ink', { deco: done ? 'STRIKETHROUGH' : null, nolink: done }), 'w'], notes ? [T(notes, 'Body/S', 'muted'), 'w'] : null]), 'g']]);
}
function s23(sec, x, y) {
  const s = screen(sec, '23 · Chi tiết cẩm nang — tab Hướng dẫn chuẩn bị (guide_detail_screen)', x, y);
  add(s, [[appBar('Cẩm nang', { actions: ['share'] }), 'w'], [tabs(['Xem chi tiết', 'Hướng dẫn chuẩn bị'], 1), 'w']]);
  const prog = F('V', { name: 'Progress', fill: 'brand', r: 20, p: 16, gap: 10, clip: true }, [T('HƯỚNG DẪN CHUẨN BỊ', 'Overline', 'on-brand'),
    [F('H', { gap: 8, align: 'c' }, [[T('2/5 công việc đã hoàn thành', 'Title/M', 'on-brand'), 'g'], T('40%', 'Display/M', 'on-brand')]), 'w'],
    progress(40, 326, 'surface', 'brand-strong', 10)]);
  const deco = inst('Logo'); deco.rescale(2.2); deco.opacity = 0.15; abs(prog, deco, 290, -30);
  const b = body(s, { p: [16, 16, 24, 16], gap: 16 }, [[F('V', { gap: 6 }, [T('GIẤY TỜ', 'Overline', 'brand'), [T('Đăng ký địa chỉ tại văn phòng quận', 'Display/L', 'ink'), 'w'], T('Ngày tạo: 12/9/2026 · Nhóm Senpai ơi', 'Caption', 'muted')]), 'w'],
    [F('H', { gap: 10 }, [btn('Đã lưu', 'Soft', { size: 'M', icon: 'bookmark' }), [btn('Tiến độ: 2/5 việc', 'Secondary', { size: 'M', icon: 'checklist' }), 'g']]), 'w'],
    [prog, 'w'],
    [group([taskRow(true, 'Nhận thẻ cư trú ở sân bay', 'Thẻ ghi “住居地未定” nếu chưa có địa chỉ.'), taskRow(true, 'Ký hợp đồng nhà, lấy địa chỉ chính xác', null), taskRow(false, 'Mang thẻ cư trú và hộ chiếu tới quầy 住民登録', 'Văn phòng quận nơi bạn sống, trong 14 ngày.'), taskRow(false, 'Đăng ký bảo hiểm y tế quốc dân', 'Làm cùng lúc ở quầy 国民健康保険.'), taskRow(false, 'Nhận thẻ thông báo My Number', 'Gửi qua bưu điện sau 2–3 tuần.')]), 'w'],
    [note('arrow_forward', 'Việc tiếp theo: Mang thẻ cư trú và hộ chiếu tới quầy 住民登録.', 'brand'), 'w']]);
  fitH(s, b);
}
function s24(sec, x, y) {
  const s = screen(sec, '24 · Cẩm nang của tôi (my_guides_screen)', x, y);
  add(s, [[appBar('Cẩm nang của tôi'), 'w']]);
  const stage = (title, mine, pct, label) => F('V', { name: 'stage', gap: 8, p: [12, 0] }, [[F('H', { gap: 8, align: 'c' }, [T(title, 'Title/S', 'ink'), mine ? badge('Giai đoạn của bạn', 'brand', 'flag') : null, [T(label, 'Label/S', 'muted', { align: 'RIGHT' }), 'g']]), 'w'], progress(pct, 330, pct === 100 ? 'ok' : 'brand')]);
  body(s, { gap: 14 }, [[T('Cẩm nang có danh sách chuẩn bị xong khi bạn đánh dấu hết các việc; cẩm nang khác xong khi bạn bấm “Đánh dấu đã xong”.', 'Body/S', 'muted'), 'w'],
    [group([stage('Sắp sang Nhật', false, 100, '6/6'), stage('Mới đến', true, 37, '3/8'), stage('Sắp về nước', false, 0, 'Chưa có'), stage('Đã về nước', false, 0, '0/4')]), 'w'],
    [sectionHead('Đang làm dở'), 'w'],
    [card({ name: 'InProgress', r: 18, p: 14, gap: 8 }, [[T('Đăng ký địa chỉ tại văn phòng quận', 'Title/S', 'ink'), 'w'], T('Mới đến', 'Caption', 'muted'), progress(40, 330, 'brand'), [T('2/5 việc · Tiếp theo: Mang thẻ cư trú và hộ chiếu tới quầy 住民登録', 'Body/S', 'muted'), 'w']]), 'w'],
    [sectionHead('Đã xong gần đây'), 'w'],
    [group([listRow(iconTile('check_circle', 'ok', 36, 18), 'Mua SIM và đăng ký điện thoại', 'Mới đến · Xong ngày 2/9/2026', { trail: false }), listRow(iconTile('check_circle', 'ok', 36, 18), 'Chuẩn bị hành lý và giấy tờ', 'Sắp sang Nhật · Xong ngày 20/8/2026', { trail: false })]), 'w'],
    [btn('Mở Cẩm nang', 'Secondary', { icon: 'menu_book' }), 'w']]);
}

// ================= SECTION 6 · Nhật ngữ =================
function phraseCard(o) {
  return card({ name: 'PhraseCard', r: 18, p: 14, gap: 8 }, [
    [F('H', { gap: 6, wrap: true, rowGap: 6 }, [badge(o.kind, 'brand'), badge(o.cat, 'ai', o.catIcon || 'storefront'), outlineBadge(o.topic), o.known ? badge('Đã thuộc', 'ok', 'check_circle') : badge('Chưa thuộc', 'lantern', 'replay')]), 'w'],
    [T(o.jp, 'JP/L', 'ink'), 'w'], T(o.romaji, 'Body/S', 'brand-text'), [T(o.vi, 'Body/M', 'ink'), 'w'],
    [F('H', { gap: 8, align: 'c' }, [o.staff ? btn('Đưa cho nhân viên xem', 'Soft', { size: 'S', icon: 'front_hand' }) : null, btn('Nghe', 'Secondary', { size: 'S', icon: 'volume_up' }), [sp(1, 1), 'g'], I('flag', 20, 'muted')]), 'w']]);
}
function s25(sec, x, y) {
  const s = screen(sec, '25 · Nhật ngữ (phrase_screen)', x, y);
  add(s, [[appBar('Nhật ngữ'), 'w']]);
  const sum = F('H', { name: 'Summary', fill: 'ink', r: 20, p: 16, gap: 14, align: 'c', clip: true }, [[F('V', { gap: 6 }, [T('ĐÃ THUỘC', 'Overline', 'lantern'), F('H', { gap: 4, align: 'b' }, [T('128', 'Display/XL', 'on-brand'), T('/ 620 mục', 'Body/S', 'on-brand')]), progress(21, 200, 'lantern', 'ink-deep', 8)]), 'g'], T('あ', 'JP/L', 'on-brand', { size: 64 })]);
  const g = (ic, tone, name, pct, label) => F('V', { name: 'GroupCard', fill: 'surface', stroke: 'line', r: 18, p: 14, gap: 8, w: 173 }, [[F('H', { gap: 4, align: 'c' }, [iconTile(ic, tone, 40), [sp(1, 1), 'g'], I('chevron_right', 20, 'muted')]), 'w'], [T(name, 'Title/S', 'ink'), 'w'], progress(pct, 145, 'brand'), T(label, 'Caption', 'muted')]);
  body(s, { gap: 14 }, [[T('Học trước những câu và từ bạn sẽ cần khi sống ở Nhật, theo loại địa điểm và chủ đề.', 'Body/S', 'muted'), 'w'],
    [search('Tìm câu tiếng Nhật, nghĩa, chủ đề'), 'w'],
    [F('H', { gap: 8 }, [[btn('Luyện tập', 'Primary', { size: 'M', icon: 'style' }), 'g'], btn('Chưa thuộc', 'Secondary', { size: 'M', icon: 'replay' }), btn('Đã thuộc', 'Secondary', { size: 'M', icon: 'task_alt' })]), 'w'],
    [sum, 'w'],
    [seg([['Chủ đề (12)', 'category'], ['Địa điểm (9)', 'location_on']], 0), 'w'],
    [F('H', { gap: 8, align: 'c' }, [T('Mẫu câu', 'Title/M', 'ink'), [T('420 mục · 96/420 đã thuộc', 'Caption', 'muted', { align: 'RIGHT' }), 'g']]), 'w'],
    F('H', { name: 'Groups', gap: 12, wrap: true, rowGap: 12, w: 358 }, [g('payments', 'brand', 'Thanh toán', 60, '18/30'), g('directions', 'ai', 'Hỏi đường', 25, '6/24'), g('local_hospital', 'ok', 'Khám bệnh', 10, '2/20'), g('storefront', 'lantern', 'Mua sắm', 45, '14/31')])]);
}
function s26(sec, x, y) {
  const s = screen(sec, '26 · Danh sách mẫu câu (phrase_list_screen)', x, y);
  add(s, [[appBar('Thanh toán', { sub: 'Chủ đề · 30 mục' }), 'w']]);
  body(s, { gap: 14 }, [[F('H', { gap: 12, align: 'c' }, [iconTile('payments', 'brand', 48, 16), [F('V', { gap: 6 }, [T('18/30 đã thuộc', 'Title/S', 'ink'), progress(60, 290, 'brand')]), 'g']]), 'w'],
    chips(['Tất cả (30)', 'Từ vựng (12)', 'Mẫu câu (18)'], 2),
    chips(['Tất cả (18)', 'Chưa thuộc (5)', 'Đã thuộc (11)', 'Chưa luyện (2)'], 0),
    [btn('Luyện thẻ ghi nhớ (18 thẻ)', 'Primary', { icon: 'style' }), 'w'],
    [phraseCard({ kind: 'Mẫu câu', cat: 'Cửa hàng tiện lợi', topic: 'Thanh toán', known: true, jp: 'カードで払えますか？', romaji: 'Kādo de haraemasu ka?', vi: 'Tôi trả bằng thẻ được không?', staff: true }), 'w'],
    [phraseCard({ kind: 'Mẫu câu', cat: 'Siêu thị', catIcon: 'shopping_cart', topic: 'Thanh toán', known: false, jp: '袋はいりません。', romaji: 'Fukuro wa irimasen.', vi: 'Tôi không cần túi ạ.', staff: true }), 'w'],
    [phraseCard({ kind: 'Mẫu câu', cat: 'Nhà hàng', catIcon: 'restaurant', topic: 'Thanh toán', known: false, jp: 'お会計をお願いします。', romaji: 'Okaikei o onegai shimasu.', vi: 'Cho tôi thanh toán.', staff: true }), 'w']]);
}
function s27(sec, x, y) {
  const s = screen(sec, '27 · Luyện tập (phrase_practice_screen)', x, y);
  add(s, [[appBar('Luyện tập'), 'w']]);
  body(s, { gap: 18 }, [[T('Chọn thẻ muốn luyện. Lật thẻ rồi chọn “Chưa thuộc” hoặc “Đã thuộc”.', 'Body/S', 'muted'), 'w'],
    [F('V', { gap: 8 }, [T('Luyện theo', 'Label/M', 'ink'), [seg(['Tất cả', 'Chủ đề', 'Địa điểm'], 1), 'w'], [dropdownField(null, 'Thanh toán (30)'), 'w']]), 'w'],
    F('V', { gap: 8 }, [T('Loại', 'Label/M', 'ink'), chips(['Cả hai (30)', 'Từ vựng (12)', 'Mẫu câu (18)'], 0)]),
    [F('V', { gap: 8 }, [T('Thẻ', 'Label/M', 'ink'), [chips(['Tất cả', 'Chưa thuộc', 'Đã thuộc', 'Chưa luyện'], 1, { wrap: true }), 'w']]), 'w'],
    [F('H', { name: 'Shuffle', fill: 'surface', stroke: 'line', r: 16, p: [12, 14], gap: 12, align: 'c' }, [iconTile('shuffle', 'ai', 36, 10), [T('Xáo trộn thứ tự thẻ', 'Title/S', 'ink'), 'g'], toggle(true)]), 'w'],
    [F('V', { name: 'Preview', fill: 'brand-soft', r: 20, p: 20, gap: 6, align: 'c' }, [I('style', 40, 'brand'), T('5 thẻ chưa thuộc', 'Title/M', 'brand-text'), T('khoảng 3 phút', 'Caption', 'brand-text')]), 'w']]);
  bottomBar(s, [[btn('Bắt đầu (5 thẻ)', 'Primary', { icon: 'play_arrow' }), 'g']]);
}
function s28(sec, x, y) {
  const s = screen(sec, '28 · Thẻ ghi nhớ (flashcard_screen)', x, y);
  add(s, [[appBar('Thẻ ghi nhớ · 3/5', { close: true }), 'w']]);
  const big = F('V', { name: 'Flashcard', fill: 'surface', stroke: 'line', r: 28, p: 24, gap: 14, h: 430, just: 'c', align: 'c', shadow: true }, [
    [F('H', { gap: 6, align: 'c' }, [badge('Mẫu câu · Thanh toán', 'brand'), [sp(1, 1), 'g'], badge('Chưa thuộc', 'lantern', 'replay')]), 'w'],
    [sp(1, 1), 'g'],
    [T('カードで払えますか？', 'JP/L', 'ink', { size: 34, align: 'CENTER' }), 'w'],
    [divider(), 'w'],
    [T('Kādo de haraemasu ka?', 'Title/M', 'brand-text', { align: 'CENTER' }), 'w'],
    [T('Tôi trả bằng thẻ được không?', 'Body/M', 'ink', { align: 'CENTER' }), 'w'],
    [sp(1, 1), 'g'],
    F('H', { fill: 'surface-2', r: 99, p: [8, 14], gap: 6, align: 'c' }, [I('volume_up', 20, 'ink'), T('Nghe', 'Label/M', 'ink')])]);
  body(s, { gap: 16 }, [progress(60, 358, 'brand', null, 6), [big, 'w'], [T('Bấm vào thẻ để lật lại', 'Caption', 'muted', { align: 'CENTER' }), 'w'],
    [F('H', { gap: 12 }, [[btn('Chưa thuộc', 'Secondary', { icon: 'replay' }), 'g'], [btn('Đã thuộc', 'Primary', { icon: 'task_alt' }), 'g']]), 'w']]);
}
function s29(sec, x, y) {
  const s = screen(sec, '29 · Đưa cho nhân viên xem (phrase_staff_screen)', x, y, { bg: 'surface' });
  add(s, [[appBar('Đưa cho nhân viên xem', { close: true }), 'w']]);
  body(s, { p: [24, 24, 40, 24], gap: 24, just: 'c', align: 'c' }, [badge('Đưa màn hình này cho nhân viên', 'lantern', 'front_hand'),
    [F('V', { name: 'Phrase', fill: 'brand-soft', r: 32, p: [40, 20], gap: 20, align: 'c' }, [[T('カードで払えますか？', 'JP/L', 'ink', { size: 40, align: 'CENTER' }), 'w'], [T('Tôi trả bằng thẻ được không?', 'Body/M', 'brand-text', { align: 'CENTER' }), 'w']]), 'w'],
    [F('H', { gap: 12 }, [[btn('Nghe phát âm', 'Secondary', { icon: 'volume_up' }), 'g'], [btn('Đóng', 'Primary'), 'g']]), 'w'],
    [T('Màn hình luôn sáng khi đang mở.', 'Caption', 'muted', { align: 'CENTER' }), 'w']]);
}

// ================= SECTION 7 · Tin nhắn =================
function s30(sec, x, y) {
  const s = screen(sec, '30 · Tin nhắn (conversation_list_screen)', x, y);
  add(s, [[appBar('Tin nhắn', { actions: ['block'] }), 'w'], [tabs([['Tin nhắn', null], ['Lời mời', '2']], 0), 'w']]);
  const tile = (init, tone, name, preview, time, unread, o) => {
    o = o || {};
    const prev = F('H', { gap: 4, align: 'c' }, [o.icon ? I(o.icon, 16, 'muted') : null, [T(preview, 'Body/S', unread ? 'ink' : 'muted', { lines: 1 }), 'g']]);
    return F('H', { name: 'ConversationTile', gap: 12, p: [10, 10], r: 16, align: 'c', fill: unread ? 'surface' : null }, [avatar(init, 52, tone), [F('V', { gap: 2 }, [
      [F('H', { gap: 6, align: 'c' }, [T(name, unread ? 'Title/S' : 'Label/M', 'ink'), o.blocked ? badge('Đã chặn', 'crit') : null, [T(time, 'Caption', unread ? 'brand-text' : 'muted', { align: 'RIGHT' }), 'g']]), 'w'],
      [F('H', { gap: 8, align: 'c' }, [[prev, 'g'], unread ? badge(unread, 'solid') : null]), 'w']]), 'g']]);
  };
  body(s, { p: [8, 8, 24, 8], gap: 2 }, [[tile('V', 'brand', 'Thảo Vy', 'Không em ơi, xe buýt Koedo Loop mua vé ngày riêng nhé.', '2 phút', '2'), 'w'],
    [tile('H', 'ok', 'Quang Huy', 'Bạn: Em cảm ơn anh nhiều ạ!', '1 giờ', null), 'w'],
    [tile('M', 'lantern', 'Mai', 'Tin nhắn đã mã hóa', 'hôm qua', null, { icon: 'lock' }), 'w'],
    [tile('K', 'ai', 'Khánh', 'Tệp đính kèm', 'T2', null, { icon: 'attach_file' }), 'w'],
    [tile('T', 'neutral', 'Tuấn', 'Tin nhắn đã được thu hồi', '12/10', null, { icon: 'undo' }), 'w'],
    [tile('P', 'crit', 'Phong', 'Bạn đã thu hồi một tin nhắn', '3/10', null, { blocked: true }), 'w'],
    [F('H', { just: 'c', p: [8, 0] }, [btn('Xem thêm', 'Ghost', { size: 'S' })]), 'w']]);
}
function bubble(mine, text, meta, quote) {
  const long = text.length * 7.4 > 240;
  const b = F('V', { name: mine ? 'Bubble/mine' : 'Bubble/theirs', fill: mine ? 'brand' : 'surface', stroke: mine ? null : 'line', r: 18, p: [10, 14], gap: 4, align: mine ? 'e' : 'MIN' }, [
    quote ? F('V', { name: 'quote', fill: mine ? 'brand-strong' : 'surface-2', r: 10, p: [6, 10], gap: 0 }, [T(quote[0], 'Label/S', mine ? 'on-brand' : 'brand-text'), T(quote[1], 'Caption', mine ? 'on-brand' : 'muted', { lines: 1 })]) : null,
    T(text, 'Body/M', mine ? 'on-brand' : 'ink', long ? { w: 240 } : {}),
    T(meta, 'Caption', mine ? 'on-brand' : 'muted')]);
  if (mine) b.bottomRightRadius = 6; else b.bottomLeftRadius = 6;
  return F('H', { name: 'msgRow', just: mine ? 'e' : 'MIN' }, [b]);
}
function s31(sec, x, y) {
  const s = screen(sec, '31 · Trò chuyện (chat_screen)', x, y);
  add(s, [[appBar('Thảo Vy', { sub: 'Đã đi làm · Senpai vàng', lead: avatar('V', 36, 'brand'), actions: ['more_vert'] }), 'w']]);
  const react = F('H', { name: 'msgRow', just: 'MIN', p: [0, 0, 0, 12] }, [F('H', { name: 'reaction', fill: 'surface', stroke: 'line', r: 99, p: [2, 8], gap: 4, align: 'c' }, [I('thumb_up', 14, 'brand', true), T('1', 'Label/S', 'ink')])]);
  body(s, { p: [8, 16, 16, 16], gap: 10 }, [[note('shield', 'Senpai ơi không bao giờ hỏi mật khẩu hay mã OTP. Đừng gửi ảnh thẻ cư trú, hộ chiếu, số tài khoản hay chuyển tiền cho người bạn chưa gặp.', 'ai'), 'w'],
    [F('H', { just: 'c' }, [badge('Hôm nay', 'neutral')]), 'w'],
    [bubble(false, 'Chào em, chị thấy em hỏi về Kawagoe ở bài viết nè.', '09:12'), 'w'],
    [bubble(true, 'Dạ chị, pass 700 yên có dùng cho xe buýt vòng quanh phố cổ không ạ?', '09:14 · Đã xem'), 'w'],
    [bubble(false, 'Không em ơi, xe buýt Koedo Loop mua vé ngày riêng 500 yên nhé. Đi bộ cũng được, phố cổ nhỏ lắm.', '09:20', ['Linh', 'pass 700 yên có dùng cho xe buýt…']), 'w'],
    [react, 'w'],
    [bubble(true, 'Em cảm ơn chị nhiều!', '09:21 · Đã gửi'), 'w'],
    T('Thảo Vy đang soạn tin…', 'Caption', 'muted')]);
  bottomBar(s, [[composer('Nhập tin nhắn…'), 'g']]);
}
// ================= SECTION 8 · Tài khoản =================
function authFooter(q, link) { return F('H', { name: 'footer', gap: 4, just: 'c', align: 'c' }, [T(q, 'Body/S', 'muted'), T(link, 'Label/M', 'brand-text')]); }
function s32(sec, x, y) {
  const s = screen(sec, '32 · Đăng nhập (login_screen)', x, y);
  add(s, [[appBar('Đăng nhập'), 'w']]);
  const logo = inst('Logo'); logo.rescale(1.5);
  body(s, { p: [12, 24, 24, 24], gap: 18 }, [logo,
    [F('V', { gap: 6 }, [[T('Chào mừng bạn quay lại Senpai ơi.', 'Display/L', 'ink'), 'w'], [T('Đăng nhập để lưu địa điểm, viết review và hỏi các senpai.', 'Body/M', 'muted'), 'w']]), 'w'],
    [field('Email', 'linh.nguyen@gmail.com', { icon: 'mail' }), 'w'],
    [field('Mật khẩu', '••••••••••', { icon: 'lock', trail: 'visibility', state: 'Focus' }), 'w'],
    [F('H', { just: 'e' }, [T('Quên mật khẩu?', 'Label/M', 'brand-text')]), 'w'],
    [btn('Đăng nhập', 'Primary'), 'w'],
    [authFooter('Chưa có tài khoản?', 'Đăng ký'), 'w'],
    cover('Fuji', 342, 150, 20)]);
}
function s33(sec, x, y) {
  const s = screen(sec, '33 · Đăng ký — bước 2 Mã xác thực (register_screen)', x, y);
  add(s, [[appBar('Đăng ký'), 'w']]);
  const box = (d, focus) => F('H', { name: 'otp', fill: 'surface', stroke: focus ? 'brand' : 'line', sw: focus ? 2 : 1, r: 12, w: 50, h: 58, just: 'c', align: 'c' }, [d ? T(d, 'Display/M', 'ink') : null]);
  body(s, { p: [8, 24, 24, 24], gap: 20 }, [[F('V', { gap: 4 }, [T('Tạo tài khoản', 'Display/L', 'ink'), [T('Miễn phí, dành cho người từ 18 tuổi. Chỉ mất khoảng một phút.', 'Body/S', 'muted'), 'w']]), 'w'],
    [stepper(['Email', 'Mã xác thực', 'Mật khẩu'], 1), 'w'],
    [F('H', { name: 'email', fill: 'surface', stroke: 'line', r: 14, p: [10, 14], gap: 10, align: 'c' }, [I('mail', 20, 'muted'), [T('linh.nguyen@gmail.com', 'Body/M', 'ink'), 'g'], T('Đổi', 'Label/M', 'brand-text')]), 'w'],
    [F('V', { gap: 8 }, [T('Mã xác thực', 'Label/M', 'ink'), F('H', { gap: 8 }, [box('4'), box('8'), box('2'), box('9'), box(null, true), box(null)]), [T('Mã có hiệu lực trong 10 phút. Nhớ kiểm tra cả hộp thư Spam.', 'Caption', 'muted'), 'w']]), 'w'],
    F('H', { gap: 4, align: 'c' }, [T('Chưa nhận được mã?', 'Body/S', 'muted'), T('Gửi lại sau 45s', 'Label/M', 'muted')]),
    [btn('Xác nhận', 'Primary'), 'w'],
    [authFooter('Đã có tài khoản?', 'Đăng nhập'), 'w']]);
}
function s34(sec, x, y) {
  const s = screen(sec, '34 · Quên mật khẩu — bước 2 (forgot_password_screen)', x, y);
  add(s, [[appBar('Quên mật khẩu'), 'w']]);
  body(s, { p: [8, 24, 24, 24], gap: 20 }, [iconTile('lock_reset', 'brand', 64, 20),
    [stepper(['Email', 'Dán đường link', 'Mật khẩu mới'], 1), 'w'],
    [T('Mở email “Đặt lại mật khẩu”, sao chép đường link trong thư rồi dán vào ô dưới đây. Đường link chỉ dùng được một lần.', 'Body/M', 'muted'), 'w'],
    [field('Đường link trong email', 'http://…/reset-password?token=…', { placeholder: true, icon: 'link', trail: 'content_paste' }), 'w'],
    [btn('Tiếp tục', 'Primary'), 'w'],
    [btn('Gửi lại liên kết', 'Ghost'), 'w'],
    [F('H', { just: 'c' }, [linkText('Quay lại Đăng nhập', 'arrow_back')]), 'w']]);
}
function s35(sec, x, y) {
  const s = screen(sec, '35 · Tôi (profile_screen)', x, y);
  add(s, [[appBar('Tôi'), 'w']]);
  const head = F('V', { name: 'Header', fill: 'surface', stroke: 'line', r: 24, p: 16, gap: 12 }, [
    [F('H', { gap: 14, align: 'c' }, [avatar('L', 64, 'lantern'), [F('V', { gap: 6 }, [T('Linh Nguyễn', 'Display/M', 'ink'), F('H', { gap: 6, wrap: true, rowGap: 6 }, [outlineBadge('Du học sinh', 'brand-text', 'school'), badge('Thành viên', 'neutral')])]), 'g']]), 'w'],
    [T('linh.nguyen@gmail.com · Đăng nhập bằng: Email và mật khẩu, Google', 'Caption', 'muted'), 'w']]);
  const pts = F('V', { name: 'Points', fill: 'brand', r: 24, p: 18, gap: 12, clip: true }, [
    [F('H', { gap: 8, align: 'c' }, [[F('V', { gap: 0 }, [T('ĐIỂM CỦA BẠN', 'Overline', 'on-brand'), T('1.250 điểm', 'Display/XL', 'on-brand')]), 'g'], F('H', { fill: 'surface', r: 99, p: [6, 12], gap: 4, align: 'c' }, [I('military_tech', 18, 'lantern-text'), T('Senpai bạc', 'Label/M', 'brand-text')])]), 'w'],
    progress(62, 322, 'lantern', 'brand-strong', 10),
    [T('Còn 750 điểm nữa lên Senpai vàng', 'Body/S', 'on-brand'), 'w'],
    [T('Review +10 · Ghim được duyệt +15 · Câu trả lời hay nhất +5 · Bài bị gỡ −20', 'Caption', 'on-brand'), 'w'],
    [F('H', { gap: 6, align: 'c', fill: 'surface', op: 0.16, r: 12, p: [10, 12] }, [I('history', 18, 'on-brand'), [T('Lịch sử điểm', 'Label/M', 'on-brand'), 'g'], I('chevron_right', 20, 'on-brand')]), 'w']]);
  const deco = inst('Logo'); deco.rescale(3); deco.opacity = 0.14; abs(pts, deco, 270, -34);
  const rank = (name, from, ok) => F('V', { name: 'rank', fill: ok ? 'lantern-soft' : 'surface', stroke: 'line', r: 14, p: 10, gap: 2, w: 82 }, [I('military_tech', 20, ok ? 'lantern-text' : 'muted'), [T(name, 'Label/S', 'ink'), 'w'], [T(ok ? 'Đã đạt' : 'từ ' + from, 'Caption', ok ? 'ok' : 'muted'), 'w']]);
  const ic = (n, tone) => iconTile(n, tone || 'brand', 36, 10);
  const b = body(s, { gap: 16 }, [[head, 'w'], [pts, 'w'],
    F('H', { gap: 8 }, [rank('Mới', '0', true), rank('Đồng', '200', true), rank('Bạc', '800', true), rank('Vàng', '2.000', false)]),
    [group([listRow(ic('verified'), 'Xin tag định danh', 'Thêm tag để mọi người biết bạn là ai'), listRow(ic('person_pin_circle'), 'Khu vực và giai đoạn', 'Mới đến · Arakawa-ku, Tokyo'), listRow(ic('interests'), 'Chủ đề quan tâm', 'Nhà ở, Việc làm thêm, Ẩm thực'), listRow(ic('menu_book'), 'Cẩm nang của tôi', null), listRow(ic('bookmarks'), 'Đã lưu (14)', null)]), 'w'],
    [group([listRow(ic('password', 'neutral'), 'Đổi mật khẩu', null), listRow(ic('logout', 'neutral'), 'Đăng xuất', null), listRow(ic('delete', 'crit'), 'Xóa tài khoản', null, { titleColor: 'crit' })]), 'w']]);
  fitH(s, b);
}
function s36(sec, x, y) {
  const s = screen(sec, '36 · Lịch sử điểm (point_history_screen)', x, y);
  add(s, [[appBar('Lịch sử điểm'), 'w']]);
  const row = (d, reason, title, date, neg) => F('H', { name: 'PointRow', gap: 12, p: [12, 0], align: 'c' }, [F('H', { fill: neg ? 'crit-soft' : 'brand-soft', r: 12, w: 56, h: 40, just: 'c', align: 'c' }, [T(d, 'Label/M', neg ? 'crit' : 'brand-text')]), [F('V', { gap: 1 }, [T(reason, 'Title/S', 'ink'), [T(title, 'Body/S', 'muted', { lines: 1 }), 'w'], T(date, 'Caption', 'muted')]), 'g']]);
  body(s, { gap: 14 }, [[F('H', { name: 'Summary', fill: 'ink', r: 20, p: 16, gap: 12, align: 'c' }, [iconTile('military_tech', 'lantern', 48, 16), [F('V', { gap: 2 }, [T('Bạn có 1.250 điểm', 'Title/M', 'on-brand'), T('38 lần cộng / trừ', 'Caption', 'on-brand')]), 'g']]), 'w'],
    T('THÁNG 11/2026', 'Overline', 'muted'),
    [group([row('+5', 'Câu trả lời hay nhất', 'Gia hạn visa du học cần mang những giấy tờ gì?', '8/11/2026'), row('+15', 'Ghim được duyệt', 'Chùa Sensō-ji cổng sau', '8/11/2026'), row('+10', 'Review', 'Gyomu Super Minami-Senju', '7/11/2026'), row('−20', 'Bài bị gỡ', 'Nội dung không còn', '2/11/2026', true)]), 'w'],
    T('THÁNG 10/2026', 'Overline', 'muted'),
    [group([row('+10', 'Review', 'Ga Machiya (Chiyoda Line)', '28/10/2026'), row('+10', 'Review', 'Phòng khám Nishi-Nippori', '15/10/2026')]), 'w']]);
}
function s37(sec, x, y) {
  const s = screen(sec, '37 · Đã lưu (saved_screen)', x, y);
  add(s, [[appBar('Đã lưu'), 'w'], [tabsScroll(['Địa điểm (5)', 'Bài viết (6)', 'Câu hỏi (2)', 'Cẩm nang (1)'], 1), 'w']]);
  const sv = (topic, time, title, author, likes, cmts) => card({ name: 'SavedPost', r: 18, p: 14, gap: 8 }, [
    [F('H', { gap: 6, align: 'c' }, [badge(topic, 'brand'), [T(time, 'Caption', 'muted', { align: 'RIGHT' }), 'g']]), 'w'],
    [T(title, 'Title/S', 'ink'), 'w'],
    [F('H', { gap: 8, align: 'c' }, [[T(author, 'Label/S', 'muted'), 'g'], iconStat('favorite', likes), iconStat('chat_bubble', cmts), F('H', { name: 'unsave', fill: 'brand-soft', r: 99, w: 32, h: 32, just: 'c', align: 'c' }, [I('bookmark_remove', 18, 'brand-text')])]), 'w']]);
  body(s, { p: [12, 16, 24, 16], gap: 12 }, [[sv('Du lịch', 'hôm qua', 'Đi Kawagoe một ngày: tiểu Edo cách Tokyo 30 phút', 'Thảo Vy', '88', '21'), 'w'],
    [sv('Nhà ở', '2 ngày trước', 'Thuê nhà không cần người bảo lãnh ở Tokyo', 'Minh Anh', '24', '8'), 'w'],
    [sv('Thủ tục', '1 tuần trước', 'Checklist 2 tuần đầu: SIM, ngân hàng, My Number', 'Tuấn', '41', '12'), 'w']]);
  const snack = F('H', { name: 'Snackbar', fill: 'ink', r: 14, p: [12, 16], gap: 12, align: 'c', w: 358, shadow: 'Shadow/Float' }, [[T('Đã bỏ lưu bài viết.', 'Body/S', 'on-brand'), 'g'], T('Hoàn tác', 'Label/M', 'lantern')]);
  abs(s, snack, 16, 0); snack.y = s.height - 34 - snack.height;
}

// ================= SECTION 9 · Cài đặt cá nhân =================
function s38(sec, x, y) {
  const s = screen(sec, '38 · Khu vực và giai đoạn (area_stage_screen)', x, y);
  add(s, [[appBar('Khu vực và giai đoạn'), 'w']]);
  const st = (ic, label, on) => F('V', { name: 'stageTile', fill: on ? 'brand-soft' : 'surface', stroke: on ? 'brand' : 'line', sw: on ? 2 : 1, r: 16, p: 12, gap: 6, w: 173 }, [I(ic, 24, on ? 'brand-text' : 'muted'), T(label, 'Label/M', on ? 'brand-text' : 'ink')]);
  const b = body(s, { gap: 18 }, [[note('lock', 'Không bắt buộc. Dùng để gợi ý việc cần làm, review và sự kiện gần bạn. Chỉ lưu khu vực, không lưu địa chỉ; chỉ mình bạn thấy.', 'ai'), 'w'],
    F('V', { gap: 10 }, [T('Giai đoạn', 'Title/S', 'ink'), F('H', { gap: 12, wrap: true, rowGap: 12, w: 358 }, [st('flight_takeoff', 'Sắp sang Nhật'), st('flight_land', 'Mới đến', true), st('luggage', 'Sắp về nước'), st('home', 'Đã về nước')])]),
    [F('V', { gap: 10 }, [T('Khu vực bạn đang sống', 'Title/S', 'ink'), [F('H', { name: 'current', fill: 'surface', stroke: 'line', r: 14, p: [12, 14], gap: 10, align: 'c' }, [I('place', 22, 'brand'), [F('V', { gap: 0 }, [T('Arakawa-ku', 'Title/S', 'ink'), T('荒川区 · Tokyo', 'Caption', 'muted')]), 'g'], I('close', 20, 'muted')]), 'w']]), 'w'],
    [field('Tìm khu vực theo tên', 'Tìm nhanh: Arakawa, 荒川, Osaka…', { placeholder: true, icon: 'search' }), 'w'],
    [F('V', { gap: 6 }, [[btn('Vị trí của tôi', 'Secondary', { icon: 'my_location' }), 'w'], [T('Vị trí chỉ dùng để gợi ý khu vực, không được lưu.', 'Caption', 'muted'), 'w']]), 'w'],
    [F('H', { gap: 10 }, [[dropdownField('Tỉnh / thành phố', 'Tokyo'), 'g'], [dropdownField('Quận / thành phố', 'Arakawa-ku'), 'g']]), 'w'],
    [T('Danh sách khu vực: Geolonia 住所データ (CC BY 4.0), dựa trên dữ liệu của デジタル庁.', 'Caption', 'muted'), 'w']]);
  bottomBar(s, [[btn('Lưu', 'Primary'), 'g']]);
  fitH(s, b);
}
function s39(sec, x, y) {
  const s = screen(sec, '39 · Chủ đề quan tâm (interest_screen)', x, y);
  add(s, [[appBar('Chủ đề quan tâm'), 'w']]);
  body(s, { gap: 16 }, [T('Không bắt buộc. Chỉ mình bạn thấy.', 'Body/S', 'muted'),
    [note('auto_awesome', 'Chọn tối đa 5 chủ đề. Bài thuộc các chủ đề này được gợi ý trước trong “Dành cho bạn”. Đã chọn 3/5.', 'brand'), 'w'],
    [chips([['Nhà ở', 'home'], ['Việc làm thêm', 'work'], ['Ẩm thực', 'restaurant'], ['Thủ tục', 'description'], ['Visa', 'badge'], ['Ngân hàng', 'account_balance'], ['Y tế', 'local_hospital'], ['Du lịch', 'history'], ['Học tiếng Nhật', 'translate'], ['Đi lại', 'train'], ['Mua sắm', 'shopping_bag'], ['Cảnh báo lừa đảo', 'gpp_maybe'], ['Khác', 'more_horiz']], -1, { wrap: true, multi: [0, 1, 2] }), 'w'],
    [F('H', { gap: 8, align: 'c' }, [I('history', 18, 'muted'), [T('Gợi ý: chủ đề bạn hay đọc, thích hoặc lưu gần đây.', 'Caption', 'muted'), 'g']]), 'w']]);
  bottomBar(s, [[btn('Lưu', 'Primary'), 'g']]);
}
function s40(sec, x, y) {
  const s = screen(sec, '40 · Xin tag định danh (tag_request_screen)', x, y);
  add(s, [[appBar('Xin tag định danh'), 'w']]);
  const opt = (on, tag, desc, owned) => F('H', { name: 'tagOption', fill: on ? 'brand-soft' : 'surface', stroke: on ? 'brand' : 'line', sw: on ? 2 : 1, r: 16, p: 14, gap: 12 }, [radio(on), [F('V', { gap: 4 }, [F('H', { gap: 6, align: 'c' }, [outlineBadge(tag, on ? 'brand-text' : 'ink'), owned ? badge('Đã có', 'ok', 'check') : null]), [T(desc, 'Body/S', 'muted'), 'w']]), 'g']]);
  const b = body(s, { gap: 16 }, [[T('Tag cho mọi người biết bạn là ai (đang du học, đã đi làm, giáo viên…). Moderator đối chiếu ảnh minh chứng rồi mới cấp tag.', 'Body/S', 'muted'), 'w'],
    T('Chọn tag', 'Title/S', 'ink'),
    [opt(false, 'Du học sinh', 'Đang học ở trường tiếng, senmon, đại học.', true), 'w'],
    [opt(true, 'Đã đi làm', 'Đang làm việc toàn thời gian ở Nhật.'), 'w'],
    [opt(false, 'Giáo viên', 'Dạy tiếng Nhật hoặc dạy ở trường tại Nhật.'), 'w'],
    [dropdownField('Loại minh chứng', 'Thẻ nhân viên / hợp đồng lao động'), 'w'],
    [photoPicker('Ảnh minh chứng', 0, 1, []), 'w'],
    [T('JPG, PNG hoặc HEIC, tối đa 10 MB. Có thể che số thẻ và thông tin không cần thiết, chỉ cần thấy tên và loại giấy tờ.', 'Caption', 'muted'), 'w'],
    [checkbox(true, 'Tôi đồng ý cho Kiểm duyệt viên xem ảnh này. Ảnh sẽ bị xóa sau khi duyệt hoặc sau 14 ngày.', { top: true }), 'w']]);
  bottomBar(s, [[btn('Gửi yêu cầu', 'Primary', { icon: 'send' }), 'g']]);
  fitH(s, b);
}
function s41(sec, x, y) {
  const s = screen(sec, '41 · Đổi mật khẩu (change_password_screen)', x, y);
  add(s, [[appBar('Đổi mật khẩu'), 'w']]);
  const rule = (ok, label) => F('H', { name: 'rule', gap: 8, align: 'c' }, [I(ok ? 'check_circle' : 'radio_button_unchecked', 18, ok ? 'ok' : 'muted', ok), T(label, 'Body/S', ok ? 'ok' : 'muted')]);
  body(s, { gap: 16 }, [[note('info', 'Đổi mật khẩu sẽ đăng xuất bạn khỏi các thiết bị khác.', 'ai'), 'w'],
    [field('Mật khẩu hiện tại', '••••••••', { icon: 'lock', trail: 'visibility' }), 'w'],
    [field('Mật khẩu mới', '••••••••••', { icon: 'lock', trail: 'visibility_off', state: 'Focus' }), 'w'],
    F('V', { gap: 6 }, [rule(true, 'Từ 8 ký tự'), rule(true, 'Có chữ'), rule(false, 'Có số')]),
    [field('Nhập lại mật khẩu mới', 'Nhập lại để xác nhận', { icon: 'lock', placeholder: true }), 'w']]);
  bottomBar(s, [[btn('Lưu mật khẩu', 'Primary'), 'g']]);
}
function s42(sec, x, y) {
  const s = screen(sec, '42 · Xóa tài khoản (delete_account_screen)', x, y);
  add(s, [[appBar('Xóa tài khoản'), 'w']]);
  const rm = (t) => F('H', { name: 'consequence', gap: 10, p: [12, 0] }, [I('remove_circle', 20, 'crit'), [T(t, 'Body/S', 'ink'), 'g']]);
  body(s, { p: [16, 24, 24, 24], gap: 18 }, [[F('V', { gap: 8, align: 'c' }, [iconTile('warning', 'crit', 72, 36), T('Xóa tài khoản?', 'Display/L', 'ink'), T('linh.nguyen@gmail.com', 'Body/M', 'muted')]), 'w'],
    [group([rm('Hồ sơ, điểm và tag bị xóa; yêu cầu tag đang chờ và ảnh minh chứng bị hủy.'), rm('Bạn sẽ bị đăng xuất và không thể khôi phục.'), rm('Bài viết, câu hỏi, bình luận, câu trả lời và tin nhắn của bạn sẽ bị ẩn với mọi người; review của bạn được xóa hoặc ẩn danh.')]), 'w'],
    [btn('Xóa tài khoản', 'Danger', { icon: 'delete_forever' }), 'w'],
    [btn('Hủy', 'Secondary'), 'w']]);
}
function s43(sec, x, y) {
  const s = screen(sec, '43 · Điều khoản sử dụng (legal_screen) — nội dung mẫu', x, y);
  add(s, [[appBar('Điều khoản sử dụng'), 'w']]);
  const sect = (h, p) => F('V', { gap: 4 }, [[T(h, 'Title/S', 'ink'), 'w'], [T(p, 'Body/S', 'ink'), 'w']]);
  body(s, { gap: 14 }, [badge('Phiên bản 2.1 · cập nhật 1/10/2026', 'neutral', 'history'),
    [card({ name: 'LegalText', r: 18, p: 18, gap: 16 }, [[sect('1. Phạm vi áp dụng', 'Điều khoản này áp dụng cho mọi người dùng Senpai ơi trên web và ứng dụng di động.'), 'w'],
      [sect('2. Tài khoản', 'Bạn cần từ 18 tuổi trở lên để đăng ký. Mỗi người chỉ dùng một tài khoản và tự bảo mật mật khẩu của mình.'), 'w'],
      [sect('3. Nội dung bạn đăng', 'Bài viết, review và ảnh phải đúng sự thật và tuân thủ Quy tắc cộng đồng. Nội dung vi phạm có thể bị ẩn hoặc gỡ, kèm trừ điểm.'), 'w'],
      [sect('4. Quyền riêng tư', 'Chúng tôi chỉ lưu khu vực bạn chọn, không lưu vị trí chính xác. Xem chi tiết trong Chính sách bảo mật.'), 'w']]), 'w'],
    [T('Nội dung thật lấy từ máy chủ; đoạn trên chỉ để minh hoạ cách trình bày.', 'Caption', 'muted'), 'w']]);
}
// ================= chạy =================
const PLAN = [
  ['2', 2, s09], ['2', 3, s10], ['2', 4, s11],
  ['3', 0, s12], ['3', 1, s13], ['3', 2, s14],
  ['4', 0, s15], ['4', 1, s16], ['4', 2, s17], ['4', 3, s18],
  ['5', 0, s19], ['5', 1, s20], ['5', 2, s21], ['5', 3, s22], ['5', 4, s23], ['5', 5, s24],
  ['6', 0, s25], ['6', 1, s26], ['6', 2, s27], ['6', 3, s28], ['6', 4, s29],
  ['7', 0, s30], ['7', 1, s31],
  ['8', 0, s32], ['8', 1, s33], ['8', 2, s34], ['8', 3, s35], ['8', 4, s36], ['8', 5, s37],
  ['9', 0, s38], ['9', 1, s39], ['9', 2, s40], ['9', 3, s41], ['9', 4, s42], ['9', 5, s43]
];
const SCREEN_X = k => 60 + k * 450, SCREEN_Y = 160;

function polishHome(secs) {
  // Material Symbols không chắc có tên cũ *_border: đổi về tên gốc (viền là mặc định).
  for (const k of ['1', '2']) {
    if (!secs[k]) continue;
    for (const t of secs[k].findAllWithCriteria({ types: ['TEXT'] })) {
      const fn = t.fontName;
      if (fn && fn.family === 'Material Symbols Rounded' && /_border$/.test(t.characters)) t.characters = t.characters.replace(/_border$/, '');
    }
  }
  const sec = secs['1']; if (!sec) return;
  const home = sec.children.find(n => n.type === 'FRAME' && n.name.indexOf('01 ·') === 0); if (!home) return;
  const feats = home.findOne(n => n.name === 'Features' && n.type === 'FRAME');
  if (feats) { const tiles = feats.children.filter(n => n.type === 'FRAME'); const h = Math.max.apply(null, tiles.map(t => t.height)); for (const t of tiles) t.resize(t.width, h); }
  const foot = home.findOne(n => n.name === 'Footer' && n.type === 'FRAME');
  if (foot) { foot.layoutWrap = 'WRAP'; foot.counterAxisSpacing = 4; foot.counterAxisAlignContent = 'AUTO'; }
}
function layoutSections(page) {
  const list = page.children.filter(n => n.type === 'SECTION' && /^\d+\s·/.test(n.name)).sort((a, b) => parseInt(a.name, 10) - parseInt(b.name, 10));
  let cy = 0;
  for (const sec of list) {
    let maxR = 0, maxB = 0;
    for (const c of sec.children) { maxR = Math.max(maxR, c.x + c.width); maxB = Math.max(maxB, c.y + c.height); }
    sec.x = 0; sec.y = cy;
    sec.resizeWithoutConstraints(Math.max(2780, maxR + 60), maxB + 100);
    cy += sec.height + 200;
  }
}
async function linkStyles() {
  let n = 0;
  const run = async (list, fn) => { for (let i = 0; i < list.length; i += 200) { await Promise.all(list.slice(i, i + 200).map(p => (p[0].removed ? null : fn(p[0], p[1]).then(() => { n++; }).catch(() => {})))); } };
  await run(LINK_T, (node, id) => node.setTextStyleIdAsync(id));
  await run(LINK_E, (node, id) => node.setEffectStyleIdAsync(id));
  return n;
}
function writeErrorReport(page, done) {
  const f = figma.createFrame(); f.name = '⚠️ Báo lỗi plugin — gửi nội dung này cho Claude';
  f.layoutMode = 'VERTICAL'; f.primaryAxisSizingMode = 'AUTO'; f.counterAxisSizingMode = 'FIXED'; f.resize(900, 100);
  f.paddingTop = f.paddingBottom = f.paddingLeft = f.paddingRight = 32; f.itemSpacing = 8; f.cornerRadius = 24;
  f.fills = [{ type: 'SOLID', color: { r: 0.984, g: 0.882, b: 0.875 } }];
  const t = figma.createText(); t.fontName = { family: 'Inter', style: 'Regular' }; t.fontSize = 16;
  t.characters = 'Vẽ xong ' + done + '/' + PLAN.length + ' màn. Lỗi:\n\n' + ERRORS.join('\n');
  f.appendChild(t); t.layoutSizingHorizontal = 'FILL';
  page.appendChild(f); f.x = 0; f.y = -800;
}
async function main() {
  figma.notify('Đang vẽ 35 màn hình… (khoảng 1 phút)', { timeout: 60000 });
  await initLib();
  const page = figma.root.children.find(p => p.name.indexOf('Màn hình') >= 0) || figma.root.children[0];
  await figma.setCurrentPageAsync(page);
  const secs = {};
  for (const n of page.children) { if (n.type === 'SECTION') { const m = n.name.match(/^(\d+)\s·/); if (m) secs[m[1]] = n; } }
  const missing = PLAN.map(p => p[0]).filter((k, i, a) => a.indexOf(k) === i && !secs[k]);
  if (missing.length) throw new Error('Thiếu section: ' + missing.join(', '));
  // xoá màn do lần chạy trước tạo (09–43)
  for (const k in secs) for (const c of secs[k].children.slice()) { const m = c.type === 'FRAME' && c.name.match(/^(\d\d) ·/); if (m && parseInt(m[1], 10) >= 9) c.remove(); }
  const oldErr = page.children.filter(n => n.name.indexOf('⚠️ Báo lỗi plugin') === 0); oldErr.forEach(n => n.remove());
  let done = 0;
  for (const [k, slot, fn] of PLAN) {
    const sec = secs[k]; const before = sec.children.length;
    try { fn(sec, SCREEN_X(slot), SCREEN_Y); done++; }
    catch (e) {
      ERRORS.push(fn.name + ': ' + (e && e.message ? e.message : String(e)) + (e && e.stack ? '\n   ' + String(e.stack).split('\n').slice(0, 3).join(' | ') : ''));
      while (sec.children.length > before) sec.children[sec.children.length - 1].remove();
    }
  }
  try { polishHome(secs); } catch (e) { ERRORS.push('polishHome: ' + e.message); }
  let linked = 0;
  try { linked = await linkStyles(); } catch (e) { ERRORS.push('linkStyles: ' + e.message); }
  try { layoutSections(page); } catch (e) { ERRORS.push('layoutSections: ' + e.message); }
  try { const h = await figma.getNodeByIdAsync('3:2'); if (h && h.name.indexOf('__lib') === 0) h.remove(); } catch (e) { ERRORS.push('xoá __lib: ' + e.message); }
  if (ERRORS.length) writeErrorReport(page, done);
  figma.viewport.scrollAndZoomIntoView(page.children.filter(n => n.type === 'SECTION'));
  return { done, linked };
}
main().then(r => {
  figma.closePlugin(ERRORS.length ? ('Xong ' + r.done + '/' + PLAN.length + ' màn, có ' + ERRORS.length + ' lỗi — xem khung ⚠️ phía trên cùng.') : ('Xong! Đã vẽ ' + r.done + ' màn hình.'));
}).catch(e => { figma.closePlugin('Lỗi: ' + (e && e.message ? e.message : String(e))); });
