# AGENTS.md

Hugo static blog using the Blowfish theme (v3.3.0) installed as a git submodule at `themes/blowfish` tracking `main`.

## Commands

- Build/verify: `hugo` (exit 0 + `public/` regenerated = success). Hugo extended is required (v0.165+ works).
- Dev server: `hugo server -D` (`-D` includes drafts; plain `hugo server` hides them).
- New post: `hugo new content posts/<slug>.md`.
- **Rebuild Tailwind after editing any template classes**: `npm run css` (or `npm run css:watch` alongside the dev server). Requires `npm install` once.

## Gotchas

- **Fonts**: Manrope (body) / Chakra Petch (headings), loaded via project `layouts/partials/extend-head.html` (theme's `head.html` hook) and mapped in `assets/css/src/main.css` (`@theme` vars + `h1–h6` base rule). Change fonts there, not in templates.
- **Article heroes**: enabled globally (`[article] showHero = true`, `heroStyle = "basic"`). Per-post image: `featureimage = '<file>'` front matter pointing at a page-bundle resource (verified resolution path: `hero/basic.html` → `functions/feature-image.html`; also auto-matches files named `*feature*`/`*cover*`/`*thumbnail*`/`*background*`). Homepage cards resolve identically via project `layouts/partials/functions/card-image.html` — keep it in sync if the theme's chain changes.

- **Tailwind is precompiled — Hugo never runs it**: Blowfish v3 ships a committed Tailwind v4 build at `themes/blowfish/assets/css/compiled/main.css`, and `head.html` just concatenates it. Classes used only in project templates don't exist in that file → invisible styles with zero build errors. The fix in place: this repo recompiles Tailwind itself (`assets/css/src/main.css` imports the theme's source + `@source` scans `layouts/`, `content/`, theme templates) and outputs to project `assets/css/compiled/main.css`, which shadows the theme's file via Hugo asset-mount precedence. If new classes are missing, you forgot `npm run css`.

- **Drafts are invisible in builds**: archetype sets `draft = true` and `config/_default/hugo.toml` has `buildDrafts = false`. A new post will not appear in `hugo` output or `public/` until `draft = false`.
- **Homepage is overridden**: root `layouts/index.html` completely replaces the theme's homepage layout. `[homepage]` params in `params.toml` have no effect on it — edit the template directly.
- **Header layout is custom**: `header.layout = "home-overlay"` selects project `layouts/partials/header/home-overlay.html`, which renders a fixed transparent overlay header on the homepage only (hero starts at y=0 beneath it) and falls through to the theme's `header/basic.html` everywhere else.
- **`header/basic.html` is shadowed** at project level: identical to the theme's except the brand line renders `params.header.brandText` ("KastraSec") with fallback to site title. Re-diff against the theme's file after theme updates.
- **Homepage hero is a fixed full-bleed layer**: `fixed inset-x-0 top-0 h-[85vh] -z-10` div (`#hero-background`; theme's own article-hero technique — immune to the body's max-width/padding). It works because the body background propagates to the root canvas; the posts section below is an opaque `bg-neutral-900` band that scrolls over it. Don't convert it back to an in-flow section — ancestor constraints will box it in again.
- **Homepage canvas is forced dark**: `body:has(#hero-background)` in `assets/css/custom.css` sets the body/canvas to kastra neutral-900 so the area below the hero is one uniform color edge-to-edge (past the body's `max-w-7xl` box) and through the footer. Keep that value in sync with `assets/css/schemes/kastra.css`.
- **Theme is a submodule**: clone with `git submodule update --init`; update theme with `git submodule update --remote themes/blowfish`. Never edit files inside `themes/blowfish` — changes are lost on update. Override via project-level `layouts/` or `assets/` instead.
- **Config is TOML under `config/_default/`** (not YAML), split per file: `hugo.toml`, `params.toml`, `menus.en.toml`, `languages.en.toml`, `markup.toml`.
- Custom color scheme: `assets/css/schemes/kastra.css` (navy/orange/violet, sampled from the hero image), selected via `colorScheme = "kastra"` in `params.toml`. Scheme files are plain RGB-triplet CSS variables; one palette serves both light and dark mode.
- `.gitignore` excludes `public/`, `.hugo_build.lock`, `node_modules/`, `resources/_gen`. The compiled `assets/css/compiled/main.css` IS committed — rebuild it whenever templates change.
