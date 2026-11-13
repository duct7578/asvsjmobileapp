// Senpai ơi – xuất toàn bộ thiết kế (ảnh PNG + cấu trúc JSON) về máy chủ nhận file trên localhost:8765.
// Chỉ đọc file Figma, không sửa gì.
'use strict';

figma.showUI(__html__, { width: 380, height: 230 });

const VARS = {};   // variable id -> name
const TSTYLE = {}; // text style id -> name
const ESTYLE = {}; // effect style id -> name
const PSTYLE = {}; // paint style id -> name
const INDEX = [];
const ERRORS = [];
let seq = 0;
const waiting = {};

figma.ui.onmessage = (m) => {
  if ((m.type === 'ack' || m.type === 'pong') && waiting[m.type === 'pong' ? 'pong' : m.id]) {
    const k = m.type === 'pong' ? 'pong' : m.id;
    const fn = waiting[k];
    delete waiting[k];
    fn(m);
  }
};
const status = (text, error) => figma.ui.postMessage({ type: 'status', text, error: !!error });
const log = (text) => figma.ui.postMessage({ type: 'log', text });

function ping() {
  return new Promise((res) => { waiting.pong = res; figma.ui.postMessage({ type: 'ping' }); });
}
function send(path, data) {
  const id = ++seq;
  return new Promise((res, rej) => {
    waiting[id] = (m) => (m.ok ? res() : rej(new Error(path + ': ' + m.err)));
    if (typeof data === 'string') figma.ui.postMessage({ type: 'file', id, path, text: data });
    else figma.ui.postMessage({ type: 'file', id, path, bytes: data });
  });
}

const r2 = (v) => (typeof v === 'number' ? Math.round(v * 100) / 100 : v);
function hex(c) {
  const h = (x) => ('0' + Math.round(x * 255).toString(16)).slice(-2);
  return '#' + h(c.r) + h(c.g) + h(c.b) + (c.a != null && c.a < 1 ? h(c.a) : '');
}
function val(v) {
  if (v && typeof v === 'object' && v.type === 'VARIABLE_ALIAS') return { alias: VARS[v.id] || v.id };
  if (v && typeof v === 'object' && 'r' in v) return hex(v);
  return v;
}
function paints(arr) {
  if (arr === figma.mixed) return 'MIXED';
  if (!arr || !arr.length) return undefined;
  const out = [];
  for (const p of arr) {
    if (p.visible === false) continue;
    const o = { type: p.type };
    if (p.type === 'SOLID') o.color = hex(p.color);
    if (p.opacity != null && p.opacity !== 1) o.opacity = r2(p.opacity);
    if (p.boundVariables && p.boundVariables.color) o.var = VARS[p.boundVariables.color.id] || p.boundVariables.color.id;
    if (p.type.indexOf('GRADIENT') === 0) {
      o.stops = p.gradientStops.map((s) => ({ pos: r2(s.position), color: hex(s.color) }));
      o.transform = p.gradientTransform.map((row) => row.map(r2));
    }
    if (p.type === 'IMAGE') o.scaleMode = p.scaleMode;
    out.push(o);
  }
  return out.length ? out : undefined;
}
function effects(n) {
  if (!('effects' in n) || !n.effects.length) return undefined;
  const o = {};
  if (n.effectStyleId && ESTYLE[n.effectStyleId]) o.style = ESTYLE[n.effectStyleId];
  o.list = n.effects.filter((e) => e.visible !== false).map((e) => ({
    type: e.type, color: e.color ? hex(e.color) : undefined, x: e.offset ? r2(e.offset.x) : undefined,
    y: e.offset ? r2(e.offset.y) : undefined, radius: r2(e.radius), spread: e.spread ? r2(e.spread) : undefined,
  }));
  return o;
}
function safe(fn) { try { return fn(); } catch (e) { return undefined; } }

