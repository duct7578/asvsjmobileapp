#!/usr/bin/env node
// Renders the Figma file "Senpai ơi – Mobile App Redesign" WITHOUT Figma.
// Runs the original use_figma / plugin scripts in design/spec/ against a DOM-backed mock of the
// Figma Plugin API (mock-figma.js) inside headless Chrome, then writes one standalone HTML + PNG
// per screen (and per Design System frame) to design/figma-export/ref/.
//
//   node design/spec-render/render.js            # everything
//   node design/spec-render/render.js --only 05,12 --no-shots
//   options: --only <nums|ds>  --no-shots  --scale 2  --verbose  --keep-open
'use strict';
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');
const { pathToFileURL } = require('url');

const HERE = __dirname;
const ROOT = path.resolve(HERE, '..', '..');
const SPEC = path.join(ROOT, 'design', 'spec');
const OUT = path.join(ROOT, 'design', 'figma-export', 'ref');
const TMP = path.join(HERE, 'tmp');

// ---------- options ----------
const argv = process.argv.slice(2);
const opt = { only: null, shots: true, scale: 1, verbose: false, keepOpen: false };
for (let i = 0; i < argv.length; i++) {
  const a = argv[i];
  if (a === '--only') opt.only = argv[++i].split(',').map(s => s.trim().toLowerCase());
  else if (a === '--no-shots') opt.shots = false;
  else if (a === '--scale') opt.scale = parseFloat(argv[++i]) || 1;
  else if (a === '--verbose') opt.verbose = true;
  else if (a === '--keep-open') opt.keepOpen = true;
  else { console.error('unknown option ' + a); process.exit(2); }
}

const CHROME = [process.env.CHROME,
  'C:/Program Files/Google/Chrome/Application/chrome.exe',
  'C:/Program Files (x86)/Google/Chrome/Application/chrome.exe',
  'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',
  'C:/Program Files/Microsoft/Edge/Application/msedge.exe',
  '/usr/bin/google-chrome', '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'].find(p => p && fs.existsSync(p));

// Fonts (paths relative to the app root).
const FONT_FACES = [
  { family: 'Be Vietnam Pro', weight: '400', file: 'assets/fonts/BeVietnamPro-Regular.ttf' },
  { family: 'Be Vietnam Pro', weight: '500', file: 'assets/fonts/BeVietnamPro-Medium.ttf' },
  { family: 'Be Vietnam Pro', weight: '600', file: 'assets/fonts/BeVietnamPro-SemiBold.ttf' },
  { family: 'Be Vietnam Pro', weight: '700', file: 'assets/fonts/BeVietnamPro-Bold.ttf' },
  { family: 'Bricolage Grotesque', weight: '200 800', file: 'assets/fonts/BricolageGrotesque-Variable.ttf', load: ['700', '800'] },
  { family: 'Zen Maru Gothic', weight: '500', file: 'assets/fonts/ZenMaruGothic-Medium.ttf' },
  { family: 'Zen Maru Gothic', weight: '700', file: 'assets/fonts/ZenMaruGothic-Bold.ttf' },
  { family: 'Material Symbols Rounded', weight: '100 700', file: 'design/spec-render/fonts/MaterialSymbolsRounded.ttf', load: ['400'] },
  { family: 'Material Icons Round', weight: '400', file: 'design/spec-render/fonts/MaterialIconsRound-Regular.otf' },
];
// Section names of page "📱 Màn hình" (created by a call that is not in design/spec; names as used by the 09–43 plugin).
const SECTIONS = ['1 · Trang chủ, Tìm kiếm, Thông báo, Thêm', '2 · Bản đồ & Địa điểm', '3 · Blog', '4 · Hỏi-Đáp', '5 · Sự kiện & Cẩm nang', '6 · Nhật ngữ', '7 · Tin nhắn', '8 · Tài khoản', '9 · Cài đặt cá nhân'];

function fontFaceCss(urlOf) {
  return FONT_FACES.map(f => '@font-face{font-family:"' + f.family + '";src:url("' + urlOf(f.file) + '");font-weight:' + f.weight + ';font-style:normal;font-display:block;}').join('\n');
}
const fileUrl = rel => pathToFileURL(path.join(ROOT, rel)).href;
const relUrl = rel => path.relative(OUT, path.join(ROOT, rel)).split(path.sep).join('/');

