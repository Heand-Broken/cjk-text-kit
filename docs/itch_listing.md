# itch.io listing — CJK Text Kit

Everything needed to publish the addon on itch.io. Copy the blocks marked
"copy" directly into the store page.

---

## 1. Page title

```
CJK Text Kit for Godot 4 — Furigana, Kinsoku & CJK Typography
```

Alternative if you prefer a shorter one:

```
CJK Text Kit — Ruby & CJK Typesetting for Godot 4
```

## 2. Tagline

Shown next to the price on the browse page and in search results.

```
The CJK typography layer Godot never shipped.
```

## 3. Pricing

itch.io lets you set a price and then run sales. Suggested ladder:

| Phase | Price | Note |
|---|---|---|
| Launch (first 2 weeks) | **$9.99** | Early-adopter price. Advertise the launch discount in your posts. |
| Regular | **$19.99** | Matches the price band of comparable Godot plugins on itch ($16–$32). |
| Optional studio tier | **$29.99** | Same plugin plus a source-code-per-developer licence and priority support for a team. |

**Set the itch.io platform share to 0 %** if you want to keep 100 % of the
revenue during the launch, then raise it later if you want itch.io's
promotional support. The default is 10 %.

Do not use "pay what you want" for the main tier: it signals low perceived
value. A fixed price with an occasional sale performs better for tools.

## 4. Description — copy