async function ser(n) {
  const o = { type: n.type, name: n.name };
  if (n.visible === false) o.hidden = true;
  if ('x' in n) { o.x = r2(n.x); o.y = r2(n.y); o.w = r2(n.width); o.h = r2(n.height); }
  if ('opacity' in n && n.opacity !== 1) o.opacity = r2(n.opacity);
  if ('rotation' in n && n.rotation) o.rotation = r2(n.rotation);
  const p = n.parent;
  const inAuto = p && 'layoutMode' in p && p.layoutMode !== 'NONE';
  if (inAuto) {
    o.sizing = [safe(() => n.layoutSizingHorizontal), safe(() => n.layoutSizingVertical)];
    if (n.layoutPositioning === 'ABSOLUTE') o.absolute = true;
  }
  if ('layoutMode' in n && n.layoutMode !== 'NONE') {
    o.layout = {
      mode: n.layoutMode, pad: [n.paddingTop, n.paddingRight, n.paddingBottom, n.paddingLeft].map(r2),
      gap: r2(n.itemSpacing), primary: n.primaryAxisAlignItems, counter: n.counterAxisAlignItems,
    };
    if (n.layoutWrap === 'WRAP') { o.layout.wrap = true; o.layout.rowGap = r2(n.counterAxisSpacing); }
  }
  if ('clipsContent' in n && n.clipsContent) o.clip = true;
  if ('fills' in n && n.type !== 'TEXT') { const f = paints(n.fills); if (f) o.fills = f; }
  if ('fillStyleId' in n && typeof n.fillStyleId === 'string' && PSTYLE[n.fillStyleId]) o.fillStyle = PSTYLE[n.fillStyleId];
  if ('strokes' in n) {
    const s = paints(n.strokes);
    if (s) {
      o.strokes = s;
      o.strokeAlign = n.strokeAlign;
      if (n.strokeWeight === figma.mixed) o.strokeSides = [n.strokeTopWeight, n.strokeRightWeight, n.strokeBottomWeight, n.strokeLeftWeight];
      else o.strokeWeight = r2(n.strokeWeight);
      if (n.dashPattern && n.dashPattern.length) o.dash = n.dashPattern;
    }
  }
  if ('cornerRadius' in n) {
    if (n.cornerRadius === figma.mixed) o.radii = [n.topLeftRadius, n.topRightRadius, n.bottomRightRadius, n.bottomLeftRadius];
    else if (n.cornerRadius) o.radius = r2(n.cornerRadius);
  }
  const ef = effects(n); if (ef) o.effects = ef;
  if (n.type === 'TEXT') {
    const t = { chars: n.characters };
    if (n.textStyleId && n.textStyleId !== figma.mixed && TSTYLE[n.textStyleId]) t.style = TSTYLE[n.textStyleId];
    if (n.fontName !== figma.mixed) { t.font = n.fontName.family; t.weight = n.fontName.style; }
    if (n.fontSize !== figma.mixed) t.size = r2(n.fontSize);
    if (n.lineHeight !== figma.mixed) t.lineHeight = n.lineHeight.unit === 'AUTO' ? 'AUTO' : r2(n.lineHeight.value) + (n.lineHeight.unit === 'PERCENT' ? '%' : 'px');
    if (n.letterSpacing !== figma.mixed && n.letterSpacing.value) t.letterSpacing = r2(n.letterSpacing.value) + (n.letterSpacing.unit === 'PERCENT' ? '%' : 'px');
    const f = paints(n.fills); if (f) t.fills = f;
    if (n.textAlignHorizontal !== 'LEFT') t.align = n.textAlignHorizontal;
    t.autoResize = n.textAutoResize;
    if (n.maxLines) t.maxLines = n.maxLines;
    if (n.textTruncation && n.textTruncation !== 'DISABLED') t.truncation = n.textTruncation;
    if (n.textDecoration && n.textDecoration !== 'NONE' && n.textDecoration !== figma.mixed) t.decoration = n.textDecoration;
    if (n.textCase && n.textCase !== 'ORIGINAL' && n.textCase !== figma.mixed) t.case = n.textCase;
    if (n.fontName === figma.mixed || n.fontSize === figma.mixed || n.fills === figma.mixed) {
      t.segments = n.getStyledTextSegments(['fontName', 'fontSize', 'fills', 'textStyleId']).map((sg) => ({
        chars: sg.characters, font: sg.fontName.family, weight: sg.fontName.style, size: sg.fontSize,
        fills: paints(sg.fills), style: TSTYLE[sg.textStyleId],
      }));
    }
    o.text = t;
  }
  if (n.type === 'INSTANCE') {
    const mc = await n.getMainComponentAsync();
    if (mc) {
      o.component = mc.parent && mc.parent.type === 'COMPONENT_SET' ? mc.parent.name : mc.name;
      if (mc.parent && mc.parent.type === 'COMPONENT_SET') o.variant = mc.name;
    }
    const props = safe(() => n.componentProperties);
    if (props) { o.props = {}; for (const k in props) o.props[k] = props[k].value; }
  }
  if ('children' in n && n.type !== 'BOOLEAN_OPERATION') {
    o.children = [];
    for (const c of n.children) o.children.push(await ser(c));
  }
  return o;
}

