@tool
class_name CJKText
extends Control

## A CJK-aware text control for Godot 4.
##
## [CJKText] is a drop-in replacement for [RichTextLabel] for projects that
## typeset Chinese, Japanese or Korean text. It adds the four things the
## engine does not provide:
##
## - [b]Ruby / furigana annotations[/b] with automatic line height.
## - [b]Kinsoku shori[/b]: characters that must not start or end a line are
##   pushed to the neighbouring line instead of being orphaned.
## - [b]Automatic CJK/Latin spacing[/b]: a quarter-em space is inserted
##   where Chinese or Japanese text touches a Latin word or a number.
## - [b]Punctuation squeezing[/b]: adjacent full-width punctuation is
##   compressed to half width so that text blocks stay tight.
##
## Supported markup: [code][b][/b][/code], [code][i][/i][/code],
## [code][u][/u][/code], [code][color=#ff8800][/color][/code],
## [code][font_size=28][/font_size][/code] and
## [code][ruby=かんじ]漢字[/ruby][/code].
##
## The control lays its own text out instead of relying on
## [RichTextLabel], because the engine's line breaker cannot express
## punctuation squeezing or reserve room for ruby readings.

## Emitted after the text has been re-typeset.
signal text_relaid_out

## The markup source of the control.
@export var text: String = "":
	set(value):
		if text == value:
			return
		text = value
		_request_relayout()

## Font used for the body text. Falls back to the theme default.
@export var font: Font:
	set(value):
		font = value
		_rebuild_fonts()
		_request_relayout()

## Font size of the body text in pixels.
@export_range(1, 512, 1) var font_size: int = 24:
	set(value):
		font_size = maxi(1, value)
		_request_relayout()

## Font used for ruby readings. Falls back to [member font].
@export var ruby_font: Font:
	set(value):
		ruby_font = value
		_request_relayout()

## Font size of ruby readings in pixels. Defaults to half the body size.
@export_range(1, 128, 1) var ruby_font_size: int = 12:
	set(value):
		ruby_font_size = maxi(1, value)
		_request_relayout()

## Colour used when a run does not specify one.
@export var default_color: Color = Color(1, 1, 1, 1):
	set(value):
		default_color = value
		queue_redraw()

## Extra space between lines, in pixels.
@export_range(-64, 128, 1) var line_spacing: float = 4.0:
	set(value):
		line_spacing = value
		_request_relayout()

## Vertical gap between the ruby reading and the baseline, in pixels.
@export_range(0, 32, 1) var ruby_spacing: float = 1.0:
	set(value):
		ruby_spacing = value
		queue_redraw()

## Horizontal alignment of each line inside the control.
@export var alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT:
	set(value):
		alignment = value
		queue_redraw()

## Insert a quarter-em space between CJK characters and adjacent Latin text.
@export var cjk_latin_spacing: bool = true:
	set(value):
		cjk_latin_spacing = value
		_request_relayout()

## Compress adjacent full-width punctuation to half width.
@export var squeeze_punctuation: bool = true:
	set(value):
		squeeze_punctuation = value
		_request_relayout()

## Apply kinsoku rules so that forbidden characters never orphan a line.
##
## The engine's own line breaker already follows the Unicode line breaking
## algorithm, which covers the standard closing and opening marks. This
## option keeps the behaviour explicit and lets you extend the rule set
## with the two properties below.
@export var kinsoku: bool = true:
	set(value):
		kinsoku = value
		_request_relayout()

## Additional characters that must not start a line.
##
## Use this for characters that are not part of the Unicode line breaking
## algorithm, for example the Japanese prolonged sound mark "ー".
@export var extra_line_start_forbidden: String = "":
	set(value):
		extra_line_start_forbidden = value
		_request_relayout()

## Additional characters that must not end a line.
@export var extra_line_end_forbidden: String = "":
	set(value):
		extra_line_end_forbidden = value
		_request_relayout()

## Wrap text at the control width. When disabled the text is laid out on a
## single line and clipped to the control width.
@export var autowrap: bool = true:
	set(value):
		autowrap = value
		_request_relayout()

var _parser := CJKParser.new()
var _layout := CJKLayout.new()
var _lines: Array[CJKLayout.Line] = []
var _runs: Array[CJKRun] = []
var _fonts: Dictionary = {}
var _content_height: float = 0.0
var _relayout_queued: bool = false


func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	_rebuild_fonts()
	_relayout()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_request_relayout()


