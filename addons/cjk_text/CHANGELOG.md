# Changelog

All notable changes to CJK Text Kit are recorded here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project uses [Semantic Versioning](https://semver.org/).

## [1.0.0] — 2026-11-22

First public release.

### Added

- **`CJKText` control** that typesets Chinese, Japanese and Korean text with
  its own line breaker, instead of relying on `RichTextLabel`.
- **Ruby / furigana annotations.** `[ruby=かんじ]漢字[/ruby]` draws the
  reading above the base text, centres it over the base and reserves the
  vertical space the line needs.
- **Automatic CJK/Latin spacing.** A quarter em is inserted wherever CJK
  text touches a Latin word or a number.
- **Punctuation squeezing.** Adjacent full-width marks of the same class
  compress to half width.
- **Kinsoku shori.** Closing marks never start a line, opening marks never
  end one, and both character sets can be extended from the inspector.
- **Latin word integrity.** Words are never broken across lines unless the
  word is longer than the line itself.
- **Lightweight markup.** `[b]`, `[i]`, `[u]`, `[color=…]`, `[font_size=…]`
  and `[ruby=…]`. The parser keeps unknown tags as literal text, ignores
  stray closing tags and closes unclosed tags at the end of the string.
- **`CJKFonts` helpers.** Resolves an installed CJK family at runtime,
  lists the families that are available and reports whether the system can
  render Han characters. No font binary is shipped with the addon.
- **Headless test suite.** 61 checks covering character classification,
  markup parsing, typesetting splits, kinsoku, ruby geometry, spacing,
  squeezing and the control itself.
- **Feature verification script.** Measures the addon's output against the
  engine's own line breaker so every claim in the documentation has a
  number attached.
- **Demo scene** that renders the same source with `CJKText` and with
  `RichTextLabel` side by side.

### Measured behaviour on Godot 4.7.2

At a 32 px CJK font:

| Measurement | Engine | CJK Text Kit |
|---|---|---|
| `測試AB` width | 106.00 px (0 px gap) | 114.00 px (8.00 px gap) |
| `。` advance | 32.00 px (full em) | compressed by 16.00 px when adjacent |
| Ruby line height | not supported | +19.00 px headroom |

### Compatibility

Verified on Godot 4.7.2 and Godot 4.7 stable, where the full test suite
passes on both. Earlier 4.x releases are expected to work because only
long-standing APIs are used, but they are not verified.

### Known limitations

- Vertical text is not supported. Godot's text server reports
  `FEATURE_VERTICAL_LAYOUT = false`, so it needs a separate glyph layout.
- `CJKText` does not support the engine specific markup of
  `RichTextLabel`, such as `[url]`, `[img]`, `[table]` or animation
  effects.
- Ruby bases are not split across lines, so a very long base can overflow
  a narrow control.
- The control lays out its text itself, so `visible_characters` based
  typewriter effects are not available.
