class_name CJKMetrics
extends RefCounted

## Character classification helpers for CJK-aware typesetting.
##
## Every predicate takes a single-character [String] and works on Unicode
## code points, so surrogate pairs and combining sequences are handled by
## Godot's own UTF-32 [String] representation.

## Characters that must never start a line (kinsoku: 行頭禁則).
const NO_LINE_START := "、。，．・：；？！‼⁇⁈⁉…‥・ゝゞヽヾー" \
	+ "）］｝〕〉》」』】〙〗〟’”｠»" \
	+ "‐゠–〜～!?‼⁇⁈⁉・:;/。" \
	+ "，．、；：！？］｝〉》」』】〙〗〟’”" \
	+ " 　"

## Characters that must never end a line (kinsoku: 行末禁則).
const NO_LINE_END := "（［｛〔〈《「『【〘〖〝‘“｟«" \
	+ "（［｛〔〈《「『【〝‘“" \
	+ "＄￥£¥＃＠§※〒"

## Closing punctuation eligible for half-width squeezing.
const CLOSE_PUNCT := "、。，．：；！？」』】〕〉》］｝”’〕〗〙〟｠" \
	+ ")]}>,.;:!?%"

## Opening punctuation eligible for half-width squeezing.
const OPEN_PUNCT := "「『【〔〈《［｛‘“([{<"

## Full-width punctuation that occupies a whole em square.
const FULLWIDTH_PUNCT := "、。，．：；！？（）「『】〔〕｛｝〈〉《》【】" \
	+ "・…‥ー～％＄￥＃＠"

## CJK ideographs and kana ranges.
const CJK_RANGES := [
	[0x3040, 0x309F],  # Hiragana
	[0x30A0, 0x30FF],  # Katakana
	[0x31F0, 0x31FF],  # Katakana phonetic extensions
	[0x3400, 0x4DBF],  # CJK Unified Ideographs Extension A
	[0x4E00, 0x9FFF],  # CJK Unified Ideographs
	[0xA000, 0xA48F],  # Yi syllables
	[0xAC00, 0xD7AF],  # Hangul syllables
	[0xF900, 0xFAFF],  # CJK Compatibility Ideographs
	[0xFF66, 0xFF9D],  # Halfwidth Katakana
]


## Returns the Unicode code point of the first character of [c].
static func code_point(c: String) -> int:
	if c.is_empty():
		return 0
	return c.unicode_at(0)


## True when [c] is a CJK ideograph, kana or Hangul syllable.
static func is_cjk(c: String) -> bool:
	if c.is_empty():
		return false
	var cp := code_point(c)
	for r in CJK_RANGES:
		if cp >= r[0] and cp <= r[1]:
			return true
	return false


## True when [c] is an ASCII letter or digit.
static func is_latin(c: String) -> bool:
	if c.is_empty():
		return false
	var cp := code_point(c)
	return (cp >= 0x41 and cp <= 0x5A) or (cp >= 0x61 and cp <= 0x7A) or (cp >= 0x30 and cp <= 0x39)


## True when [c] is any non-CJK, non-space character that should still be
## kept apart from adjacent CJK text (Latin, Greek, Cyrillic, ...).
static func is_western(c: String) -> bool:
	if c.is_empty():
		return false
	if is_cjk(c):
		return false
	var cp := code_point(c)
	if cp == 0x20 or cp == 0x09:
		return false
	if cp < 0x80:
		return true
	# Latin-1 / Latin Extended / Greek / Cyrillic ranges.
	if cp >= 0x00A0 and cp <= 0x052F:
		return true
	return false


## True when [c] is full-width punctuation that fills a whole em square.
static func is_fullwidth_punct(c: String) -> bool:
	if c.is_empty():
		return false
	return FULLWIDTH_PUNCT.contains(c)


## True when [c] may appear inside a Latin word.
##
## Latin words must not be broken across lines, so the characters that glue
## a word together are listed here. A period is deliberately excluded
## because it usually ends a sentence rather than a word.
static func is_word_char(c: String) -> bool:
	if c.is_empty():
		return false
	var cp := code_point(c)
	if cp >= 0x30 and cp <= 0x39:
		return true
	if cp >= 0x41 and cp <= 0x5A:
		return true
	if cp >= 0x61 and cp <= 0x7A:
		return true
	if cp >= 0xC0 and cp <= 0x24F:
		# Latin extended, Greek and Cyrillic letters.
		return true
	return cp == 0x2D or cp == 0x2F or cp == 0x5F or cp == 0x27


## True when a line may be broken between [prev] and [next].
##
## A break is allowed between two CJK characters, around spaces and at
## script boundaries, but never inside a Latin word.
static func can_break_between(prev: String, next: String) -> bool:
	if prev.is_empty() or next.is_empty():
		return true
	if is_word_char(prev) and is_word_char(next):
		return false
	return true


## True when [c] is closing punctuation.
static func is_close_punct(c: String) -> bool:
	if c.is_empty():
		return false
	return CLOSE_PUNCT.contains(c)


## True when [c] is opening punctuation.
static func is_open_punct(c: String) -> bool:
	if c.is_empty():
		return false
	return OPEN_PUNCT.contains(c)


## True when [c] must not start a line.
##
## [param extra] holds additional characters configured by the user. The
## built-in set already covers the characters listed in the Unicode line
## breaking algorithm, which is what the engine's own breaker uses, so the
## extra set exists for characters that are not part of that algorithm, such
## as the Japanese prolonged sound mark.
static func is_forbidden_at_line_start(c: String, extra: String = "") -> bool:
	if c.is_empty():
		return false
	if NO_LINE_START.contains(c):
		return true
	return not extra.is_empty() and extra.contains(c)


## True when [c] must not end a line.
##
## See [method is_forbidden_at_line_start] for the meaning of [param extra].
static func is_forbidden_at_line_end(c: String, extra: String = "") -> bool:
	if c.is_empty():
		return false
	if NO_LINE_END.contains(c):
		return true
	return not extra.is_empty() and extra.contains(c)


## True when a visible gap should be inserted between [prev] and [next].
##
## The rule is the one used by Chinese and Japanese typesetting guides:
## a quarter-em space separates CJK characters from adjacent Latin letters
## and digits so the two scripts do not visually collide.
static func needs_spacing(prev: String, next: String) -> bool:
	if prev.is_empty() or next.is_empty():
		return false
	if prev == " " or next == " ":
		return false
	var a := is_cjk(prev) or is_fullwidth_punct(prev)
	var b := is_cjk(next) or is_fullwidth_punct(next)
	return (a and is_western(next)) or (b and is_western(prev))


## True when [next] is punctuation that may be squeezed to half width
## because it directly follows another punctuation mark of the same class.
##
## Only full-width punctuation participates: half-width ASCII marks are
## already narrow and squeezing them would look wrong.
static func should_squeeze(prev: String, next: String) -> bool:
	if prev.is_empty() or next.is_empty():
		return false
	if not (is_fullwidth_punct(prev) and is_fullwidth_punct(next)):
		return false
	return (is_close_punct(prev) and is_close_punct(next)) \
			or (is_open_punct(prev) and is_open_punct(next))