function slug(s) {
  return s.normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/đ/g, 'd').replace(/Đ/g, 'D')
    .toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '').slice(0, 80).replace(/-+$/, '');
}
const htmlEsc = s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

// Split a file of concatenated use_figma scripts on its "// =====" marker lines.
function scriptParts(file) {
  const src = fs.readFileSync(file, 'utf8');
  // part markers are "// ===== phần N: …" (design-system) and "// ===== 013 =====" (screens-01-08);
  // inner comments such as "// ===== 01 Home guest =====" belong to their part.
  const MARK = /^\/\/ ===== (?:phần \d|\d{3} )[^\n]*$/mg;
  const markers = [...src.matchAll(MARK)].map(m => m[0]);
  const chunks = src.split(new RegExp(MARK.source, 'm'));
  const out = [];
  chunks.forEach((code, i) => {
    if (!code.replace(/^\s*\/\/.*$/mg, '').trim()) return;
    out.push({ label: path.basename(file) + ' ' + (i === 0 ? '(part 1)' : markers[i - 1].replace(/^\/\/ =+\s*/, '').replace(/\s*=+\s*$/, '')), code });
  });
  return out;
}

// ---------- minimal CDP client ----------
class CDP {
  constructor(url) { this.url = url; this.seq = 0; this.pending = new Map(); this.handlers = new Set(); }
  open() {
    return new Promise((res, rej) => {
      this.ws = new WebSocket(this.url);
      this.ws.onopen = () => res();
      this.ws.onerror = e => rej(new Error('CDP websocket error ' + (e && e.message || '')));
      this.ws.onmessage = e => {
        const m = JSON.parse(typeof e.data === 'string' ? e.data : Buffer.from(e.data).toString('utf8'));
        if (m.id != null && this.pending.has(m.id)) {
          const p = this.pending.get(m.id); this.pending.delete(m.id);
          if (m.error) p.rej(new Error(p.method + ': ' + m.error.message + (m.error.data ? ' ' + m.error.data : ''))); else p.res(m.result);
        } else if (m.method) for (const h of this.handlers) h(m);
      };
    });
  }
  send(method, params, sessionId) {
    const id = ++this.seq; const msg = { id, method, params: params || {} };
    if (sessionId) msg.sessionId = sessionId;
    return new Promise((res, rej) => { this.pending.set(id, { res, rej, method }); this.ws.send(JSON.stringify(msg)); });
  }
  waitFor(method, sessionId, ms) {
    return new Promise((res, rej) => {
      const t = setTimeout(() => { this.handlers.delete(h); rej(new Error('timeout waiting for ' + method)); }, ms || 60000);
      const h = m => { if (m.method === method && (!sessionId || m.sessionId === sessionId)) { clearTimeout(t); this.handlers.delete(h); res(m.params); } };
      this.handlers.add(h);
    });
  }
  close() { try { this.ws.close(); } catch (e) { } }
}

async function launchChrome() {
  if (!CHROME) throw new Error('Chrome/Edge not found; set CHROME=path');
  const profile = path.join(TMP, 'chrome-profile');
  fs.mkdirSync(profile, { recursive: true });
  const portFile = path.join(profile, 'DevToolsActivePort');
  fs.rmSync(portFile, { force: true });
  const proc = spawn(CHROME, ['--headless=new', '--remote-debugging-port=0', '--user-data-dir=' + profile, '--allow-file-access-from-files',
    '--hide-scrollbars', '--force-device-scale-factor=1', '--no-first-run', '--no-default-browser-check', '--disable-extensions',
    '--disable-background-networking', '--disable-sync', '--disable-component-update', '--mute-audio', '--font-render-hinting=none', 'about:blank'], { stdio: 'ignore' });
  const t0 = Date.now();
  while (!fs.existsSync(portFile) || fs.readFileSync(portFile, 'utf8').split('\n').length < 2) {
    if (Date.now() - t0 > 30000) { proc.kill(); throw new Error('Chrome did not start (no DevToolsActivePort)'); }
    await new Promise(r => setTimeout(r, 100));
  }
  const [port, wsPath] = fs.readFileSync(portFile, 'utf8').trim().split(/\r?\n/);
  const cdp = new CDP('ws://127.0.0.1:' + port + wsPath);
  await cdp.open();
  return { proc, cdp };
}

