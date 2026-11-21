class_name CJKLayout
extends RefCounted

## Typesetting engine for CJK text.
##
## The engine measures every run independently, inserts the quarter-em gap
## between CJK and Latin text, squeezes adjacent punctuation, breaks lines
## while honouring kinsoku rules and reserves vertical space for ruby
## annotations.
##
## Line breaking is implemented here rather than delegated to
## [TextParagraph] because ICU's default rules cannot express the
## "squeeze punctuation" or "reserve ruby headroom" requirements, and
## because the annotation needs to know exactly which glyph belongs to
## which line.

## A contiguous piece of a run that ends up on one line.
class Segment extends RefCounted:
	## Index of the source run inside the run array.
	var run_index: int = 0
	## First character of the segment inside the run.
	var source_start: int = 0
	## Number of characters in the segment.
	var source_length: int = 0
	## Horizontal offset of the segment inside its line.
	var x: float = 0.0
	## Width of the segment.
	var width: float = 0.0
	## Shaped text used to draw the segment.
	##
	## The [TextLine] is kept alive by this reference: its shaped text RID
	## is only valid while the line exists.
	var text_line: TextLine = null
	## Ascent of the segment.
	var ascent: float = 0.0
	## Descent of the segment.
	var descent: float = 0.0
	## Underline offset measured from the baseline.
	var underline_position: float = 0.0
	## Underline thickness.
	var underline_thickness: float = 0.0
	## Whether the segment should draw an underline.
	var underline: bool = false
	## Horizontal squeeze applied to the segment, in pixels.
	var squeeze: float = 0.0
	## The literal characters covered by this segment.
	var ch_text: String = ""
	## Font size used to measure this segment.
	var font_size: int = 16


## A ruby annotation anchored to a segment.
class RubyMark extends RefCounted:
	## Horizontal offset of the annotated base inside its line.
	var x: float = 0.0
	## Width of the annotated base.
	var width: float = 0.0
	## The reading text.
	var text: String = ""
	## Shaped text used to draw the reading.
	##
	## The [TextLine] is kept alive by this reference.
	var text_line: TextLine = null
	## Ascent of the reading, used to place it above the baseline.
	var ascent: float = 0.0


## A laid out line of text.
class Line extends RefCounted:
	## Segments belonging to this line, ordered left to right.
	var segments: Array[Segment] = []
	## Ruby annotations belonging to this line.
	var rubies: Array[RubyMark] = []
	## Width of the line.
	var width: float = 0.0
	## Distance from the top of the line to the baseline.
	var ascent: float = 0.0
	## Distance from the baseline to the bottom of the line.
	var descent: float = 0.0
	## Extra vertical space reserved above the baseline for ruby readings.
	var ruby_height: float = 0.0
	## Total height of the line.
	var height: float = 0.0


## A grapheme discovered while measuring a run.
class Grapheme extends RefCounted:
	var start: int = 0
	var end: int = 0
	var x0: float = 0.0
	var x1: float = 0.0
	var ch: String = ""


var _ts := TextServerManager.get_primary_interface()


## Lays out [param runs] into lines no wider than [param width].
##
## [param fonts] maps "normal", "bold", "italic" and "bold_italic" to
## [Font] resources. [param base_size] is the fallback font size, and
## [param ruby_size] the size used for phonetic readings.
##
## A [param width] of zero or less disables wrapping and produces a single
## line. [param ruby_font] overrides the font used for ruby readings; when
## it is null the reading inherits the style of its base text.
func layout(runs: Array[CJKRun], width: float, fonts: Dictionary,
		base_size: int, ruby_size: int, ruby_font: Font = null,
		kinsoku_enabled: bool = true, squeeze_enabled: bool = true,
		line_start_forbidden: String = "", line_end_forbidden: String = "") -> Array[Line]:
	var lines: Array[Line] = []
	if runs.is_empty():
		return lines

	var measured := _measure_runs(runs, fonts, base_size)
	var sequence := _build_sequence(runs, measured, base_size)
	if sequence.is_empty():
		return lines

	var line_start := 0
	while line_start < sequence.size():
		var line_end := _find_break(sequence, line_start, width, kinsoku_enabled,
				line_start_forbidden, line_end_forbidden)
		lines.append(_make_line(runs, sequence, line_start, line_end, measured,
				fonts, ruby_size, ruby_font, width, squeeze_enabled))
		if line_end <= line_start:
			break
		line_start = line_end
	return lines


