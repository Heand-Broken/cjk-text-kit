class_name CJKParser
extends RefCounted

## Parses a lightweight BBCode dialect into typeset-ready runs.
##
## Supported tags:
## [code][b][/b][/code] bold,
## [code][i][/i][/code] italic,
## [code][u][/u][/code] underline,
## [code][color=#ff8800][/color][/code] colour (hex or a named colour),
## [code][font_size=28][/font_size][/code] explicit pixel size,
## [code][ruby=かんじ]漢字[/ruby][/code] phonetic annotation
## (also accepts [code][rb=...][/rb][/code]).
##
## The parser is deliberately forgiving: unclosed tags are closed at the end
## of the string, stray closing tags are ignored, and unknown tags are kept
## as literal text instead of being swallowed. That matters for user
## generated content such as dialogue coming from a save file.
##
## Tags are scanned by hand rather than with a regular expression so that
## the closing form and the opening form can never drift apart.

const NAMED_COLORS := {
	"black": Color(0, 0, 0),
	"white": Color(1, 1, 1),
	"red": Color(0.9, 0.25, 0.25),
	"green": Color(0.35, 0.8, 0.4),
	"blue": Color(0.35, 0.55, 0.95),
	"yellow": Color(0.95, 0.85, 0.3),
	"orange": Color(0.95, 0.6, 0.2),
	"purple": Color(0.7, 0.45, 0.9),
	"magenta": Color(0.9, 0.35, 0.85),
	"cyan": Color(0.3, 0.8, 0.85),
	"gray": Color(0.5, 0.5, 0.5),
	"grey": Color(0.5, 0.5, 0.5),
	"pink": Color(0.95, 0.65, 0.75),
	"brown": Color(0.55, 0.4, 0.25),
	"lime": Color(0.6, 0.85, 0.3),
	"navy": Color(0.2, 0.3, 0.6),
	"teal": Color(0.2, 0.6, 0.6),
	"silver": Color(0.75, 0.75, 0.78),
	"maroon": Color(0.5, 0.2, 0.2),
}

## Tags that only change styling.
const STYLE_TAGS := ["b", "i", "u", "color", "font_size"]

## Tags that carry a phonetic annotation.
const RUBY_TAGS := ["ruby", "rb"]


## Parses [param source] and returns the resulting runs.
##
## The returned runs already carry typesetting adjustments (the quarter-em
## CJK/Latin gap and the punctuation squeeze), so the layout engine can
## measure them directly.
static func parse(source: String) -> Array[CJKRun]:
	var style_runs := _parse_style_runs(source)
	var out: Array[CJKRun] = []
	for r in style_runs:
		out.append_array(_split_for_typesetting(r))
	return out


## Strips every recognised tag, leaving the plain text behind.
##
## Useful for previews, character counters and accessibility labels.
static func strip_tags(source: String) -> String:
	var out := ""
	var i := 0
	while i < source.length():
		if source[i] == "[":
			var tag := _scan_tag(source, i)
			if not tag.is_empty():
				i += int(tag["length"])
				continue
		out += source[i]
		i += 1
	return out


## Scans a tag starting at [param i].
##
## Returns an empty dictionary when the text at [param i] is not a tag.
## The result holds "name", "value", "closing" and "length".
static func _scan_tag(source: String, i: int) -> Dictionary:
	if i >= source.length() or source[i] != "[":
		return {}
	var j := i + 1
	var closing := false
	if j < source.length() and source[j] == "/":
		closing = true
		j += 1
	var name_start := j
	while j < source.length() and _is_tag_char(source[j]):
		j += 1
	if j == name_start:
		return {}
	var name := source.substr(name_start, j - name_start).to_lower()
	var value := ""
	if j < source.length() and source[j] == "=":
		j += 1
		var value_start := j
		while j < source.length() and source[j] != "]":
			j += 1
		value = source.substr(value_start, j - value_start)
	if j < source.length() and source[j] == "]":
		return {
			"name": name,
			"value": value,
			"closing": closing,
			"length": j - i + 1,
		}
	return {}


## True when [param c] may appear inside a tag name.
static func _is_tag_char(c: String) -> bool:
	if c == "_":
		return true
	return (c >= "a" and c <= "z") or (c >= "A" and c <= "Z")


