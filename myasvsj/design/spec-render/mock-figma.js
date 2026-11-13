// Mock of the Figma Plugin API that runs inside a (headless) Chrome page.
// Every node is backed by a DOM element styled with CSS that mimics Figma auto-layout,
// so Chrome is the layout engine: reading node.width / node.height / node.x / node.y
// returns real measured values (real fonts), exactly like the scripts expect.
// Loaded by tmp/harness.html (built by render.js). Exposes window.figma and window.__mock.
(function () {
  'use strict';

  const R3 = v => Math.round(v * 1000) / 1000;
  const PX = v => R3(v) + 'px';
  let idc = 1, uidc = 1;
  const NODES = new Map();
  const ALIAS = new Map();
  const WARN = [];
  const VARS = new Map();
  const TSTYLES = [], ESTYLES = [];
  const MIXED = Symbol('figma.mixed');
  const CONTAINERS = new Set(['PAGE', 'FRAME', 'COMPONENT', 'COMPONENT_SET', 'INSTANCE', 'SECTION', 'GROUP']);
  const DIRTY = new Set();
  const warn = m => { if (WARN.length < 500) WARN.push(m); };

  const JUST = { MIN: 'flex-start', CENTER: 'center', MAX: 'flex-end', SPACE_BETWEEN: 'space-between' };
  const ALIGN = { MIN: 'flex-start', CENTER: 'center', MAX: 'flex-end', BASELINE: 'baseline' };
  const VJ = { TOP: 'flex-start', CENTER: 'center', BOTTOM: 'flex-end' };
  const TALIGN = { LEFT: 'left', CENTER: 'center', RIGHT: 'right', JUSTIFIED: 'justify' };
  const WEIGHTS = { thin: 100, hairline: 100, extralight: 200, ultralight: 200, light: 300, regular: 400, normal: 400, book: 400, medium: 500, semibold: 600, demibold: 600, bold: 700, extrabold: 800, ultrabold: 800, black: 900, heavy: 900 };

  const clone = o => (o == null ? o : JSON.parse(JSON.stringify(o)));
  const esc = s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

  // ---------- colours / paints ----------
  function rgba(c, a) {
    const r = Math.round((c.r || 0) * 255), g = Math.round((c.g || 0) * 255), b = Math.round((c.b || 0) * 255);
    a = a == null ? 1 : a;
    if (a >= 0.9995) return '#' + [r, g, b].map(x => x.toString(16).padStart(2, '0')).join('').toUpperCase();
    return 'rgba(' + r + ', ' + g + ', ' + b + ', ' + R3(a) + ')';
  }
  function varValue(id) {
    const v = VARS.get(id); if (!v) return null;
    const k = Object.keys(v._values)[0]; return k ? v._values[k] : null;
  }
  function solidColor(p) {
    let c = p.color || { r: 0, g: 0, b: 0 };
    const bv = p.boundVariables && p.boundVariables.color;
    if (bv && bv.id) { const val = varValue(bv.id); if (val) c = val; }
    const a = (c.a != null ? c.a : 1) * (p.opacity != null ? p.opacity : 1);
    return rgba(c, a);
  }
  function gradientCss(p) {
    const stops = (p.gradientStops || []).map(s => rgba(s.color, (s.color.a != null ? s.color.a : 1) * (p.opacity != null ? p.opacity : 1)) + ' ' + R3(s.position * 100) + '%').join(', ');
    let angle = 180;
    const t = p.gradientTransform;
    if (t && t[0] && t[1]) angle = Math.round(Math.atan2(t[1][0], t[0][0]) * 180 / Math.PI) + 90;
    if (p.type === 'GRADIENT_RADIAL') return 'radial-gradient(' + stops + ')';
    return 'linear-gradient(' + angle + 'deg, ' + stops + ')';
  }
  function visiblePaints(arr) { return (arr || []).filter(p => p && p.visible !== false && (p.opacity == null || p.opacity > 0)); }
  function firstSolid(arr) { const p = visiblePaints(arr).find(q => q.type === 'SOLID'); return p ? solidColor(p) : null; }

  // ---------- fonts ----------
  function fontCss(fn) {
    const fam = fn && fn.family || 'Inter';
    const style = (fn && fn.style || 'Regular');
    const key = style.toLowerCase().replace(/italic/, '').replace(/[\s-]/g, '');
    const weight = WEIGHTS[key] || 400;
    const italic = /italic/i.test(style);
    const icon = /^Material (Symbols|Icons)/.test(fam);
    const stack = icon ? '"' + fam + '"' : '"' + fam + '", "Segoe UI", "Yu Gothic UI", sans-serif';
    return { stack, weight, italic, icon, symbols: /^Material Symbols/.test(fam) };
  }
  function lineHeightCss(lh) {
    if (!lh || lh.unit === 'AUTO') return 'normal';
    if (lh.unit === 'PERCENT') return R3(lh.value) + '%';
    return PX(lh.value);
  }
  function letterSpacingCss(ls) {
    if (!ls || !ls.value) return null;
    if (ls.unit === 'PERCENT') return R3(ls.value / 100) + 'em';
    return PX(ls.value);
  }
  const DECO = { UNDERLINE: 'underline', STRIKETHROUGH: 'line-through' };

  function uniquifySvg(svg) {
    const u = 'u' + (uidc++);
    const ids = new Set(); svg.replace(/\sid="([^"]+)"/g, (m, id) => { ids.add(id); return m; });
    let out = svg;
    for (const id of ids) {
      const re = new RegExp('(id="|url\\(#|href="#)' + id.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '(["\\)])', 'g');
      out = out.replace(re, (m, a, b) => a + id + '_' + u + b);
    }
    return out;
  }
  function svgSize(svg) {
    const w = /<svg[^>]*\swidth="([\d.]+)/.exec(svg), h = /<svg[^>]*\sheight="([\d.]+)/.exec(svg);
    const vb = /viewBox="([^"]+)"/.exec(svg);
    let W = w ? +w[1] : 0, H = h ? +h[1] : 0;
    if ((!W || !H) && vb) { const a = vb[1].trim().split(/[\s,]+/).map(Number); W = W || a[2]; H = H || a[3]; }
    return [W || 100, H || 100];
  }
  function prepSvg(svg) {
    let s = svg;
    if (!/viewBox=/.test(s)) { const [w, h] = svgSize(s); s = s.replace('<svg', '<svg viewBox="0 0 ' + w + ' ' + h + '"'); }
    s = s.replace(/<svg([^>]*)>/, (m, attrs) => '<svg' + attrs.replace(/\s(width|height)="[^"]*"/g, '') + ' width="100%" height="100%" style="position:absolute;left:0;top:0;display:block;overflow:hidden">');
    return uniquifySvg(s);
  }

  // ---------- node ----------
  function defaults(type) {
    return {
      name: type === 'TEXT' ? 'Text' : type === 'PAGE' ? 'Page' : type.charAt(0) + type.slice(1).toLowerCase(),
      visible: true, opacity: 1, x: 0, y: 0, w: 100, h: 100, wNat: false, hNat: false,
      fills: [], strokes: [], strokeWeight: 1, strokeAlign: 'INSIDE', sides: null, dash: [],
      radii: [0, 0, 0, 0], effects: [], effectStyleId: '', clip: false, blendMode: 'PASS_THROUGH',
      layoutMode: 'NONE', pSize: 'AUTO', cSize: 'AUTO', pAlign: 'MIN', cAlign: 'MIN', gap: 0, cGap: 0, cAlignContent: 'AUTO', wrap: 'NO_WRAP',
      pad: [0, 0, 0, 0], grow: 0, align: 'INHERIT', positioning: 'AUTO', description: '',
      // text
      characters: '', fontName: { family: 'Inter', style: 'Regular' }, fontSize: 12, lineHeight: { unit: 'AUTO' }, letterSpacing: { unit: 'PERCENT', value: 0 },
      tah: 'LEFT', tav: 'TOP', autoResize: 'WIDTH_AND_HEIGHT', maxLines: null, truncation: 'DISABLED', deco: 'NONE', textStyleId: '', ranges: [],
      svg: null, constraints: { horizontal: 'MIN', vertical: 'MIN' }
    };
  }

  class Node {
    constructor(type, init) {
      this._type = type;
      this._id = 'm:' + (idc++);
      NODES.set(this._id, this);
      this._p = defaults(type);
      if (init) Object.assign(this._p, init);
      this._parent = null;
      this._kids = CONTAINERS.has(type) ? [] : null;
      this._removed = false;
      this._main = null;
      this._el = document.createElement('div');
      this._el.__n = this;
      this._tEl = null; this._strokeEl = null; this._svgDone = false;
      if (type === 'TEXT') { this._tEl = document.createElement('div'); this._el.appendChild(this._tEl); this._textDirty = true; }
      this._dirty();
    }
    // ----- identity -----
    get id() { return this._id; }
    get type() { return this._type; }
    get removed() { return this._removed; }
    get parent() { return this._parent; }
    get children() { return this._kids ? this._kids.slice() : undefined; }
    get name() { return this._p.name; }
    set name(v) { this._p.name = String(v); this._dirty(); }
    get description() { return this._p.description; }
    set description(v) { this._p.description = String(v); }
    get mainComponent() { return this._main; }
    get defaultVariant() { return this._type === 'COMPONENT_SET' ? (this._kids.find(k => k._type === 'COMPONENT') || null) : undefined; }
    get variantProperties() { return parseVariant(this._p.name); }
    // ----- dirty / style -----
    _dirty(kids) { DIRTY.add(this); if (kids && this._kids) for (const k of this._kids) DIRTY.add(k); }
    _isAL() { return (this._type === 'FRAME' || this._type === 'COMPONENT' || this._type === 'INSTANCE' || this._type === 'COMPONENT_SET') && this._p.layoutMode !== 'NONE'; }
    _flowChild() { const par = this._parent; return !!(par && par._isAL() && this._p.positioning !== 'ABSOLUTE'); }
    _axisMode(ax) {
      const p = this._p, par = this._parent;
      if (this._flowChild()) {
        const parH = par._p.layoutMode === 'HORIZONTAL';
        const primary = (ax === 'H') === parH;
        if (primary ? p.grow > 0 : p.align === 'STRETCH') return 'FILL';
      }
      if (this._type === 'TEXT') {
        const ar = p.autoResize;
        if (ar === 'WIDTH_AND_HEIGHT') return 'HUG';
        if (ar === 'HEIGHT') return ax === 'V' ? 'HUG' : 'FIXED';
        return 'FIXED';
      }
      if (this._isAL()) {
        const H = p.layoutMode === 'HORIZONTAL';
        const m = ((ax === 'H') === H) ? p.pSize : p.cSize;
        return m === 'AUTO' ? 'HUG' : 'FIXED';
      }
      return 'FIXED';
    }
    _restyle() {
      if (this._type === 'PAGE') { this._el.style.cssText = 'position:relative;width:0;height:0;overflow:visible;'; return; }
      const p = this._p, el = this._el, s = {};
      const par = this._parent;
      const flow = this._flowChild();
      s['box-sizing'] = 'border-box';
      if (flow) s.position = 'relative'; else { s.position = 'absolute'; s.left = PX(p.x); s.top = PX(p.y); }
      const hz = this._axisMode('H'), vt = this._axisMode('V');
      if (flow) {
        const parH = par._p.layoutMode === 'HORIZONTAL';
        const prim = parH ? hz : vt, cross = parH ? vt : hz;
        if (prim === 'FILL') { s.flex = '1 1 0px'; s[parH ? 'min-width' : 'min-height'] = '0'; }
        else s.flex = '0 0 auto';
        if (cross === 'FILL') s['align-self'] = 'stretch';
      }
      if (hz === 'FIXED') s.width = p.wNat ? 'max-content' : PX(p.w);
      else if (hz === 'HUG') s.width = 'max-content';
      if (vt === 'FIXED') s.height = p.hNat ? 'auto' : PX(p.h);
      if (this._type === 'SECTION') { s.width = PX(p.w); s.height = PX(p.h); }
      const isText = this._type === 'TEXT';
      if (this._isAL()) {
        const H = p.layoutMode === 'HORIZONTAL';
        s.display = 'flex'; s['flex-direction'] = H ? 'row' : 'column';
        if (H && p.wrap === 'WRAP') { s['flex-wrap'] = 'wrap'; s['column-gap'] = PX(p.gap); s['row-gap'] = PX(p.cGap); s['align-content'] = p.cAlignContent === 'SPACE_BETWEEN' ? 'space-between' : 'flex-start'; }
        else s.gap = PX(p.gap);
        s['justify-content'] = JUST[p.pAlign] || 'flex-start';
        s['align-items'] = ALIGN[p.cAlign] || 'flex-start';
        if (p.pad.some(v => v)) s.padding = p.pad.map(PX).join(' ');
      } else if (!isText) s.display = 'block';
      // fills
      if (isText) {
        const c = firstSolid(p.fills); s.color = c || 'transparent';
      } else {
        const vis = visiblePaints(p.fills);
        if (vis.length === 1 && vis[0].type === 'SOLID') s['background-color'] = solidColor(vis[0]);
        else if (vis.length) s['background-image'] = vis.slice().reverse().map(f => f.type === 'SOLID' ? 'linear-gradient(' + solidColor(f) + ', ' + solidColor(f) + ')' : (f.type || '').indexOf('GRADIENT') === 0 ? gradientCss(f) : 'none').join(', ');
      }
      // radius
      if (this._type === 'ELLIPSE') s['border-radius'] = '50%';
      else if (p.radii.some(v => v)) s['border-radius'] = [p.radii[0], p.radii[1], p.radii[2], p.radii[3]].map(PX).join(' ');
      if (p.clip && !isText && this._type !== 'SECTION') s.overflow = 'hidden';
      if (p.opacity !== 1) s.opacity = String(R3(p.opacity));
      // effects
      const shadows = [], filters = [], back = [];
      for (const e of p.effects || []) {
        if (!e || e.visible === false) continue;
        if (e.type === 'DROP_SHADOW' || e.type === 'INNER_SHADOW') {
          const o = e.offset || { x: 0, y: 0 };
          shadows.push((e.type === 'INNER_SHADOW' ? 'inset ' : '') + PX(o.x) + ' ' + PX(o.y) + ' ' + PX(e.radius || 0) + ' ' + PX(e.spread || 0) + ' ' + rgba(e.color || { r: 0, g: 0, b: 0 }, e.color && e.color.a != null ? e.color.a : 0.25));
        } else if (e.type === 'LAYER_BLUR') filters.push('blur(' + PX((e.radius || 0) / 2) + ')');
        else if (e.type === 'BACKGROUND_BLUR') back.push('blur(' + PX((e.radius || 0) / 2) + ')');
      }
      if (shadows.length) s['box-shadow'] = shadows.join(', ');
      if (filters.length) s.filter = filters.join(' ');
      if (back.length) s['backdrop-filter'] = back.join(' ');
      if (this._type === 'COMPONENT_SET') { s.outline = '1px dashed #9747FF'; s['border-radius'] = s['border-radius'] || '5px'; }
      // text
      if (isText) {
        const f = fontCss(p.fontName);
        s['font-family'] = f.stack; s['font-weight'] = String(f.weight); if (f.italic) s['font-style'] = 'italic';
        s['font-size'] = PX(p.fontSize); s['line-height'] = lineHeightCss(p.lineHeight);
        const ls = letterSpacingCss(p.letterSpacing); if (ls) s['letter-spacing'] = ls;
        s['text-align'] = TALIGN[p.tah] || 'left';
        if (DECO[p.deco]) s['text-decoration'] = DECO[p.deco];
        if (f.icon) {
          s['white-space'] = 'nowrap'; s['font-feature-settings'] = '"liga" 1'; s['overflow-wrap'] = 'normal'; s['word-break'] = 'normal';
          if (f.symbols) s['font-variation-settings'] = '"FILL" 0, "wght" 400, "GRAD" 0, "opsz" 24';
        } else {
          s['white-space'] = p.autoResize === 'WIDTH_AND_HEIGHT' ? 'pre' : 'pre-wrap';
          if (p.autoResize !== 'WIDTH_AND_HEIGHT') s['overflow-wrap'] = 'break-word';
        }
        if (p.tav !== 'TOP' && vt === 'FIXED') { s.display = 'flex'; s['flex-direction'] = 'column'; s['justify-content'] = VJ[p.tav]; }
        else s.display = 'block';
        const clamp = p.maxLines && p.truncation === 'ENDING' && p.autoResize !== 'WIDTH_AND_HEIGHT';
        this._tEl.style.cssText = clamp ? 'display:-webkit-box;-webkit-box-orient:vertical;-webkit-line-clamp:' + p.maxLines + ';overflow:hidden;' : (p.truncation === 'ENDING' && vt === 'FIXED' ? 'overflow:hidden;text-overflow:ellipsis;' : '');
      }
      if (!p.visible) s.display = 'none';
      let css = '';
      for (const k in s) css += k + ':' + s[k] + ';';
      el.style.cssText = css;
      el.setAttribute('data-name', p.name);
      el.setAttribute('data-type', this._type);
      if (this._textDirty) this._renderText();
      if (p.svg && !this._svgDone) { const box = document.createElement('div'); box.innerHTML = prepSvg(p.svg); el.insertBefore(box.firstElementChild, el.firstChild); this._svgDone = true; }
      this._renderStroke();
    }
    _renderText() {
      this._textDirty = false;
      const p = this._p, str = p.characters;
      if (!p.ranges.length) { this._tEl.textContent = str; return; }
      const cuts = new Set([0, str.length]);
      for (const r of p.ranges) { cuts.add(Math.max(0, Math.min(str.length, r.s))); cuts.add(Math.max(0, Math.min(str.length, r.e))); }
      const pts = Array.from(cuts).sort((a, b) => a - b);
      let html = '';
      for (let i = 0; i < pts.length - 1; i++) {
        const a = pts[i], b = pts[i + 1]; if (a === b) continue;
        const o = {};
        for (const r of p.ranges) if (r.s <= a && r.e >= b) Object.assign(o, r.v);
        let st = '';
        if (o.fills) { const c = firstSolid(o.fills); if (c) st += 'color:' + c + ';'; }
        if (o.fontName) { const f = fontCss(o.fontName); st += 'font-family:' + f.stack.replace(/"/g, "'") + ';font-weight:' + f.weight + ';' + (f.italic ? 'font-style:italic;' : ''); }
        if (o.deco) st += 'text-decoration:' + (DECO[o.deco] || 'none') + ';';
        if (o.fontSize) st += 'font-size:' + PX(o.fontSize) + ';';
        html += st ? '<span style="' + st + '">' + esc(str.slice(a, b)) + '</span>' : esc(str.slice(a, b));
      }
      this._tEl.innerHTML = html;
    }
    _renderStroke() {
      const p = this._p;
      const vis = this._type === 'TEXT' ? [] : visiblePaints(p.strokes);
      const sides = p.sides || [p.strokeWeight, p.strokeWeight, p.strokeWeight, p.strokeWeight];
      if (!vis.length || !sides.some(v => v > 0)) { if (this._strokeEl) { this._strokeEl.remove(); this._strokeEl = null; } return; }
      if (!this._strokeEl) { this._strokeEl = document.createElement('div'); this._strokeEl.setAttribute('data-stroke', ''); }
      const w = Math.max.apply(null, sides);
      const off = p.strokeAlign === 'OUTSIDE' ? -w : p.strokeAlign === 'CENTER' ? -w / 2 : 0;
      const rad = this._type === 'ELLIPSE' ? '50%' : p.radii.map(r => PX(r ? r - off : 0)).join(' ');
      this._strokeEl.style.cssText = 'position:absolute;pointer-events:none;box-sizing:border-box;left:' + PX(off) + ';top:' + PX(off) + ';right:' + PX(off) + ';bottom:' + PX(off) +
        ';border-style:' + (p.dash && p.dash.length ? 'dashed' : 'solid') + ';border-color:' + solidColor(vis[0]) + ';border-width:' + sides.map(PX).join(' ') + ';border-radius:' + rad + ';';
      if (this._strokeEl.parentNode !== this._el || this._el.lastChild !== this._strokeEl) this._el.appendChild(this._strokeEl);
    }
    // ----- tree -----
    _insert(n, i) {
      if (!this._kids) throw new Error('Cannot add children to a ' + this._type);
      if (n === this) throw new Error('Cannot append node to itself');
      if (n._parent) n._detach();
      if (i == null || i > this._kids.length) i = this._kids.length;
      this._kids.splice(i, 0, n);
      n._parent = this;
      const ref = this._kids[i + 1] ? this._kids[i + 1]._el : (this._strokeEl && this._strokeEl.parentNode === this._el ? this._strokeEl : null);
      this._el.insertBefore(n._el, ref);
      n._dirty();
    }
    _detach() {
      const par = this._parent; if (!par) return;
      const a = par._kids, k = a.indexOf(this); if (k >= 0) a.splice(k, 1);
      this._parent = null;
      if (this._el.parentNode) this._el.parentNode.removeChild(this._el);
    }
    appendChild(n) { this._checkAppend(); this._insert(n); }
    insertChild(i, n) { this._checkAppend(); this._insert(n, i); }
    _checkAppend() { if (this._inInstance || this._type === 'INSTANCE') throw new Error('Cannot move node. New parent is an instance or is inside of an instance'); }
    remove() {
      this._detach();
      const mark = n => { n._removed = true; DIRTY.delete(n); if (n._kids) n._kids.forEach(mark); };
      mark(this);
    }
    _walk(fn) { const out = []; const rec = n => { for (const k of n._kids || []) { if (fn(k)) out.push(k); rec(k); } }; rec(this); return out; }
    findOne(fn) { let res = null; const rec = n => { for (const k of n._kids || []) { if (res) return; if (fn(k)) { res = k; return; } rec(k); } }; rec(this); return res; }
    findAll(fn) { return this._walk(k => !fn || fn(k)); }
    findChild(fn) { return (this._kids || []).find(fn) || null; }
    findChildren(fn) { return (this._kids || []).filter(k => !fn || fn(k)); }
    findAllWithCriteria(c) { const types = c && c.types; return this._walk(k => !types || types.indexOf(k._type) >= 0); }
    async loadAsync() { }
    // ----- geometry -----
    _hiddenChain() { for (let n = this; n; n = n._parent) if (!n._p.visible) return true; return false; }
    _measurable() { return !this._removed && this._el.isConnected && !this._hiddenChain(); }
    _measure() { flush(); return this._el.getBoundingClientRect(); }
    get width() { if (this._type === 'PAGE') return 0; if (!this._measurable()) return this._p.w; return R3(this._measure().width); }
    get height() { if (this._type === 'PAGE') return 0; if (!this._measurable()) return this._p.h; return R3(this._measure().height); }
    get x() {
      if (!this._flowChild() || !this._measurable()) return this._p.x;
      const r = this._measure(), q = this._parent._el.getBoundingClientRect(); return R3(r.left - q.left);
    }
    get y() {
      if (!this._flowChild() || !this._measurable()) return this._p.y;
      const r = this._measure(), q = this._parent._el.getBoundingClientRect(); return R3(r.top - q.top);
    }
    set x(v) { this._p.x = +v; this._dirty(); }
    set y(v) { this._p.y = +v; this._dirty(); }
    get absoluteBoundingBox() { const r = this._measure(); return { x: r.left, y: r.top, width: r.width, height: r.height }; }
    resize(w, h) {
      const p = this._p;
      p.w = Math.max(0.01, +w || 0.01); p.h = Math.max(0.01, +h || 0.01); p.wNat = false; p.hNat = false;
      if (this._isAL()) { p.pSize = 'FIXED'; p.cSize = 'FIXED'; }
      if (this._type === 'TEXT' && p.autoResize === 'WIDTH_AND_HEIGHT') p.autoResize = 'NONE';
      this._dirty();
    }
    resizeWithoutConstraints(w, h) { this.resize(w, h); }
    rescale(scale) {
      if (!(scale > 0)) throw new Error('rescale: invalid scale');
      const rec = (n, root) => {
        const p = n._p;
        if (!root) { p.x *= scale; p.y *= scale; }
        if (n._type !== 'TEXT' || p.autoResize !== 'WIDTH_AND_HEIGHT') { p.w *= scale; p.h *= scale; }
        p.radii = p.radii.map(v => v * scale); p.strokeWeight *= scale; if (p.sides) p.sides = p.sides.map(v => v * scale);
        p.pad = p.pad.map(v => v * scale); p.gap *= scale; p.cGap *= scale; p.dash = (p.dash || []).map(v => v * scale);
        p.fontSize *= scale;
        if (p.lineHeight && p.lineHeight.unit === 'PIXELS') p.lineHeight = { unit: 'PIXELS', value: p.lineHeight.value * scale };
        if (p.letterSpacing && p.letterSpacing.unit === 'PIXELS') p.letterSpacing = { unit: 'PIXELS', value: p.letterSpacing.value * scale };
        p.effects = (p.effects || []).map(e => Object.assign({}, e, { radius: (e.radius || 0) * scale, spread: (e.spread || 0) * scale, offset: e.offset ? { x: e.offset.x * scale, y: e.offset.y * scale } : e.offset }));
        n._dirty();
        for (const k of n._kids || []) rec(k, false);
      };
      rec(this, true);
    }
    // ----- visual props -----
    get visible() { return this._p.visible; } set visible(v) { this._p.visible = !!v; this._dirty(); }
    get opacity() { return this._p.opacity; } set opacity(v) { this._p.opacity = +v; this._dirty(); }
    get blendMode() { return this._p.blendMode; } set blendMode(v) { this._p.blendMode = v; }
    get fills() { return clone(this._p.fills); }
    set fills(v) { if (v === MIXED) return; this._p.fills = clone(v || []); this._dirty(); }
    get strokes() { return clone(this._p.strokes); }
    set strokes(v) { this._p.strokes = clone(v || []); this._dirty(); }
    get strokeWeight() { return this._p.sides && new Set(this._p.sides).size > 1 ? MIXED : this._p.strokeWeight; }
    set strokeWeight(v) { this._p.strokeWeight = +v; this._p.sides = null; this._dirty(); }
    _side(i, v) { const p = this._p; if (!p.sides) p.sides = [p.strokeWeight, p.strokeWeight, p.strokeWeight, p.strokeWeight]; p.sides[i] = +v; this._dirty(); }
    get strokeTopWeight() { return this._p.sides ? this._p.sides[0] : this._p.strokeWeight; } set strokeTopWeight(v) { this._side(0, v); }
    get strokeRightWeight() { return this._p.sides ? this._p.sides[1] : this._p.strokeWeight; } set strokeRightWeight(v) { this._side(1, v); }
    get strokeBottomWeight() { return this._p.sides ? this._p.sides[2] : this._p.strokeWeight; } set strokeBottomWeight(v) { this._side(2, v); }
    get strokeLeftWeight() { return this._p.sides ? this._p.sides[3] : this._p.strokeWeight; } set strokeLeftWeight(v) { this._side(3, v); }
    get strokeAlign() { return this._p.strokeAlign; } set strokeAlign(v) { this._p.strokeAlign = v; this._dirty(); }
    get dashPattern() { return this._p.dash.slice(); } set dashPattern(v) { this._p.dash = (v || []).slice(); this._dirty(); }
    get cornerRadius() { const r = this._p.radii; return r.every(v => v === r[0]) ? r[0] : MIXED; }
    set cornerRadius(v) { if (v === MIXED) return; this._p.radii = [+v, +v, +v, +v]; this._dirty(); }
    get topLeftRadius() { return this._p.radii[0]; } set topLeftRadius(v) { this._p.radii[0] = +v; this._dirty(); }
    get topRightRadius() { return this._p.radii[1]; } set topRightRadius(v) { this._p.radii[1] = +v; this._dirty(); }
    get bottomRightRadius() { return this._p.radii[2]; } set bottomRightRadius(v) { this._p.radii[2] = +v; this._dirty(); }
    get bottomLeftRadius() { return this._p.radii[3]; } set bottomLeftRadius(v) { this._p.radii[3] = +v; this._dirty(); }
    get effects() { return clone(this._p.effects); } set effects(v) { this._p.effects = clone(v || []); this._dirty(); }
    get effectStyleId() { return this._p.effectStyleId; }
    set effectStyleId(id) { const s = ESTYLES.find(e => e.id === id); if (!s) throw new Error('Invalid effect style id ' + id); this._p.effectStyleId = id; this._p.effects = clone(s._effects); this._dirty(); }
    async setEffectStyleIdAsync(id) { this.effectStyleId = id; }
    get clipsContent() { return this._p.clip; } set clipsContent(v) { this._p.clip = !!v; this._dirty(); }
    get constraints() { return clone(this._p.constraints); } set constraints(v) { this._p.constraints = clone(v); }
    // ----- auto layout -----
    get layoutMode() { return this._p.layoutMode; }
    set layoutMode(v) {
      const p = this._p; if (v === p.layoutMode) return;
      if (p.layoutMode === 'NONE' && v !== 'NONE') { p.pSize = 'FIXED'; p.cSize = 'FIXED'; }
      else if (p.layoutMode !== 'NONE' && v !== 'NONE' && p.layoutMode !== v) { const a = p.pSize; p.pSize = p.cSize; p.cSize = a; }
      p.layoutMode = v; this._dirty(true);
    }
    get primaryAxisSizingMode() { return this._p.pSize; } set primaryAxisSizingMode(v) { this._p.pSize = v; this._p[this._p.layoutMode === 'HORIZONTAL' ? 'wNat' : 'hNat'] = false; this._dirty(); }
    get counterAxisSizingMode() { return this._p.cSize; } set counterAxisSizingMode(v) { this._p.cSize = v; this._p[this._p.layoutMode === 'HORIZONTAL' ? 'hNat' : 'wNat'] = false; this._dirty(); }
    get primaryAxisAlignItems() { return this._p.pAlign; } set primaryAxisAlignItems(v) { this._p.pAlign = v; this._dirty(); }
    get counterAxisAlignItems() { return this._p.cAlign; } set counterAxisAlignItems(v) { this._p.cAlign = v; this._dirty(); }
    get counterAxisAlignContent() { return this._p.cAlignContent; } set counterAxisAlignContent(v) { this._p.cAlignContent = v; this._dirty(); }
    get itemSpacing() { return this._p.gap; } set itemSpacing(v) { this._p.gap = +v; this._dirty(); }
    get counterAxisSpacing() { return this._p.cGap; } set counterAxisSpacing(v) { this._p.cGap = +v; this._dirty(); }
    get layoutWrap() { return this._p.wrap; } set layoutWrap(v) { this._p.wrap = v; this._dirty(); }
    get paddingTop() { return this._p.pad[0]; } set paddingTop(v) { this._p.pad[0] = +v; this._dirty(); }
    get paddingRight() { return this._p.pad[1]; } set paddingRight(v) { this._p.pad[1] = +v; this._dirty(); }
    get paddingBottom() { return this._p.pad[2]; } set paddingBottom(v) { this._p.pad[2] = +v; this._dirty(); }
    get paddingLeft() { return this._p.pad[3]; } set paddingLeft(v) { this._p.pad[3] = +v; this._dirty(); }
    get horizontalPadding() { return this._p.pad[1]; } set horizontalPadding(v) { this._p.pad[1] = this._p.pad[3] = +v; this._dirty(); }
    get verticalPadding() { return this._p.pad[0]; } set verticalPadding(v) { this._p.pad[0] = this._p.pad[2] = +v; this._dirty(); }
    get layoutGrow() { return this._p.grow; } set layoutGrow(v) { this._p.grow = +v; this._dirty(); }
    get layoutAlign() { return this._p.align; } set layoutAlign(v) { this._p.align = v; this._dirty(); }
    get layoutPositioning() { return this._p.positioning; }
    set layoutPositioning(v) {
      if (v === 'ABSOLUTE' && !(this._parent && this._parent._isAL())) throw new Error('Can only set layoutPositioning = ABSOLUTE if the parent node has layoutMode !== NONE');
      this._p.positioning = v; this._dirty();
    }
    get layoutSizingHorizontal() { return this._axisMode('H'); } set layoutSizingHorizontal(v) { this._setSizing('H', v); }
    get layoutSizingVertical() { return this._axisMode('V'); } set layoutSizingVertical(v) { this._setSizing('V', v); }
    _setSizing(ax, v) {
      const p = this._p, par = this._parent;
      const parAL = !!(par && par._isAL()) && p.positioning !== 'ABSOLUTE';
      const primary = parAL && ((ax === 'H') === (par._p.layoutMode === 'HORIZONTAL'));
      if (v === 'FILL') {
        if (!parAL) throw new Error('FILL can only be set on children of auto-layout frames (' + p.name + ')');
        if (primary) p.grow = 1; else p.align = 'STRETCH';
        this._dirty(); return;
      }
      if (parAL) { if (primary) p.grow = 0; else p.align = 'INHERIT'; }
      if (this._type === 'TEXT') {
        if (v === 'HUG') {
          if (ax === 'H') p.autoResize = 'WIDTH_AND_HEIGHT';
          else if (p.autoResize === 'NONE' || p.autoResize === 'TRUNCATE') p.autoResize = 'HEIGHT';
        } else if (v === 'FIXED') {
          if (ax === 'H' && p.autoResize === 'WIDTH_AND_HEIGHT') { p.autoResize = 'HEIGHT'; p.wNat = true; }
          if (ax === 'V' && p.autoResize !== 'NONE') { if (p.autoResize === 'WIDTH_AND_HEIGHT') p.wNat = true; p.autoResize = 'NONE'; p.hNat = true; }
        }
      } else if (this._isAL()) {
        const H = p.layoutMode === 'HORIZONTAL';
        const key = ((ax === 'H') === H) ? 'pSize' : 'cSize';
        const nat = ax === 'H' ? 'wNat' : 'hNat';
        if (v === 'HUG') { p[key] = 'AUTO'; p[nat] = false; }
        else if (v === 'FIXED' && p[key] === 'AUTO') { p[key] = 'FIXED'; p[nat] = true; }
      } else if (v === 'HUG') {
        throw new Error('HUG can only be set on auto-layout frames and text nodes (' + p.name + ')');
      }
      this._dirty();
    }
    // ----- text -----
    _t() { if (this._type !== 'TEXT') throw new Error('Not a text node'); }
    _tset(k, v) { this._t(); this._p[k] = v; this._textDirty = true; this._dirty(); }
    get characters() { return this._p.characters; }
    set characters(v) { this._t(); this._p.characters = String(v); this._p.ranges = []; this._textDirty = true; this._dirty(); }
    get fontName() { return clone(this._p.fontName); } set fontName(v) { if (v === MIXED) return; this._tset('fontName', clone(v)); }
    get fontSize() { return this._p.fontSize; } set fontSize(v) { if (v === MIXED) return; this._tset('fontSize', +v); }
    get lineHeight() { return clone(this._p.lineHeight); } set lineHeight(v) { if (v === MIXED) return; this._tset('lineHeight', clone(v)); }
    get letterSpacing() { return clone(this._p.letterSpacing); } set letterSpacing(v) { if (v === MIXED) return; this._tset('letterSpacing', clone(v)); }
    get textAlignHorizontal() { return this._p.tah; } set textAlignHorizontal(v) { this._tset('tah', v); }
    get textAlignVertical() { return this._p.tav; } set textAlignVertical(v) { this._tset('tav', v); }
    get textDecoration() { return this._p.deco; } set textDecoration(v) { this._tset('deco', v || 'NONE'); }
    get textAutoResize() { return this._p.autoResize; }
    set textAutoResize(v) {
      this._t(); const p = this._p, old = p.autoResize;
      if (old === 'WIDTH_AND_HEIGHT' && v !== 'WIDTH_AND_HEIGHT') p.wNat = true;
      if (v === 'NONE' && old !== 'NONE') p.hNat = true;
      if (v === 'WIDTH_AND_HEIGHT') { p.wNat = false; p.hNat = false; }
      if (v === 'HEIGHT') p.hNat = false;
      p.autoResize = v; this._dirty();
    }
    get maxLines() { return this._p.maxLines; } set maxLines(v) { this._tset('maxLines', v == null ? null : +v); }
    get textTruncation() { return this._p.truncation; } set textTruncation(v) { this._tset('truncation', v); }
    get textStyleId() { return this._p.textStyleId; }
    set textStyleId(id) {
      this._t(); const s = TSTYLES.find(t => t.id === id); if (!s) throw new Error('Invalid text style id ' + id);
      const p = this._p; p.textStyleId = id; p.fontName = clone(s._fontName); p.fontSize = s._fontSize; p.lineHeight = clone(s._lineHeight); p.letterSpacing = clone(s._letterSpacing);
      if (s._textDecoration) p.deco = s._textDecoration;
      this._textDirty = true; this._dirty();
    }
    async setTextStyleIdAsync(id) { this.textStyleId = id; }
    _range(a, b, v) { this._t(); this._p.ranges.push({ s: a, e: b, v }); this._textDirty = true; this._dirty(); }
    setRangeFills(a, b, f) { this._range(a, b, { fills: clone(f) }); }
    setRangeFontName(a, b, f) { this._range(a, b, { fontName: clone(f) }); }
    setRangeTextDecoration(a, b, d) { this._range(a, b, { deco: d }); }
    setRangeFontSize(a, b, s) { this._range(a, b, { fontSize: s }); }
    // ----- components -----
    createInstance() {
      if (this._type !== 'COMPONENT') throw new Error('createInstance only on components');
      const inst = this._cloneTree(true);
      currentPage._insert(inst);
      return inst;
    }
    _cloneTree(asInstance) {
      const n = new Node(asInstance ? 'INSTANCE' : this._type, clone(this._p));
      n._p.svg = this._p.svg;
      if (asInstance) {
        n._main = this;
        const set = this._parent && this._parent._type === 'COMPONENT_SET' ? this._parent : null;
        n._p.name = set ? set._p.name : this._p.name;
        n._p.x = 0; n._p.y = 0; n._p.grow = 0; n._p.align = 'INHERIT'; n._p.positioning = 'AUTO';
      }
      if (this._kids) for (const k of this._kids) { const c = k._cloneTree(false); c._inInstance = true; n._insert(c); }
      if (n._type === 'TEXT') n._textDirty = true;
      return n;
    }
    setProperties(props) {
      if (this._type !== 'INSTANCE') throw new Error('setProperties only on instances');
      const main = this._main, set = main && main._parent;
      if (!set || set._type !== 'COMPONENT_SET') { warn('setProperties on non-variant instance ' + this._p.name); return; }
      const want = Object.assign(parseVariant(main._p.name), props);
      const target = set._kids.find(c => { const v = parseVariant(c._p.name); return Object.keys(want).every(k => v[k] === want[k]); });
      if (!target) throw new Error('No variant matches ' + JSON.stringify(want) + ' in ' + set._p.name);
      const keep = { x: this._p.x, y: this._p.y, grow: this._p.grow, align: this._p.align, positioning: this._p.positioning, name: this._p.name };
      this._p = clone(target._p); this._p.svg = target._p.svg; Object.assign(this._p, keep);
      for (const k of this._kids.slice()) k.remove();
      if (this._el.firstChild && this._el.firstChild.tagName === 'svg') this._el.removeChild(this._el.firstChild);
      this._svgDone = false;
      for (const k of target._kids) { const c = k._cloneTree(false); c._inInstance = true; this._insert(c); }
      this._main = target; this._dirty();
    }
    detachInstance() { this._type = 'FRAME'; this._main = null; return this; }
    // misc no-ops
    setPluginData() { } getPluginData() { return ''; } setSharedPluginData() { } getSharedPluginData() { return ''; }
    exportAsync() { return Promise.resolve(new Uint8Array()); }
  }
  function parseVariant(name) {
    const o = {};
    String(name).split(',').forEach(part => { const m = part.split('='); if (m.length === 2) o[m[0].trim()] = m[1].trim(); });
    return o;
  }

  function flush() {
    if (!DIRTY.size) return;
    const list = Array.from(DIRTY); DIRTY.clear();
    for (const n of list) if (!n._removed) n._restyle();
  }

  // ---------- document ----------
  const docEl = document.getElementById('doc') || document.body;
  const pages = [];
  function makePage(name) { const pg = new Node('PAGE', { name }); docEl.appendChild(pg._el); pages.push(pg); return pg; }
  let currentPage = makePage('Page 1');

  // ---------- styles / variables ----------
  let sidc = 1;
  class TextStyle {
    constructor() { this.id = 'S:t' + (sidc++) + ','; this.name = 'Text style'; this.type = 'TEXT'; this.description = ''; this._fontName = { family: 'Inter', style: 'Regular' }; this._fontSize = 12; this._lineHeight = { unit: 'AUTO' }; this._letterSpacing = { unit: 'PERCENT', value: 0 }; this._textDecoration = null; }
    get fontName() { return clone(this._fontName); } set fontName(v) { this._fontName = clone(v); }
    get fontSize() { return this._fontSize; } set fontSize(v) { this._fontSize = +v; }
    get lineHeight() { return clone(this._lineHeight); } set lineHeight(v) { this._lineHeight = clone(v); }
    get letterSpacing() { return clone(this._letterSpacing); } set letterSpacing(v) { this._letterSpacing = clone(v); }
    get textDecoration() { return this._textDecoration || 'NONE'; } set textDecoration(v) { this._textDecoration = v; }
    remove() { const i = TSTYLES.indexOf(this); if (i >= 0) TSTYLES.splice(i, 1); }
  }
  class EffectStyle {
    constructor() { this.id = 'S:e' + (sidc++) + ','; this.name = 'Effect style'; this.type = 'EFFECT'; this.description = ''; this._effects = []; }
    get effects() { return clone(this._effects); } set effects(v) { this._effects = clone(v); }
    remove() { const i = ESTYLES.indexOf(this); if (i >= 0) ESTYLES.splice(i, 1); }
  }
  let vidc = 1;
  class Variable {
    constructor(name, col, type) { this.id = 'VariableID:' + (vidc++) + ':1'; this.name = name; this.resolvedType = type; this.variableCollectionId = col.id; this._values = {}; this.scopes = ['ALL_SCOPES']; this.description = ''; VARS.set(this.id, this); col.variableIds.push(this.id); }
    get valuesByMode() { return clone(this._values); }
    setValueForMode(mode, v) { this._values[mode] = clone(v); }
    remove() { VARS.delete(this.id); }
  }
  const COLS = [];
  let cidc = 1;
  class Collection {
    constructor(name) { this.id = 'VariableCollectionId:' + (cidc++) + ':1'; this.name = name; this.modes = [{ modeId: cidc + ':0', name: 'Mode 1' }]; this.variableIds = []; COLS.push(this); }
    get defaultModeId() { return this.modes[0].modeId; }
    renameMode(id, name) { const m = this.modes.find(x => x.modeId === id); if (m) m.name = name; }
    addMode(name) { const id = cidc + ':' + this.modes.length; this.modes.push({ modeId: id, name }); return id; }
  }

  const figma = {
    mixed: MIXED,
    apiVersion: '1.0.0', editorType: 'figma',
    root: { type: 'DOCUMENT', name: 'Senpai ơi – Mobile App Redesign', get children() { return pages.slice(); }, appendChild(p) { } },
    get currentPage() { return currentPage; },
    set currentPage(p) { currentPage = p; },
    async setCurrentPageAsync(p) { currentPage = p; },
    createPage() { return makePage('Page ' + (pages.length + 1)); },
    async loadFontAsync() { },
    async listAvailableFontsAsync() { return []; },
    async getNodeByIdAsync(id) { return figma.getNodeById(id); },
    getNodeById(id) {
      if (ALIAS.has(id)) { const n = ALIAS.get(id); return n && !n._removed ? n : null; }
      const n = NODES.get(id); if (n && !n._removed) return n;
      const pg = pages.find(p => p._id === id); return pg || null;
    },
    notify() { return { cancel() { } }; },
    closePlugin(msg) { figma.__closeMsg = msg; if (figma.__onClose) figma.__onClose(msg == null ? '' : msg); },
    viewport: { scrollAndZoomIntoView() { }, center: { x: 0, y: 0 }, zoom: 1 },
    ui: { postMessage() { }, onmessage: null, show() { }, hide() { }, resize() { } },
    on() { }, off() { }, once() { },
    createFrame() { const f = new Node('FRAME', { fills: [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 }, opacity: 1, visible: true, blendMode: 'NORMAL' }], clip: true, name: 'Frame' }); currentPage._insert(f); return f; },
    createAutoLayout(dir) { const f = new Node('FRAME', { layoutMode: dir === 'VERTICAL' ? 'VERTICAL' : 'HORIZONTAL', pSize: 'AUTO', cSize: 'AUTO', fills: [], clip: false, name: 'Frame' }); currentPage._insert(f); return f; },
    createText() { const t = new Node('TEXT', { fills: [{ type: 'SOLID', color: { r: 0, g: 0, b: 0 } }], w: 0, h: 0 }); currentPage._insert(t); return t; },
    createRectangle() { const r = new Node('RECTANGLE', { fills: [{ type: 'SOLID', color: { r: 0.851, g: 0.851, b: 0.851 } }], name: 'Rectangle' }); currentPage._insert(r); return r; },
    createEllipse() { const r = new Node('ELLIPSE', { fills: [{ type: 'SOLID', color: { r: 0.851, g: 0.851, b: 0.851 } }], name: 'Ellipse' }); currentPage._insert(r); return r; },
    createLine() { const r = new Node('RECTANGLE', { h: 0.01, name: 'Line' }); currentPage._insert(r); return r; },
    createSection() { const s = new Node('SECTION', { name: 'Section', fills: [] }); currentPage._insert(s); return s; },
    createComponent() { const c = new Node('COMPONENT', { clip: true, fills: [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }], name: 'Component' }); currentPage._insert(c); return c; },
    createNodeFromSvg(svg) {
      const [w, h] = svgSize(svg);
      const n = new Node('FRAME', { svg: String(svg), w, h, fills: [], clip: false, name: 'svg' });
      currentPage._insert(n); return n;
    },
    createComponentFromNode(n) {
      if (n._type !== 'FRAME' && n._type !== 'GROUP') throw new Error('createComponentFromNode: unsupported node ' + n._type);
      n._type = 'COMPONENT'; n._dirty(); return n;
    },
    combineAsVariants(nodes, parent, index) {
      const set = new Node('COMPONENT_SET', { name: 'Component set', fills: [], clip: true });
      (parent || currentPage)._insert(set, index);
      const x0 = Math.min.apply(null, nodes.map(n => n._p.x)), y0 = Math.min.apply(null, nodes.map(n => n._p.y));
      set._p.x = x0; set._p.y = y0;
      for (const n of nodes) { if (n._type !== 'COMPONENT') throw new Error('combineAsVariants: all nodes must be components'); set._insert(n); }
      return set;
    },
    createTextStyle() { const s = new TextStyle(); TSTYLES.push(s); return s; },
    createEffectStyle() { const s = new EffectStyle(); ESTYLES.push(s); return s; },
    async getLocalTextStylesAsync() { return TSTYLES.slice(); },
    async getLocalEffectStylesAsync() { return ESTYLES.slice(); },
    getLocalTextStyles() { return TSTYLES.slice(); },
    getLocalEffectStyles() { return ESTYLES.slice(); },
    async getStyleByIdAsync(id) { return TSTYLES.concat(ESTYLES).find(s => s.id === id) || null; },
    variables: {
      createVariableCollection(name) { return new Collection(name); },
      createVariable(name, col, type) { return new Variable(name, typeof col === 'string' ? COLS.find(c => c.id === col) : col, type); },
      async getLocalVariablesAsync(type) { return Array.from(VARS.values()).filter(v => !type || v.resolvedType === type); },
      async getLocalVariableCollectionsAsync() { return COLS.slice(); },
      async getVariableByIdAsync(id) { return VARS.get(id) || null; },
      getVariableById(id) { return VARS.get(id) || null; },
      setBoundVariableForPaint(paint, field, v) {
        if (!v || !VARS.has(v.id)) throw new Error('setBoundVariableForPaint: bad variable');
        const val = varValue(v.id) || paint.color;
        return Object.assign({}, clone(paint), { color: { r: val.r, g: val.g, b: val.b }, boundVariables: { color: { type: 'VARIABLE_ALIAS', id: v.id } } });
      }
    }
  };

  // ---------- harness API (used by render.js) ----------
  const mock = {
    flush,
    alias(id, node) { ALIAS.set(id, node); },
    findByName(name) { for (const n of NODES.values()) if (!n._removed && n._p.name === name) return n; return null; },
    warnings() { return WARN.slice(); },
    stats() { let live = 0; for (const n of NODES.values()) if (!n._removed) live++; return { created: NODES.size, live }; },
    unknownProps() {
      const out = {};
      for (const n of NODES.values()) for (const k of Object.keys(n)) if (k.charAt(0) !== '_') out[k] = (out[k] || 0) + 1;
      return out;
    },
    pages() { return pages.map(p => ({ id: p._id, name: p._p.name, children: p._kids.map(c => ({ id: c._id, type: c._type, name: c._p.name, visible: c._p.visible })) })); },
    // list screens (frames in sections of the screens page) + Design System frames
    outputs() {
      flush();
      const res = [];
      const scr = pages.find(p => p._p.name.indexOf('Màn hình') >= 0);
      if (scr) for (const sec of scr._kids) {
        if (sec._type !== 'SECTION') continue;
        for (const f of sec._kids) {
          const m = /^(\d\d) ·/.exec(f._p.name);
          if (!m || f._type !== 'FRAME') continue;
          const r = f._el.getBoundingClientRect();
          res.push({ kind: 'screen', id: f._id, num: m[1], name: f._p.name, section: sec._p.name, w: R3(r.width), h: R3(r.height) });
        }
      }
      const ds = pages.find(p => p._p.name.indexOf('Design System') >= 0);
      if (ds) for (const f of ds._kids) {
        if (!f._p.visible) continue;
        const r = f._el.getBoundingClientRect();
        res.push({ kind: 'ds', id: f._id, name: f._p.name, type: f._type, w: R3(r.width), h: R3(r.height), variants: f._type === 'COMPONENT_SET' ? f._kids.map(k => k._p.name) : null });
      }
      const errFrame = scr && scr._kids.find(n => n._p.name.indexOf('⚠️') === 0);
      return { list: res, pluginErrors: errFrame ? errFrame.findAll(n => n._type === 'TEXT').map(t => t._p.characters).join('\n') : null };
    },
    serialize(id) {
      flush();
      const n = NODES.get(id);
      const c = n._el.cloneNode(true);
      c.style.position = 'absolute'; c.style.left = '0px'; c.style.top = '0px';
      return c.outerHTML;
    },
    // automatic checks on one output frame: icon ligatures that did not resolve, text cut by its box,
    // and auto-layout children that stick out of a fixed/fill-width parent (Figma would show the same overflow).
    diagnose(id) {
      flush();
      const root = NODES.get(id), icons = [], overflow = [], clipped = [];
      const path = n => { const a = []; for (let x = n; x && x !== root; x = x._parent) a.unshift(x._p.name); return a.slice(-3).join(' › '); };
      const visible = n => { for (let x = n; x; x = x._parent) if (!x._p.visible) return false; return true; };
      for (const n of [root].concat(root.findAll(() => true))) {
        if (!visible(n)) continue;
        if (n._type === 'TEXT') {
          const f = fontCss(n._p.fontName);
          const rg = document.createRange(); rg.selectNodeContents(n._tEl); const w = rg.getBoundingClientRect().width;
          if (f.icon && w > n._p.fontSize * 1.3) icons.push(n._p.characters);
          if (!f.icon && n._axisMode('H') !== 'HUG' && n._tEl.scrollWidth > n._el.clientWidth + 2) clipped.push(path(n) + ' "' + n._p.characters.slice(0, 30) + '"');
          continue;
        }
        if (!n._isAL() || n._axisMode('H') === 'HUG') continue;
        const r = n._el.getBoundingClientRect(), padR = n._p.pad[1], padL = n._p.pad[3];
        for (const k of n._kids) {
          if (!k._p.visible || !k._flowChild()) continue;
          const q = k._el.getBoundingClientRect();
          let inner = q.right;
          if (k._isAL() && k._axisMode('H') !== 'HUG') { // content overflowing a squeezed child
            const kr = k._el.scrollWidth - k._el.clientWidth; if (kr > 2 && getComputedStyle(k._el).overflow !== 'hidden') inner = Math.max(inner, q.right + kr);
            let minL = q.left; for (const g of k._kids) if (g._p.visible && g._flowChild()) minL = Math.min(minL, g._el.getBoundingClientRect().left);
            if (q.left - minL > 2) overflow.push(path(k) + ' content overflows by ' + Math.round(q.left - minL) + 'px each side');
          }
          if (inner > r.right - padR + 2 || q.left < r.left + padL - 2) overflow.push(path(k) + ' sticks out of "' + n._p.name + '" by ' + Math.round(Math.max(inner - (r.right - padR), r.left + padL - q.left)) + 'px' + (n._p.clip ? ' (clipped)' : ''));
        }
      }
      return { icons: Array.from(new Set(icons)), overflow: Array.from(new Set(overflow)), clipped: Array.from(new Set(clipped)) };
    },
    // compact tree dump for debugging
    dump(id, depth) {
      flush();
      const n = NODES.get(id) || mock.findByName(id);
      const rec = (x, d) => {
        const r = x._el.getBoundingClientRect(), q = x._parent ? x._parent._el.getBoundingClientRect() : { left: 0, top: 0 };
        let line = '  '.repeat(d) + x._type + ' "' + x._p.name + '" ' + R3(r.left - q.left) + ',' + R3(r.top - q.top) + ' ' + R3(r.width) + 'x' + R3(r.height) + ' H=' + x._axisMode('H') + ' V=' + x._axisMode('V') + (x._type === 'TEXT' ? ' [' + x._p.characters.slice(0, 40) + ']' : '') + (x._p.visible ? '' : ' (hidden)');
        const out = [line];
        if (d < (depth || 99)) for (const k of x._kids || []) out.push(...rec(k, d + 1));
        return out;
      };
      return rec(n, 0).join('\n');
    }
  };
  window.figma = figma;
  window.__mock = mock;
})();