## Measures every run and returns per-run data.
func _measure_runs(runs: Array[CJKRun], fonts: Dictionary, base_size: int) -> Array:
	var out := []
	for r in runs:
		var font := _font_for(r, fonts)
		var size := r.font_size if r.font_size > 0 else base_size
		var tl := TextLine.new()
		if not r.text.is_empty():
			tl.add_string(r.text, font, size)
		out.append({
			"line": tl,
			"font": font,
			"size": size,
			"width": tl.get_line_width(),
			"ascent": tl.get_line_ascent(),
			"descent": tl.get_line_descent(),
			"underline_position": tl.get_line_underline_position(),
			"underline_thickness": tl.get_line_underline_thickness(),
			"graphemes": _graphemes(tl.get_rid(), r.text),
		})
	return out


## Splits a run into graphemes and measures the horizontal extent of each.
func _graphemes(rid: RID, text: String) -> Array:
	var out: Array[Grapheme] = []
	if text.is_empty():
		return out
	var breaks := _ts.shaped_text_get_character_breaks(rid)
	var previous := 0
	for g_end in breaks:
		var g := Grapheme.new()
		g.start = previous
		g.end = g_end
		g.ch = text.substr(previous, g_end - previous)
		var bounds := _ts.shaped_text_get_grapheme_bounds(rid, g_end)
		g.x0 = bounds.x
		g.x1 = bounds.y
		out.append(g)
		previous = g_end
	return out


## Flattens the measured runs into one global grapheme sequence.
##
## The sequence carries absolute horizontal positions so that line breaking
## can simply compare the last grapheme against the available width.
func _build_sequence(runs: Array[CJKRun], measured: Array, base_size: int) -> Array:
	var sequence: Array = []
	var cursor := 0.0
	for ri in runs.size():
		var r := runs[ri]
		var m: Dictionary = measured[ri]
		var size: int = m["size"]
		cursor += r.gap_before * float(size)
		var run_x0 := cursor
		var graphemes: Array = m["graphemes"]
		for gi in graphemes.size():
			var g: Grapheme = graphemes[gi]
			var x1 := run_x0 + g.x1
			if gi == graphemes.size() - 1:
				# The squeeze shortens the run, so the effective end of the
				# last grapheme moves left by the squeezed amount.
				x1 -= r.advance_reduction * float(size)
			var previous_char := ""
			if gi > 0:
				previous_char = String(graphemes[gi - 1].ch)
			elif ri > 0:
				previous_char = _last_char_of(runs, ri)
			sequence.append({
				"run_index": ri,
				"start": g.start,
				"end": g.end,
				"ch": g.ch,
				"x0": run_x0 + g.x0,
				"x1": x1,
				"breakable": CJKMetrics.can_break_between(previous_char, g.ch),
			})
		cursor = run_x0 + float(m["width"]) - r.advance_reduction * float(size)
	return sequence


## Returns the last character of the run at [param index].
func _last_char_of(runs: Array[CJKRun], index: int) -> String:
	if index <= 0 or index > runs.size():
		return ""
	var text: String = runs[index - 1].text
	if text.is_empty():
		return ""
	return text.substr(text.length() - 1, 1)


## Finds the index at which the line starting at [param start] must break.
##
## The returned index is exclusive. Kinsoku rules are applied afterwards:
## a character that may not start a line is pulled into the current line,
## and a character that may not end a line is pushed to the next one. The
## two rules cooperate, so the resulting line is always legal.
func _find_break(sequence: Array, start: int, width: float,
		kinsoku_enabled: bool = true, line_start_forbidden: String = "",
		line_end_forbidden: String = "") -> int:
	var limit := INF if width <= 0.0 else maxf(width, 1.0)
	var line_x0: float = sequence[start]["x0"]
	var end := start
	while end < sequence.size():
		var gx1: float = sequence[end]["x1"]
		if gx1 - line_x0 > limit:
			break
		end += 1
	if end >= sequence.size():
		return sequence.size()
	if end == start:
		end = start + 1

	# Never break inside a Latin word. If the word does not fit at all it is
	# broken anyway, because leaving the line empty is not an option.
	var guard_word := 0
	while end > start + 1 and not bool(sequence[end].get("breakable", true)):
		end -= 1
		guard_word += 1
		if guard_word > 4096:
			break

	if not kinsoku_enabled:
		return end
	var guard := 0
	while guard < 1024:
		guard += 1
		if end >= sequence.size():
			break
		# A forbidden character may not start the next line: pull it in.
		if CJKMetrics.is_forbidden_at_line_start(sequence[end]["ch"], line_start_forbidden):
			end += 1
			continue
		# A forbidden character may not end this line: push it down.
		if end > start + 1 and CJKMetrics.is_forbidden_at_line_end(
				sequence[end - 1]["ch"], line_end_forbidden):
			end -= 1
			continue
		break
	return end