```markdown
**Godot's RichTextLabel cannot typeset CJK text properly. CJK Text Kit can.**

On Godot 4.7.2, `[ruby=かんじ]漢字[/ruby]` is not a tag — it comes out of
the engine as the literal string `[ruby=かんじ]漢字[/ruby]`. There is no
furigana support anywhere in the engine, no space is inserted between
Chinese and Latin text, and full-width punctuation always eats a full
em-square even when two marks sit next to each other.

CJK Text Kit is a drop-in text control that fixes exactly those things.

![screenshot](https://your-cdn.example/screenshots/demo.png)

---

### ✨ Ruby / furigana annotations

`[ruby=かんじ]漢字[/ruby]` draws the reading above the base text, centres it
over the base, and reserves the vertical space the line needs — no manual
line-height tweaking.

![ruby](https://your-cdn.example/screenshots/ruby.png)

### ✨ Automatic CJK/Latin spacing

A quarter em is inserted wherever CJK text touches a Latin word or a number.

Measured on Godot 4.7.2 at 32 px:

| | Engine | CJK Text Kit |
|---|---|---|
| `測試AB` | 106.00 px | **114.00 px** |
| gap between `測試` and `AB` | 0 px | **8.00 px** (0.25 em) |

### ✨ Punctuation squeezing

Adjacent full-width marks of the same class compress to half width, so
`真的？！」` stops wasting an em-square.

| | Engine | CJK Text Kit |
|---|---|---|
| `。` advance | 32.00 px (full em) | **−16.00 px** when adjacent |

### ✨ Kinsoku shori

Closing marks never start a line and opening marks never end one. The
engine's own line breaker already follows the Unicode line breaking
algorithm, so this is not a fix — it is an explicit, configurable
guarantee, with extra character sets you can add from the inspector.

### ✨ Latin words are never split

`ORA-1250` stays in one piece. Words longer than the line are broken as a
last resort.

---

### 🚀 Install

1. Unzip `addons/cjk_text/` into your project.
2. Enable **CJK Text** in *Project → Project Settings → Plugins*.
3. Add a `CJKText` node.

### 💻 Usage

```gdscript
var label := CJKText.new()
label.font = CJKFonts.create_system_font()   # no font files to ship
label.font_size = 28
label.ruby_font_size = 14
label.text = "「[ruby=きょう]今日[/ruby]は良い天気ですね。」"
add_child(label)
```

No font binary is bundled — CJK fonts are huge and often restricted, so
the addon resolves one that is already installed on the player's system,
or you point it at a font file you are allowed to ship.

### 🏷️ Markup

`[b]` `[i]` `[u]` `[color=#ff8800]` `[font_size=28]` `[ruby=かんじ]`

The parser is forgiving: unknown tags stay as text, stray closing tags are
ignored, and unclosed tags are closed at the end of the string. Dialogue
loaded from a save file will not break it.

### ✅ Compatibility

* **Verified on Godot 4.7.2 and 4.7 stable.** The full test suite passes on
  both.
* Earlier 4.x releases are expected to work, but are not verified.
* GDScript only, no dependencies, no autoloads, no project settings
  changes.

### 📜 Licence

One licence per developer. Unlimited commercial and non-commercial projects.
No royalties, no revenue caps, no seat fees. Compiled games can be sold on
any platform without attribution.

### 🗺️ Roadmap

* Vertical text (縦書き) — the engine's text server reports
  `FEATURE_VERTICAL_LAYOUT = false`, so it needs its own glyph layout.
* Hanging punctuation.
* Paragraph alignment, indentation and text spacing.

Questions or bugs? Leave a comment on this page.
```

## 5. Tags

itch.io shows at most five tags and they drive search. Use these five:

```
godot
godot4
visual-novel
typography
japanese
```

Alternatives worth swapping in depending on the audience you are chasing:
`chinese`, `cjk`, `tool`, `plugin`, `localization`, `dialogue`.

## 6. Classification

- **Category:** Assets → *Tools* (or *Templates* if you also ship a
  template project)
- **Genre:** Not applicable for a tool
- **Platforms:** Windows, macOS, Linux, Web
- **Tags:** as above
- **Status:** Released
- **Rating:** Leave empty, or set "This is not a game" if itch asks

## 7. Cover image

itch.io shows the cover at 630 × 250 and crops to 50 % on some surfaces.
Keep the important content in the centre and avoid thin text.

The cover in `docs/screenshots/cover.png` is generated by the project itself
(`docs/cover/cover.gd`), so it stays in sync with the actual rendering. It
shows the title on the left and a live ruby-annotated sample on the right.

## 8. Screenshots

Upload at least three, in this order:

1. `demo.png` — the side-by-side comparison against `RichTextLabel`.
2. `ruby.png` — a close-up of furigana over Japanese text.
3. `spacing.png` — the CJK/Latin gap and the squeezed punctuation, with the
   measurements annotated.

Keep them at 1280 × 720 or larger.

## 9. Update log entry for launch

```markdown
## 1.0.0 — first release

* Ruby / furigana annotations with automatic line height.
* Automatic quarter-em spacing between CJK and Latin text.
* Half-width squeezing for adjacent full-width punctuation.
* Kinsoku line breaking with a configurable forbidden character set.
* Latin words are never split across lines.
* Lightweight markup: [b] [i] [u] [color] [font_size] [ruby].
* 61 headless tests, verified on Godot 4.7.2 and 4.7 stable.
```

## 10. Promotion plan

itch.io is a niche audience and the buyers of a CJK typography tool are
mostly Japanese and Chinese developers, so a single-channel launch will
underperform. Budget for four channels:

| Channel | Why | Effort |
|---|---|---|
| **itch.io devlog + social posts** | The people already browsing itch for Godot assets. | Low |
| **BOOTH (pixiv)** | The main marketplace for Japanese indie tools. A Japanese README and a Japanese demo video. | Medium |
| **X / Twitter** | Japanese and Chinese game-dev circles share tools this way. A short before/after video works best. | Low |
| **Baidu / Bilibili / Xiaohongshu** | Chinese indie developers and visual novel circles. Post the side-by-side comparison image. | Medium |
| **Godot Asset Store** | Free listing, even though it cannot take payment yet. It is the official store and gives you a permanent page. | Low |

A 30-second video of the same sentence rendered by the engine and by the
addon is the single highest-leverage asset. The `[ruby]` tag turning into
literal text on the right side is instantly legible to anyone who has
tried to typeset Japanese in Godot.

## 11. Honest revenue expectation

Do the arithmetic before you count on this paying for anything:

* A comparable mature tool on itch.io sold **567 copies for $4,869** in a
  full year (Pixel Composer, public Patreon report).
* Comparable Godot plugins on itch.io sit between **$5 and $35**.
* A new tool with no reviews, no video and no track record typically starts
  in the low tens of sales per month, and grows slowly.

A realistic first-year outcome for a **$19.99** plugin with a good demo and
consistent promotion is **60–200 sales, roughly $900–$3,000**. Treat that
as the first brick, not the whole wall. The credible path to a real income
is a small product line (a CJK text tool, a Japanese font/asset tool, a
dialogue演出 pack) that cross-promotes, plus sales on BOOTH and Steam
Workshops where the audience is larger.

The strongest argument for this product is not the revenue. It is that the
CJK typography gap in Godot is real, it is confirmed by measurement, and
nobody has shipped a commercial solution to it yet.
