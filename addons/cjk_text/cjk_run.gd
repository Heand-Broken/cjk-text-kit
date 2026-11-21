class_name CJKRun
extends RefCounted

## A single styled, typeset-ready fragment of text.
##
## Runs are produced by [CJKParser]. Each run holds text that shares the
## same visual style and, within a run, no typesetting adjustment is
## required. The layout engine measures runs independently, so a run also
## carries the extra spacing and squeeze adjustments that apply to it.

## The literal text of this run.
var text: String = ""

## Bold styling.
var bold: bool = false

## Italic styling.
var italic: bool = false

## Underline styling.
var underline: bool = false

## Whether [member color] should be used instead of the inherited colour.
var has_color: bool = false

## Explicit colour when [member has_color] is true.
var color: Color = Color.WHITE

## Explicit font size in pixels, or 0 to inherit the default size.
var font_size: int = 0

## Phonetic reading (furigana / ruby) attached above this run.
##
## When non-empty the run is rendered as the base text of a ruby pair.
var ruby: String = ""

## Extra space inserted *before* this run, expressed in em units.
##
## Used for the quarter-em gap between CJK text and adjacent Latin words.
var gap_before: float = 0.0

## Amount subtracted from this run's advance width, expressed in em units.
##
## Used to squeeze punctuation that directly follows another punctuation mark.
var advance_reduction: float = 0.0

## Whether the previous character in the source text was a ruby base.
var _unused: bool = false


func _init(p_text: String = "") -> void:
	text = p_text


## True when this run carries a ruby annotation.
func has_ruby() -> bool:
	return not ruby.is_empty()


## Duplicates this run, optionally replacing the text.
func clone_with_text(p_text: String) -> CJKRun:
	var r := CJKRun.new(p_text)
	r.bold = bold
	r.italic = italic
	r.underline = underline
	r.has_color = has_color
	r.color = color
	r.font_size = font_size
	r.ruby = ruby
	r.gap_before = gap_before
	r.advance_reduction = advance_reduction
	return r


func _to_string() -> String:
	return "CJKRun(%s, ruby=%s, gap=%.2f, red=%.2f)" % [
		text, ruby, gap_before, advance_reduction]