## Builds the line that covers [param start] (inclusive) to [param end] (exclusive).
func _make_line(runs: Array[CJKRun], sequence: Array, start: int, end: int,
		measured: Array, fonts: Dictionary, ruby_size: int,
		ruby_font: Font, limit: float, squeeze_enabled: bool = true) -> Line:
	var line := Line.new()
	if end <= start:
		return line
	var line_x0: float = sequence[start]["x0"]

	var current_run := -1
	var segment: Segment = null
	for i in range(start, end):
		var entry: Dictionary = sequence[i]
		var ri: int = entry["run_index"]
		if ri != current_run:
			if segment != null:
				_finalise_segment(segment, runs[current_run], measured[current_run])
				line.segments.append(segment)
			segment = Segment.new()
			segment.run_index = ri
			segment.source_start = entry["start"]
			segment.source_length = entry["end"] - entry["start"]
			segment.x = float(entry["x0"]) - line_x0
			current_run = ri
		segment.source_length = entry["end"] - segment.source_start
		segment.width = float(entry["x1"]) - line_x0 - segment.x
		segment.ch_text += String(entry["ch"])
	if segment != null:
		_finalise_segment(segment, runs[current_run], measured[current_run])
		line.segments.append(segment)

	line.width = 0.0
	if not line.segments.is_empty():
		var last: Segment = line.segments[line.segments.size() - 1]
		line.width = last.x + last.width

	# Kinsoku may have pulled a character into a line that no longer fits.
	# Compressing a trailing full-width punctuation mark buys back the space
	# without changing the glyph shape.
	if squeeze_enabled and limit > 0.0 and limit < INF:
		while line.width - limit > 0.5 and not line.segments.is_empty():
			var tail: Segment = line.segments[line.segments.size() - 1]
			var run: CJKRun = runs[tail.run_index]
			var last_char := run.text.substr(
					tail.source_start + tail.source_length - 1, 1)
			if not CJKMetrics.is_fullwidth_punct(last_char):
				break
			if tail.squeeze > 0.0:
				break
			tail.squeeze = 0.5 * float(tail.font_size)
			tail.width = maxf(0.0, tail.width - tail.squeeze)
			line.width = tail.x + tail.width

	line.ascent = 0.0
	line.descent = 0.0
	for s in line.segments:
		line.ascent = maxf(line.ascent, s.ascent)
		line.descent = maxf(line.descent, s.descent)

	# Attach ruby annotations and reserve their vertical space.
	for s in line.segments:
		var run: CJKRun = runs[s.run_index]
		if not run.has_ruby():
			continue
		var mark := RubyMark.new()
		mark.x = s.x
		mark.width = s.width
		mark.text = run.ruby
		var reading_font := ruby_font
		if reading_font == null:
			reading_font = _font_for(run, fonts)
		var rtl := TextLine.new()
		rtl.add_string(run.ruby, reading_font, ruby_size)
		mark.text_line = rtl
		mark.ascent = rtl.get_line_ascent()
		line.rubies.append(mark)
		line.ruby_height = maxf(line.ruby_height, mark.ascent + 2.0)

	line.height = line.ascent + line.ruby_height + line.descent
	return line


## Fills in the drawing data of a segment.
func _finalise_segment(segment: Segment, run: CJKRun, m: Dictionary) -> void:
	segment.ascent = m["ascent"]
	segment.descent = m["descent"]
	segment.font_size = m["size"]
	segment.underline_position = m["underline_position"]
	segment.underline_thickness = m["underline_thickness"]
	segment.underline = run.underline
	if segment.source_start == 0 and segment.source_length == run.text.length():
		segment.text_line = m["line"]
		return
	# The run was split across lines: shape the fragment on its own.
	var tl := TextLine.new()
	tl.add_string(run.text.substr(segment.source_start, segment.source_length),
			m["font"], m["size"])
	segment.text_line = tl


## Picks the font matching the style flags of [param run].
func _font_for(run: CJKRun, fonts: Dictionary) -> Font:
	var key := "normal"
	if run.bold and run.italic:
		key = "bold_italic"
	elif run.bold:
		key = "bold"
	elif run.italic:
		key = "italic"
	var f: Font = fonts.get(key, null)
	if f == null:
		f = fonts.get("normal", null)
	if f == null:
		f = ThemeDB.fallback_font
	return f