## Parses the source into style runs without applying typesetting splits.
static func _parse_style_runs(source: String) -> Array[CJKRun]:
	var runs: Array[CJKRun] = []
	var stack: Array[Dictionary] = []
	var buffer := ""
	var ruby_buffer := ""
	var in_ruby := false
	var i := 0

	while i < source.length():
		if source[i] == "[":
			var tag := _scan_tag(source, i)
			if not tag.is_empty():
				var name: String = tag["name"]
				var value: String = tag["value"]
				var closing: bool = tag["closing"]
				if in_ruby and not (closing and RUBY_TAGS.has(name)):
					# Inside a ruby base every other tag is literal text.
					ruby_buffer += source.substr(i, int(tag["length"]))
					i += int(tag["length"])
					continue
				var consumed := _handle_tag(name, closing)
				if consumed == "ruby_open":
					_flush(runs, buffer, stack)
					buffer = ""
					in_ruby = true
					stack.append({"kind": name, "value": value})
				elif consumed == "ruby_close":
					var reading := ""
					for s in stack:
						if RUBY_TAGS.has(String(s.get("kind", ""))):
							reading = String(s.get("value", ""))
							break
					_flush(runs, ruby_buffer, stack, reading)
					ruby_buffer = ""
					in_ruby = false
					_pop_to(stack, name)
				elif consumed == "open":
					_flush(runs, buffer, stack)
					buffer = ""
					stack.append({"kind": name, "value": value})
				elif consumed == "close":
					_flush(runs, buffer, stack)
					buffer = ""
					_pop_to(stack, name)
				else:
					# Unknown tag: keep it as literal text.
					buffer += source.substr(i, int(tag["length"]))
				i += int(tag["length"])
				continue
		if in_ruby:
			ruby_buffer += source[i]
		else:
			buffer += source[i]
		i += 1

	_flush(runs, buffer, stack)
	if in_ruby:
		# Unterminated ruby: keep the base text with its reading.
		var reading := ""
		for s in stack:
			if RUBY_TAGS.has(String(s.get("kind", ""))):
				reading = String(s.get("value", ""))
				break
		_flush(runs, ruby_buffer, stack, reading)
	return runs


## Handles a single tag and reports what the caller should do.
##
## Returns one of "open", "close", "ruby_open", "ruby_close" or "literal".
static func _handle_tag(name: String, closing: bool) -> String:
	if STYLE_TAGS.has(name):
		return "close" if closing else "open"
	if RUBY_TAGS.has(name):
		return "ruby_close" if closing else "ruby_open"
	return "literal"


## Pops the stack up to and including the matching opening tag.
static func _pop_to(stack: Array[Dictionary], name: String) -> void:
	for i in range(stack.size() - 1, -1, -1):
		if String(stack[i].get("kind", "")) == name:
			stack.resize(i)
			return
	# No matching opener: ignore the stray closing tag.


## Emits the accumulated buffer as a run carrying the current style.
static func _flush(runs: Array[CJKRun], buffer: String, stack: Array[Dictionary],
		ruby: String = "") -> void:
	if buffer.is_empty() and ruby.is_empty():
		return
	var run := CJKRun.new(buffer)
	run.ruby = ruby
	for s in stack:
		match String(s.get("kind", "")):
			"b":
				run.bold = true
			"i":
				run.italic = true
			"u":
				run.underline = true
			"color":
				var c := parse_color(String(s.get("value", "")))
				if c != null:
					run.has_color = true
					run.color = c
			"font_size":
				run.font_size = maxi(1, int(String(s.get("value", "0")).to_int()))
	runs.append(run)


## Parses a colour literal. Returns [code]null[/code] when invalid.
static func parse_color(value: String) -> Variant:
	var v := value.strip_edges()
	if v.is_empty():
		return null
	if NAMED_COLORS.has(v.to_lower()):
		return NAMED_COLORS[v.to_lower()]
	if v.begins_with("#"):
		var hex := v.substr(1)
		if hex.length() == 3:
			var r := hex.substr(0, 1).repeat(2)
			var g := hex.substr(1, 1).repeat(2)
			var b := hex.substr(2, 1).repeat(2)
			return Color(r + g + b)
		if hex.length() == 6 or hex.length() == 8:
			return Color(hex)
		return null
	# Color("name") style.
	if v.begins_with("Color(") or v.begins_with("color("):
		if v.length() > 7:
			var inner := v.substr(6, v.length() - 7)
			if NAMED_COLORS.has(inner.to_lower()):
				return NAMED_COLORS[inner.to_lower()]
	return null


## Splits a style run at typesetting boundaries.
##
## A run is split where a quarter-em gap is required between CJK and Latin
## text, or where punctuation is squeezed to half width because it directly
## follows another punctuation mark of the same class.
static func _split_for_typesetting(run: CJKRun) -> Array[CJKRun]:
	var out: Array[CJKRun] = []
	var chars := run.text
	if chars.is_empty():
		return out
	if run.has_ruby():
		# Ruby bases stay in one piece so the annotation can be centred over
		# the whole base text.
		out.append(run)
		return out

	var start := 0
	var gap := 0.0
	var reduction := 0.0
	for i in range(1, chars.length()):
		var prev := chars.substr(i - 1, 1)
		var nxt := chars.substr(i, 1)
		var new_gap := 0.0
		var new_reduction := 0.0
		if CJKMetrics.needs_spacing(prev, nxt):
			new_gap = 0.25
		elif CJKMetrics.should_squeeze(prev, nxt):
			new_reduction = 0.5
		if new_gap > 0.0 or new_reduction > 0.0:
			var piece := run.clone_with_text(chars.substr(start, i - start))
			piece.gap_before = gap
			piece.advance_reduction = reduction
			out.append(piece)
			start = i
			gap = new_gap
			reduction = new_reduction
	var last := run.clone_with_text(chars.substr(start))
	last.gap_before = gap
	last.advance_reduction = reduction
	out.append(last)
	return out