async function collectTokens() {
  const out = { collections: [], variables: [], textStyles: [], effectStyles: [], paintStyles: [] };
  const vars = await figma.variables.getLocalVariablesAsync();
  for (const v of vars) VARS[v.id] = v.name;
  for (const c of await figma.variables.getLocalVariableCollectionsAsync()) {
    out.collections.push({ id: c.id, name: c.name, modes: c.modes });
  }
  for (const v of vars) {
    const values = {};
    for (const m in v.valuesByMode) values[m] = val(v.valuesByMode[m]);
    out.variables.push({ name: v.name, type: v.resolvedType, collection: v.variableCollectionId, values, description: v.description || undefined });
  }
  for (const s of await figma.getLocalTextStylesAsync()) {
    TSTYLE[s.id] = s.name;
    out.textStyles.push({
      name: s.name, font: s.fontName.family, weight: s.fontName.style, size: s.fontSize,
      lineHeight: s.lineHeight.unit === 'AUTO' ? 'AUTO' : r2(s.lineHeight.value) + (s.lineHeight.unit === 'PERCENT' ? '%' : 'px'),
      letterSpacing: r2(s.letterSpacing.value) + (s.letterSpacing.unit === 'PERCENT' ? '%' : 'px'),
      textCase: s.textCase, decoration: s.textDecoration, description: s.description || undefined,
    });
  }
  for (const s of await figma.getLocalEffectStylesAsync()) {
    ESTYLE[s.id] = s.name;
    out.effectStyles.push({ name: s.name, effects: effects({ effects: s.effects }).list });
  }
  for (const s of await figma.getLocalPaintStylesAsync()) {
    PSTYLE[s.id] = s.name;
    out.paintStyles.push({ name: s.name, paints: paints(s.paints) });
  }
  return out;
}

function slug(s) {
  return s.normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/đ/g, 'd').replace(/Đ/g, 'D')
    .replace(/[^A-Za-z0-9]+/g, '-').replace(/^-+|-+$/g, '').toLowerCase().slice(0, 60) || 'node';
}

async function exportNode(node, folder, base, meta, scale) {
  const file = folder + '/' + base;
  try {
    const json = await ser(node);
    await send(file + '.json', JSON.stringify(json, null, 1));
    const png = await node.exportAsync({ format: 'PNG', constraint: { type: 'SCALE', value: scale || 2 } });
    await send(file + '.png', png);
    INDEX.push(Object.assign({ file, name: node.name, w: r2(node.width), h: r2(node.height) }, meta));
    log('✓ ' + node.name);
  } catch (e) {
    ERRORS.push(node.name + ': ' + (e && e.message ? e.message : String(e)));
    log('✗ ' + node.name + ' — ' + (e && e.message ? e.message : e));
  }
}

