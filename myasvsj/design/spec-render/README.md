# spec-render: Figma reference images without Figma

Renders every frame of the Figma file "Senpai ơi – Mobile App Redesign" (43 phone screens and the
Design System page) to PNG and standalone HTML. It does not use Figma. It re-runs the exact
scripts that drew the file (`design/spec/*.figma.js`) against a mock of the Figma Plugin API.

```
node design/spec-render/render.js
```

Output goes to `design/figma-export/ref/`:
- `NN-<slug>.png` / `.html` for each screen
- `ds-<name>.png` / `.html` for each Design System node
- `index.md`, which lists every screen with its frame name, section, size and check results

A full run takes about 10 s. Needs Node 22+ (it uses the global `WebSocket`) and Chrome or Edge.
If the browser is somewhere else, set `CHROME=<path>`.

Options:

| option | effect |
|---|---|
| `--only 05,12` / `--only ds` | rewrite only these HTML/PNG files (all scripts still run; `index.md` is left alone) |
| `--no-shots` | write the HTML files but skip the PNGs |
| `--scale 2` | take PNGs at 2× device pixels |
| `--verbose` | print the page's console output |

## How it works

1. `render.js` builds `tmp/harness.html`, which holds the fonts and `mock-figma.js`. It starts
   headless Chrome with `--remote-debugging-port` and talks to it over the DevTools protocol.
2. `mock-figma.js` backs every Figma node with a DOM element. Its CSS mirrors Figma auto layout:
   - HORIZONTAL/VERTICAL → flex row/column, `itemSpacing` → `gap`, padding as padding
   - `primaryAxisAlignItems` → `justify-content` (SPACE_BETWEEN too), `counterAxisAlignItems` → `align-items`
   - sizing: HUG → `max-content`, FILL → `flex: 1 1 0` or `align-self: stretch`, FIXED → px
   - WRAP with `counterAxisSpacing` → `flex-wrap` plus `row-gap`
   - ABSOLUTE children and children of non-auto-layout frames → `position: absolute` at x/y
   - `clipsContent` → `overflow: hidden`
   - strokes (per-side, INSIDE/CENTER/OUTSIDE, dashed) → an overlay element that takes no space,
     like Figma strokes
   - drop shadows → `box-shadow`
   - text styles, maxLines + ENDING → line clamp, range fills, range fonts and decorations
   - colour variables → their hex values
   - components, instances, `setProperties` variant swaps, `rescale`, `createNodeFromSvg` → inline SVG

   Chrome is the layout engine, so reads such as `node.width`, `node.height`, `node.x` and
   `node.y` return real measured values with the real fonts. The scripts depend on this, for
   example `area.height - panel.height`, `fab()` and `overlayBadge()`.
3. The scripts run in the order they ran in Figma:
   - `design-system.figma.js` parts 1–3 (variables, styles, LIB helper text, components,
     Foundations)
   - the 9 sections, created here because the call that made them is not in `design/spec`
   - `screens-01-08.figma.js` parts 013–016 (part 015 fails as it did in Figma, and 016 replaces
     07–08)
   - the `screens-09-43.figma.js` plugin, including `polishHome` and `linkStyles`

   The node IDs the scripts hard-code (`2:2`, `3:2`, `3:3`, `4:313`, `4:316`) are mapped to the
   matching mock nodes.
4. Each screen's DOM subtree is serialized into a standalone HTML file. Styles are inline, and
   fonts load through relative `@font-face` URLs. Each file is then opened at the frame's own
   size and captured with `Page.captureScreenshot`.
5. Automatic checks are written to `index.md`:
   - icon ligatures that did not resolve
   - children that stick out of a fixed or fill-width auto-layout parent

## Fonts

| family | file |
|---|---|
| Be Vietnam Pro, Bricolage Grotesque (variable), Zen Maru Gothic | `assets/fonts/` |
| Material Symbols Rounded (variable, ligatures) | `fonts/MaterialSymbolsRounded.ttf`, a copy of `rawFontsUnfixed/MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf` from the pub cache package `material_symbols_icons-4.2960.0` |
| Material Icons Round (filled icons) | `fonts/MaterialIconsRound-Regular.otf`, from `github.com/google/material-design-icons/raw/master/font/` |

## Files

- `render.js`: the orchestrator (CDP client, script runner, HTML/PNG/index writer)
- `mock-figma.js`: the DOM-backed Figma Plugin API mock (runs in the page)
- `fonts/`: the icon fonts
- `tmp/`: throwaway files (harness page, Chrome profile)