## Replaces the markup source and re-typesets immediately.
func set_text(value: String) -> void:
	text = value


## Returns the plain text with every recognised tag removed.
func get_plain_text() -> String:
	return CJKParser.strip_tags(text)


## The total height needed to display the current text.
func get_content_height() -> float:
	return _content_height


## The number of laid out lines.
func get_line_count() -> int:
	return _lines.size()


## Returns the text of the laid out line at [param index], tags removed.
func get_line_text(index: int) -> String:
	if index < 0 or index >= _lines.size():
		return ""
	var parts: Array[String] = []
	for s in _lines[index].segments:
		var run: CJKRun = _runs[s.run_index]
		parts.append(run.text.substr(s.source_start, s.source_length))
	return "".join(parts)


func _rebuild_fonts() -> void:
	var base := font
	if base == null:
		base = ThemeDB.fallback_font
	_fonts = {
		"normal": base,
		"bold": _make_variation(base, true, false),
		"italic": _make_variation(base, false, true),
		"bold_italic": _make_variation(base, true, true),
	}


func _make_variation(base: Font, bold: bool, italic: bool) -> Font:
	var fv := FontVariation.new()
	fv.base_font = base
	if bold:
		fv.variation_embolden = 0.55
	if italic:
		fv.variation_transform = Transform2D(
				Vector2(1.0, 0.0), Vector2(-0.25, 1.0), Vector2.ZERO)
	return fv


func _request_relayout() -> void:
	if _relayout_queued:
		return
	_relayout_queued = true
	if is_inside_tree():
		_relayout.call_deferred()
	else:
		_relayout_queued = false
		_relayout()


func _relayout() -> void:
	_relayout_queued = false
	if _fonts.is_empty():
		_rebuild_fonts()
	_runs = _parser.parse(text)
	if not cjk_latin_spacing or not squeeze_punctuation:
		_runs = _strip_adjustments(_runs)
	var available := size.x
	if not autowrap:
		available = 0.0
	_lines = _layout.layout(_runs, available, _fonts, font_size, ruby_font_size,
			ruby_font, kinsoku, squeeze_punctuation,
			extra_line_start_forbidden, extra_line_end_forbidden)
	_content_height = 0.0
	for i in _lines.size():
		if i > 0:
			_content_height += line_spacing
		_content_height += _lines[i].height
	update_minimum_size()
	queue_redraw()
	text_relaid_out.emit()


## Removes the typesetting adjustments when the corresponding option is off.
func _strip_adjustments(runs: Array[CJKRun]) -> Array[CJKRun]:
	var out: Array[CJKRun] = []
	for r in runs:
		var copy := r.clone_with_text(r.text)
		if not cjk_latin_spacing:
			copy.gap_before = 0.0
		if not squeeze_punctuation:
			copy.advance_reduction = 0.0
		out.append(copy)
	return out


func _draw() -> void:
	var ts := TextServerManager.get_primary_interface()
	var canvas := get_canvas_item()
	var y := 0.0
	for line in _lines:
		var baseline := y + line.ascent + line.ruby_height
		var origin_x := 0.0
		if alignment == HORIZONTAL_ALIGNMENT_CENTER:
			origin_x = (size.x - line.width) * 0.5
		elif alignment == HORIZONTAL_ALIGNMENT_RIGHT:
			origin_x = size.x - line.width
		for s in line.segments:
			var run: CJKRun = _runs[s.run_index]
			var color := run.color if run.has_color else default_color
			ts.shaped_text_draw(s.text_line.get_rid(), canvas,
					Vector2(origin_x + s.x, baseline), -1.0, -1.0, color, -1.0)
			if s.underline:
				var thickness := maxf(s.underline_thickness, 1.0)
				draw_line(Vector2(origin_x + s.x, baseline + s.underline_position),
						Vector2(origin_x + s.x + s.width, baseline + s.underline_position),
						color, thickness)
		for mark in line.rubies:
			var ruby_rid := mark.text_line.get_rid()
			var ruby_width := ts.shaped_text_get_size(ruby_rid).x
			# The reading sits in the headroom reserved above the baseline,
			# so it rests on top of the base glyphs rather than on top of them.
			var ruby_baseline := baseline - line.ascent - ruby_spacing
			ts.shaped_text_draw(ruby_rid, canvas,
					Vector2(origin_x + mark.x + (mark.width - ruby_width) * 0.5, ruby_baseline),
					-1.0, -1.0, default_color, -1.0)
		y += line.height + line_spacing