async function exportAssets(page) {
  const sets = page.findAllWithCriteria({ types: ['COMPONENT_SET', 'COMPONENT'] });
  for (const c of sets) {
    if (c.type === 'COMPONENT' && c.parent && c.parent.type === 'COMPONENT_SET') continue;
    if (c.name === 'Cover' && c.type === 'COMPONENT_SET') {
      for (const v of c.children) {
        const scene = slug(v.name.replace(/^.*=/, ''));
        try {
          await send('assets/cover-' + scene + '.png', await v.exportAsync({ format: 'PNG', constraint: { type: 'SCALE', value: 3 } }));
          log('✓ cover ' + scene);
        } catch (e) { ERRORS.push('cover ' + scene + ': ' + e.message); }
      }
    }
    if (c.name === 'Logo') {
      const variants = c.type === 'COMPONENT_SET' ? c.children : [c];
      for (const v of variants) {
        const nm = 'logo' + (c.type === 'COMPONENT_SET' ? '-' + slug(v.name) : '');
        try {
          await send('assets/' + nm + '.png', await v.exportAsync({ format: 'PNG', constraint: { type: 'SCALE', value: 4 } }));
          await send('assets/' + nm + '.svg', await v.exportAsync({ format: 'SVG' }));
          log('✓ ' + nm);
        } catch (e) { ERRORS.push(nm + ': ' + e.message); }
      }
    }
  }
}

async function main() {
  status('Đang kiểm tra máy chủ nhận file…');
  const pong = await ping();
  if (!pong.ok) {
    status('Không kết nối được máy chủ nhận file (localhost:8765). Hãy báo Claude.', true);
    return;
  }
  status('Đang đọc màu, kiểu chữ, hiệu ứng…');
  const tokens = await collectTokens();
  await send('tokens.json', JSON.stringify(tokens, null, 1));
  const pages = figma.root.children;
  const pagesInfo = [];
  for (const page of pages) {
    await page.loadAsync();
    const info = { name: page.name, sections: [], frames: [] };
    pagesInfo.push(info);
    const isDS = page.name.indexOf('Design System') >= 0;
    const pageSlug = isDS ? 'design-system' : (page.name.indexOf('Màn hình') >= 0 ? 'screens' : 'page-' + slug(page.name));
    const top = page.children.filter((n) => n.visible !== false && n.name.indexOf('__lib') !== 0 && n.name.indexOf('⚠️') !== 0);
    for (const n of top) {
      if (n.type === 'SECTION') {
        const kids = n.children.filter((c) => c.visible !== false && ['FRAME', 'COMPONENT', 'COMPONENT_SET', 'INSTANCE', 'GROUP'].indexOf(c.type) >= 0);
        info.sections.push({ name: n.name, children: kids.map((c) => c.name) });
        for (const c of kids) {
          const m = c.name.match(/^(\d\d)\s*·/);
          const base = m ? m[1] + '-' + slug(c.name.replace(/^\d\d\s*·\s*/, '')) : slug(n.name) + '--' + slug(c.name);
          status('Đang xuất: ' + c.name);
          await exportNode(c, pageSlug, base, { page: page.name, section: n.name }, 2);
        }
      } else if (['FRAME', 'COMPONENT', 'COMPONENT_SET', 'INSTANCE', 'GROUP'].indexOf(n.type) >= 0) {
        info.frames.push(n.name);
        const m = n.name.match(/^(\d\d)\s*·/);
        const base = m ? m[1] + '-' + slug(n.name.replace(/^\d\d\s*·\s*/, '')) : slug(n.name);
        status('Đang xuất: ' + n.name);
        await exportNode(n, pageSlug, base, { page: page.name }, 2);
      }
    }
    if (isDS) { status('Đang xuất logo và ảnh minh hoạ…'); await exportAssets(page); }
  }
  await send('index.json', JSON.stringify({ file: figma.root.name, exportedAt: new Date().toISOString(), pages: pagesInfo, items: INDEX, errors: ERRORS }, null, 1));
  await send('_done.txt', 'ok ' + INDEX.length + ' items, ' + ERRORS.length + ' errors');
  status(ERRORS.length ? ('Xong, ' + INDEX.length + ' khung, ' + ERRORS.length + ' lỗi. Báo Claude là đã chạy xong.') : ('Xong! Đã xuất ' + INDEX.length + ' khung. Bạn có thể đóng plugin và báo Claude.'), ERRORS.length > 0);
  figma.notify('Đã xuất ' + INDEX.length + ' khung cho Claude.');
}

main().catch((e) => { status('Lỗi: ' + (e && e.message ? e.message : String(e)), true); });