async function main() {
  const T0 = Date.now();
  fs.mkdirSync(TMP, { recursive: true });
  fs.mkdirSync(OUT, { recursive: true });
  for (const f of FONT_FACES) if (!fs.existsSync(path.join(ROOT, f.file))) throw new Error('missing font ' + f.file + ' (see design/spec-render/README.md)');

  // harness page: fonts + mock
  const loads = [];
  for (const f of FONT_FACES) for (const w of (f.load || [f.weight])) loads.push(w + ' 16px "' + f.family + '"');
  const harness = '<!doctype html><html><head><meta charset="utf-8"><style>' + fontFaceCss(fileUrl) +
    '\nhtml,body{margin:0;padding:0;}body{-webkit-font-smoothing:antialiased;}</style></head><body><div id="doc" style="position:relative"></div>' +
    '<script src="' + pathToFileURL(path.join(HERE, 'mock-figma.js')).href + '"></script>' +
    '<script>window.__ready = Promise.all(' + JSON.stringify(loads) + '.map(s => document.fonts.load(s, "aあ"))).then(() => ' + JSON.stringify(loads) + '.map(s => [s, document.fonts.check(s)]));</script></body></html>';
  const harnessPath = path.join(TMP, 'harness.html');
  fs.writeFileSync(harnessPath, harness);

  const { proc, cdp } = await launchChrome();
  const { targetId } = await cdp.send('Target.createTarget', { url: 'about:blank' });
  const { sessionId } = await cdp.send('Target.attachToTarget', { targetId, flatten: true });
  const S = sessionId;
  await cdp.send('Page.enable', {}, S);
  await cdp.send('Runtime.enable', {}, S);
  cdp.handlers.add(m => {
    if (m.sessionId !== S) return;
    if (m.method === 'Runtime.consoleAPICalled' && (opt.verbose || m.params.type === 'error')) console.log('  [page ' + m.params.type + ']', m.params.args.map(a => a.value !== undefined ? a.value : a.description).join(' '));
    if (m.method === 'Runtime.exceptionThrown') console.log('  [page exception]', m.params.exceptionDetails.exception ? m.params.exceptionDetails.exception.description : m.params.exceptionDetails.text);
  });
  const evaluate = async (expression) => {
    const r = await cdp.send('Runtime.evaluate', { expression, awaitPromise: true, returnByValue: true }, S);
    if (r.exceptionDetails) {
      const d = r.exceptionDetails; const msg = d.exception ? (d.exception.description || d.exception.value) : d.text;
      throw new Error(String(msg));
    }
    return r.result.value;
  };
  const navigate = async (url) => { const w = cdp.waitFor('Page.loadEventFired', S, 60000); await cdp.send('Page.navigate', { url }, S); await w; };

  const report = { parts: [], errors: [] };
  try {
    await cdp.send('Emulation.setDeviceMetricsOverride', { width: 1600, height: 1000, deviceScaleFactor: 1, mobile: false }, S);
    await navigate(pathToFileURL(harnessPath).href);
    const fontsOk = await evaluate('window.__ready');
    const bad = fontsOk.filter(x => !x[1]);
    console.log('fonts loaded: ' + (fontsOk.length - bad.length) + '/' + fontsOk.length + (bad.length ? '  MISSING: ' + bad.map(x => x[0]).join(', ') : ''));

    const runPart = async (p) => {
      const t = Date.now();
      try {
        const v = await evaluate('(async () => {\n' + p.code + '\n})().then(r => { try { return JSON.stringify(r); } catch (e) { return String(r); } })');
        console.log('ran ' + p.label + ' in ' + ((Date.now() - t) / 1000).toFixed(1) + 's -> ' + String(v).slice(0, 160));
        report.parts.push({ label: p.label, ok: true });
      } catch (e) {
        // Part 015 throws in real Figma too (LIB abs() sets layoutPositioning on a non-auto-layout frame);
        // part 016 deletes its half-drawn 07/08 and redraws them, so this failure is expected.
        const expected = /015/.test(p.label) && /layoutPositioning/.test(e.message);
        console.log((expected ? 'expected failure (replaced by part 016) ' : 'FAILED ') + p.label + ': ' + e.message.split('\n').slice(0, 4).join(' | '));
        report.parts.push({ label: p.label, ok: false, error: e.message.split('\n')[0] });
        if (!expected) report.errors.push(p.label + ': ' + e.message.split('\n')[0]);
      }
    };

    // 1) Design System (3 parts) with the node ids the later scripts hard-code
    const ds = scriptParts(path.join(SPEC, 'design-system.figma.js'));
    await runPart(ds[0]);
    await evaluate("__mock.alias('2:2', figma.root.children.find(p => p.name.indexOf('Design System') >= 0)); true");
    await runPart(ds[1]);
    await evaluate("(() => { const h = __mock.findByName('__lib (helper – sẽ xoá)'); __mock.alias('3:2', h); __mock.alias('3:3', h && h.children.find(c => c.name === 'lib')); return true; })()");
    for (const p of ds.slice(2)) await runPart(p);

    // 2) the 9 sections on page "📱 Màn hình" (ids 4:313 / 4:316 are used by screens-01-08)
    await evaluate('(async () => { const page = figma.root.children.find(p => p.name.indexOf("Màn hình") >= 0); await figma.setCurrentPageAsync(page);' +
      'const names = ' + JSON.stringify(SECTIONS) + '; const secs = names.map((n, i) => { const s = figma.createSection(); s.name = n; s.x = 0; s.y = i * 3200; s.resizeWithoutConstraints(2780, 3000); page.appendChild(s); return s; });' +
      "__mock.alias('4:313', secs[0]); __mock.alias('4:316', secs[1]); return true; })()");

    // 3) screens 01–08 (use_figma scripts that eval the LIB text node)
    for (const p of scriptParts(path.join(SPEC, 'screens-01-08.figma.js'))) await runPart(p);

    // 4) screens 09–43 (self-contained plugin code.js; waits for figma.closePlugin)
    {
      const code = fs.readFileSync(path.join(SPEC, 'screens-09-43.figma.js'), 'utf8');
      const t = Date.now();
      try {
        const msg = await evaluate('new Promise((resolve, reject) => { figma.__onClose = resolve; try { (function () {\n' + code + '\n})(); } catch (e) { reject(e); } })');
        console.log('ran screens-09-43.figma.js (plugin) in ' + ((Date.now() - t) / 1000).toFixed(1) + 's -> closePlugin: ' + msg);
        report.parts.push({ label: 'screens-09-43.figma.js (plugin)', ok: !/lỗi|Lỗi/.test(msg), msg });
      } catch (e) {
        console.log('FAILED plugin: ' + e.message);
        report.errors.push('plugin: ' + e.message.split('\n')[0]);
      }
    }

    const unknown = await evaluate('__mock.unknownProps()');
    if (Object.keys(unknown).length) console.log('WARNING unknown node properties set by scripts (not rendered): ' + JSON.stringify(unknown));
    const warns = await evaluate('__mock.warnings()');
    if (warns.length) console.log('mock warnings: ' + warns.slice(0, 20).join(' | '));
    console.log('nodes: ' + JSON.stringify(await evaluate('__mock.stats()')));

    // 5) serialize
    const { list, pluginErrors } = await evaluate('__mock.outputs()');
    if (pluginErrors) { console.log('PLUGIN ERROR REPORT FRAME:\n' + pluginErrors); report.errors.push('plugin error frame: ' + pluginErrors.replace(/\s+/g, ' ').slice(0, 400)); }
    const screens = list.filter(o => o.kind === 'screen').sort((a, b) => a.num.localeCompare(b.num));
    const dsFrames = list.filter(o => o.kind === 'ds');
    const want = o => !opt.only || (o.kind === 'screen' ? opt.only.includes(o.num) || opt.only.includes(String(+o.num)) : opt.only.includes('ds'));
    const css = fontFaceCss(relUrl);
    const jobs = [];
    for (const o of screens) {
      o.file = o.num + '-' + slug(o.name.replace(/^\d\d\s*·\s*/, ''));
      o.W = Math.ceil(o.w - 0.01); o.H = Math.ceil(o.h - 0.01);
      o.diag = await evaluate('__mock.diagnose(' + JSON.stringify(o.id) + ')');
      if (o.diag.icons.length || o.diag.overflow.length || o.diag.clipped.length) console.log('  check ' + o.num + ': ' + JSON.stringify(o.diag));
      if (!want(o)) continue;
      const inner = await evaluate('__mock.serialize(' + JSON.stringify(o.id) + ')');
      const html = '<!doctype html>\n<html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=' + o.W + '">\n<title>' + htmlEsc(o.name) + '</title>\n' +
        '<!-- Figma frame "' + htmlEsc(o.name) + '" (section "' + htmlEsc(o.section) + '"), ' + o.W + 'x' + o.H + '. Generated from design/spec/*.figma.js by design/spec-render/render.js. -->\n' +
        '<style>\n' + css + '\nhtml,body{margin:0;padding:0;}body{position:relative;width:' + o.W + 'px;height:' + o.H + 'px;overflow:hidden;background:#FFFFFF;-webkit-font-smoothing:antialiased;}\n</style></head>\n<body>\n' + inner + '\n</body></html>\n';
      fs.writeFileSync(path.join(OUT, o.file + '.html'), html);
      jobs.push(o);
    }
    for (const o of dsFrames) {
      o.file = 'ds-' + slug(o.name);
      const pad = 24, top = o.type === 'FRAME' ? pad : 40;
      o.W = Math.ceil(o.w + pad * 2); o.H = Math.ceil(o.h + top + pad);
      if (!want(o)) continue;
      const inner = await evaluate('__mock.serialize(' + JSON.stringify(o.id) + ')');
      const label = o.type === 'FRAME' ? '' : '<div title="' + htmlEsc((o.variants || []).join(' | ')) + '" style="position:absolute;left:' + pad + 'px;right:' + pad + 'px;top:14px;font:500 13px/16px \'Be Vietnam Pro\',sans-serif;color:#9747FF;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">' + (o.type === 'COMPONENT_SET' ? '❖ ' : '◆ ') + htmlEsc(o.name) + (o.variants ? ' <span style="color:#8a8a8a">· ' + o.variants.length + ' variants</span>' : '') + '</div>';
      const html = '<!doctype html>\n<html lang="vi"><head><meta charset="utf-8">\n<title>Design System · ' + htmlEsc(o.name) + '</title>\n' +
        '<!-- Design System page node "' + htmlEsc(o.name) + '" (' + o.type + '). Generated by design/spec-render/render.js. -->\n' +
        '<style>\n' + css + '\nhtml,body{margin:0;padding:0;}body{position:relative;width:' + o.W + 'px;height:' + o.H + 'px;overflow:hidden;background:#F5F5F5;-webkit-font-smoothing:antialiased;}\n</style></head>\n<body>\n' + label +
        '<div style="position:absolute;left:' + pad + 'px;top:' + top + 'px;">' + inner + '</div>\n</body></html>\n';
      fs.writeFileSync(path.join(OUT, o.file + '.html'), html);
      jobs.push(o);
    }
    console.log('wrote ' + jobs.length + ' HTML files');

    // 6) screenshots
    if (opt.shots) {
      for (const o of jobs) {
        const W = o.W, H = o.H;
        await cdp.send('Emulation.setDeviceMetricsOverride', { width: W, height: Math.min(H, 16000), deviceScaleFactor: opt.scale, mobile: false }, S);
        await navigate(pathToFileURL(path.join(OUT, o.file + '.html')).href);
        await evaluate('(async () => { document.body.offsetHeight; await document.fonts.ready; await new Promise(r => requestAnimationFrame(() => requestAnimationFrame(r))); return true; })()');
        const shot = await cdp.send('Page.captureScreenshot', { format: 'png', clip: { x: 0, y: 0, width: W, height: H, scale: 1 }, captureBeyondViewport: true }, S);
        fs.writeFileSync(path.join(OUT, o.file + '.png'), Buffer.from(shot.data, 'base64'));
      }
      console.log('wrote ' + jobs.length + ' PNG files');
    }

    // 7) index.md (always lists everything that rendered)
    if (!opt.only) {
      const nums = new Set(screens.map(s => s.num));
      const missing = []; for (let i = 1; i <= 43; i++) { const n = String(i).padStart(2, '0'); if (!nums.has(n)) missing.push(n); }
      const lines = ['# Senpai ơi – Mobile App Redesign · reference renders', '',
        'Rendered without Figma from the scripts that drew the file (`design/spec/*.figma.js`) by `node design/spec-render/render.js` on ' + new Date().toISOString().slice(0, 16).replace('T', ' ') + '.',
        'Each PNG has a standalone HTML twin (same name) whose CSS mirrors the Figma auto-layout tree (`data-name` attributes = Figma layer names).',
        'PNGs are 1× (' + (opt.scale !== 1 ? 'scale ' + opt.scale : 'device pixel = Figma pixel') + '); screens are 390 px wide, tall screens keep the frame\'s real height.', '',
        '## Screens (' + screens.length + '/43)', '', '| # | Figma frame name | Section | PNG | Size (px) |', '|---|---|---|---|---|'];
      for (const o of screens) lines.push('| ' + o.num + ' | ' + o.name.replace(/\|/g, '\\|') + ' | ' + o.section + ' | [' + o.file + '.png](' + o.file + '.png) | ' + o.W + ' × ' + o.H + ' |');
      lines.push('', '## Design System (page “🎨 Design System”)', '', '| Node | Type | Variants (in canvas order) | PNG | Size (px, incl. canvas margin) |', '|---|---|---|---|---|');
      for (const o of dsFrames) lines.push('| ' + o.name + ' | ' + o.type + ' | ' + (o.variants ? o.variants.join('<br>') : '–') + ' | [' + o.file + '.png](' + o.file + '.png) | ' + o.W + ' × ' + o.H + ' |');
      lines.push('', '## Notes', '');
      if (missing.length) lines.push('- **Missing screens:** ' + missing.join(', '));
      else lines.push('- All 43 screens rendered.');
      if (report.errors.length) for (const e of report.errors) lines.push('- Script error: ' + e);
      lines.push('- Script part `015` of screens-01-08 throws (LIB `abs()` sets `layoutPositioning` on the non-auto-layout map frame) exactly as it would in Figma; part `016` deletes its half-drawn 07 and redraws 07–08.');
      const iconFail = screens.filter(o => o.diag && o.diag.icons.length);
      lines.push(iconFail.length ? '- **Icon ligatures not resolved:** ' + iconFail.map(o => o.num + ' (' + o.diag.icons.join(', ') + ')').join('; ') : '- Automatic check: every Material Symbols / Material Icons ligature resolved to a glyph (no icon rendered as a word).');
      const scroll = screens.filter(o => o.diag && o.diag.overflow.some(s => /\(clipped\)/.test(s))).map(o => o.num);
      if (scroll.length) lines.push('- Rows wider than the screen and cut at the edge on purpose (horizontal-scroll chips / cards / tabs): ' + scroll.join(', ') + '.');
      const real = screens.filter(o => o.diag && o.diag.overflow.some(s => !/\(clipped\)/.test(s)));
      if (real.length) {
        lines.push('- Content that overflows its box **because of how the script sizes it** (Figma shows the same; worth fixing in the Flutter build rather than copying):');
        for (const o of real) lines.push('  - ' + o.num + ': ' + o.diag.overflow.filter(s => !/\(clipped\)/.test(s)).join('; '));
      }
      lines.push('- Section names come from the 09–43 plugin / earlier mock (the call that created the sections is not in `design/spec`).',
        '- Screens 07–08 are the versions from script part `016` (it replaces the earlier `015` drawing), and the plugin\'s `polishHome` tweaks (equal-height feature tiles and wrapping footer on 01, `*_border` icon names in sections 1–2) are applied, as in the final file.',
        '- Fonts: Be Vietnam Pro, Bricolage Grotesque, Zen Maru Gothic (assets/fonts), Material Symbols Rounded (pub cache copy) and Material Icons Round (google/material-design-icons) in `design/spec-render/fonts/`. Japanese glyphs missing from Be Vietnam Pro fall back to the system font, as Figma also substitutes them.',
        '- Layout is computed by Chrome flexbox mimicking Figma auto-layout (HUG = max-content, FILL = flex 1 1 0 / stretch, FIXED = px); tiny sub-pixel differences from Figma\'s own text metrics are possible.');
      fs.writeFileSync(path.join(OUT, 'index.md'), lines.join('\n') + '\n');
      console.log('wrote index.md (' + screens.length + ' screens, ' + dsFrames.length + ' DS frames)' + (missing.length ? ' MISSING: ' + missing.join(',') : ''));
    }
    console.log('done in ' + ((Date.now() - T0) / 1000).toFixed(1) + 's');
  } finally {
    if (!opt.keepOpen) { cdp.close(); proc.kill(); }
  }
}

main().catch(e => { console.error(e && e.stack || e); process.exit(1); });
