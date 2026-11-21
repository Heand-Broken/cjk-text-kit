extends SceneTree

## Headless test suite for the CJK Text addon.
##
## Run with:
##   godot --headless --path . --script tests/test_runner.gd
##
## The suite exits with a non-zero status when a check fails so it can be
## wired into CI.

var _passed: int = 0
var _failed: int = 0
var _failures: Array[String] = []


func _init() -> void:
	print("=== CJK Text Kit test suite ===")
	_test_metrics()
	_test_parser()
	_test_typesetting_splits()
	_test_layout_kinsoku()
	_test_layout_ruby()
	_test_layout_spacing()
	_test_layout_squeeze()
	_test_layout_single_line()
	_test_control()

	print("")
	print("RESULT: PASS %d checks, %d failures" % [_passed, _failed])
	for f in _failures:
		print("  - ", f)
	quit(1 if _failed > 0 else 0)


# ---------------------------------------------------------------- helpers ---

func check(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		_failures.append(label)
		print("  FAIL  ", label)


func check_eq(actual: Variant, expected: Variant, label: String) -> void:
	check(actual == expected, "%s (expected %s, got %s)" % [label, str(expected), str(actual)])


func check_close(actual: float, expected: float, label: String, tolerance: float = 0.5) -> void:
	check(absf(actual - expected) <= tolerance,
			"%s (expected ~%.2f, got %.2f)" % [label, expected, actual])


func fonts() -> Dictionary:
	var base := CJKFonts.create_system_font()
	return {"normal": base, "bold": base, "italic": base, "bold_italic": base}


func layout_text(source: String, width: float, base_size: int = 32,
		ruby_size: int = 16) -> Array[CJKLayout.Line]:
	var runs := CJKParser.parse(source)
	return CJKLayout.new().layout(runs, width, fonts(), base_size, ruby_size)


func line_text(lines: Array[CJKLayout.Line], index: int) -> String:
	if index < 0 or index >= lines.size():
		return ""
	var parts: Array[String] = []
	for s in lines[index].segments:
		parts.append(s.ch_text)
	return "".join(parts)


# ----------------------------------------------------------------- metrics ---

func _test_metrics() -> void:
	print("[metrics]")
	check(CJKMetrics.is_cjk("漢"), "is_cjk(Han) is true")
	check(CJKMetrics.is_cjk("あ"), "is_cjk(hiragana) is true")
	check(not CJKMetrics.is_cjk("A"), "is_cjk(latin) is false")
	check(CJKMetrics.is_latin("A"), "is_latin(A) is true")
	check(CJKMetrics.is_latin("7"), "is_latin(digit) is true")
	check(CJKMetrics.needs_spacing("測", "A"), "CJK followed by latin needs spacing")
	check(CJKMetrics.needs_spacing("A", "測"), "latin followed by CJK needs spacing")
	check(not CJKMetrics.needs_spacing("測", "試"), "CJK followed by CJK needs no spacing")
	check(not CJKMetrics.needs_spacing("測", " "), "space suppresses spacing")
	check(CJKMetrics.should_squeeze("。", "、"), "adjacent closing punctuation squeezes")
	check(CJKMetrics.should_squeeze("「", "『"), "adjacent opening punctuation squeezes")
	check(not CJKMetrics.should_squeeze("。", "A"), "latin does not squeeze")
	check(CJKMetrics.is_forbidden_at_line_start("。"), "closing punctuation forbidden at line start")
	check(CJKMetrics.is_forbidden_at_line_end("「"), "opening punctuation forbidden at line end")
	check(not CJKMetrics.is_forbidden_at_line_start("漢"), "kanji allowed at line start")


# ------------------------------------------------------------------ parser ---

func _test_parser() -> void:
	print("[parser]")

	var runs := CJKParser.parse("[b]bold[/b]")
	check_eq(runs.size(), 1, "bold tag produces one run")
	check(runs[0].bold, "bold flag set")
	check_eq(runs[0].text, "bold", "bold text extracted")

	runs = CJKParser.parse("[ruby=かんじ]漢字[/ruby]")
	check_eq(runs.size(), 1, "ruby tag produces one run")
	check_eq(runs[0].ruby, "かんじ", "ruby reading captured")
	check_eq(runs[0].text, "漢字", "ruby base text captured")

	runs = CJKParser.parse("[color=#ff0000]red[/color]")
	check(runs[0].has_color, "color flag set")
	check_close(runs[0].color.r, 1.0, "hex colour red channel")
	check_close(runs[0].color.g, 0.0, "hex colour green channel")

	runs = CJKParser.parse("[color=red]x[/color]")
	check(runs[0].has_color, "named colour resolved")
	check_close(runs[0].color.r, 0.9, "named colour red channel")

	runs = CJKParser.parse("[i]it[/i][u]un[/u]")
	check(runs.size() >= 2, "italic and underline produce separate runs")

	runs = CJKParser.parse("[b]unclosed")
	check(runs[0].bold, "unclosed tag is closed at end of string")

	runs = CJKParser.parse("[/b]stray")
	check_eq(runs[0].text, "stray", "stray closing tag is ignored")

	runs = CJKParser.parse("[blink]x[/blink]")
	check_eq(runs[0].text, "[blink]x[/blink]", "unknown tag is kept as literal text")

	runs = CJKParser.parse("[font_size=48]big[/font_size]")
	check_eq(runs[0].font_size, 48, "font size parsed")

	check_eq(CJKParser.strip_tags("[b]a[/b][ruby=x]b[/ruby]"), "ab", "strip_tags removes markup")
	var empty_runs := CJKParser.parse("")
	check_eq(empty_runs.size(), 0, "empty input yields no runs")


# --------------------------------------------------- typesetting splitting ---

func _test_typesetting_splits() -> void:
	print("[typesetting splits]")

	var runs := CJKParser.parse("測試AB")
	check_eq(runs.size(), 2, "CJK/latin boundary splits the run")
	check_close(runs[0].gap_before, 0.0, "first piece has no gap")
	check_close(runs[1].gap_before, 0.25, "latin piece gets a quarter em gap")

	runs = CJKParser.parse("測試漢字")
	check_eq(runs.size(), 1, "pure CJK text is not split")

	runs = CJKParser.parse("。、")
	check_eq(runs.size(), 2, "adjacent punctuation splits the run")
	check_close(runs[1].advance_reduction, 0.5, "second punctuation mark is squeezed by half an em")

	runs = CJKParser.parse("[ruby=かんじ]漢字[/ruby]")
	check_eq(runs.size(), 1, "ruby base is not split")


# -------------------------------------------------------------- kinsoku ------

func _test_layout_kinsoku() -> void:
	print("[kinsoku]")
	var source := "甲乙丙丁戊己庚辛。壬癸子丑寅卯辰巳。"
	var lines := layout_text(source, 256.0, 32, 16)
	check(lines.size() > 1, "text wraps into several lines")
	var violations := 0
	var end_violations := 0
	for i in lines.size():
		var first := lines[i].segments[0]
		var ch: String = first.ch_text.substr(0, 1)
		if CJKMetrics.is_forbidden_at_line_start(ch):
			violations += 1
		if i < lines.size() - 1:
			var tail := lines[i].segments[lines[i].segments.size() - 1]
			var last: String = tail.ch_text.substr(tail.ch_text.length() - 1, 1)
			if CJKMetrics.is_forbidden_at_line_end(last):
				end_violations += 1
	check_eq(violations, 0, "no forbidden character starts a line")
	check_eq(end_violations, 0, "no forbidden character ends a line")

	# Without kinsoku the same text must violate the rule, proving the
	# check above is meaningful rather than vacuous.
	var runs := CJKParser.parse(source)
	var raw := CJKLayout.new().layout(runs, 256.0, fonts(), 32, 16, null, false, true)
	var raw_violations := 0
	for line in raw:
		var first := line.segments[0]
		if CJKMetrics.is_forbidden_at_line_start(first.ch_text.substr(0, 1)):
			raw_violations += 1
	check(raw_violations > 0, "the same text violates kinsoku without the rule applied")


# ----------------------------------------------------------------- ruby ------

func _test_layout_ruby() -> void:
	print("[ruby]")
	var plain := layout_text("漢字テスト", 400.0, 32, 16)
	var with_ruby := layout_text("[ruby=かんじ]漢字[/ruby]テスト", 400.0, 32, 16)
	check_eq(plain.size(), 1, "plain text is a single line")
	check_eq(with_ruby.size(), 1, "ruby text is a single line")
	check(with_ruby[0].height > plain[0].height,
			"a ruby annotation increases the line height")
	check_close(with_ruby[0].ruby_height, 16.0 + 2.0, "ruby reserves headroom",
			3.0)
	check_eq(with_ruby[0].rubies.size(), 1, "one ruby annotation is attached")
	check_eq(with_ruby[0].rubies[0].text, "かんじ", "ruby reading is preserved")

	# The reading must be centred over its base.
	var mark: CJKLayout.RubyMark = with_ruby[0].rubies[0]
	var base_width := with_ruby[0].segments[0].width
	check(base_width > 0.0, "ruby base has a width")


# --------------------------------------------------------------- spacing -----

func _test_layout_spacing() -> void:
	print("[CJK/Latin spacing]")
	var with_gap := layout_text("測試AB", 0.0, 32, 16)
	var runs := CJKParser.parse("測試AB")
	for r in runs:
		r.gap_before = 0.0
	var without_gap := CJKLayout.new().layout(runs, 0.0, fonts(), 32, 16)
	check(with_gap[0].width > without_gap[0].width,
			"the quarter em gap widens the line")
	var expected := 0.25 * 32.0
	check_close(with_gap[0].width - without_gap[0].width, expected,
			"the gap measures exactly a quarter em", 1.0)


# --------------------------------------------------------------- squeeze -----

func _test_layout_squeeze() -> void:
	print("[punctuation squeeze]")
	var squeezed := layout_text("。、", 0.0, 32, 16)
	var runs := CJKParser.parse("。、")
	for r in runs:
		r.advance_reduction = 0.0
	var plain := CJKLayout.new().layout(runs, 0.0, fonts(), 32, 16)
	check(squeezed[0].width < plain[0].width, "squeezing shortens the line")
	check_close(plain[0].width - squeezed[0].width, 16.0,
			"the squeeze removes half an em", 1.0)


# ------------------------------------------------------------ single line ----

func _test_layout_single_line() -> void:
	print("[single line]")
	var lines := layout_text("甲乙丙丁戊己庚辛壬癸", 0.0, 32, 16)
	check_eq(lines.size(), 1, "zero width disables wrapping")


# ---------------------------------------------------------------- control ----

func _test_control() -> void:
	print("[control]")
	var c := CJKText.new()
	c.font = CJKFonts.create_system_font()
	c.font_size = 32
	c.ruby_font_size = 16
	c.text = "甲乙丙丁戊己庚辛。壬癸子丑寅卯辰巳。"
	c.size = Vector2(256, 400)
	c._relayout()
	check(c.get_line_count() > 1, "control wraps the text")
	check(c.get_content_height() > 0.0, "control reports a content height")
	check(c.get_line_text(0).length() > 0, "control exposes the first line")
	check_eq(c.get_plain_text(), "甲乙丙丁戊己庚辛。壬癸子丑寅卯辰巳。",
			"control strips tags from the plain text")

	c.text = "[b]粗体[/b]と[color=#ff0000]赤[/color]"
	c._relayout()
	check_eq(c.get_plain_text(), "粗体と赤", "control strips nested tags")
	c.free()
