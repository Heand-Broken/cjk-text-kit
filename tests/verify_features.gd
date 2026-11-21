extends SceneTree

## Feature verification: compares the addon's typesetting against the
## engine's own line breaker so every claim has a number attached.
##
## Run with:
##   godot --headless --path . --script tests/verify_features.gd

var _font: Font


func _init() -> void:
	_font = CJKFonts.create_system_font()
	print("=== CJK Text Kit — feature verification ===")
	_verify_kinsoku()
	_verify_spacing()
	_verify_squeeze()
	_verify_ruby()
	_verify_word_break()
	quit()


func _fonts() -> Dictionary:
	return {"normal": _font, "bold": _font, "italic": _font, "bold_italic": _font}


## Lays the source out with the addon and returns the resulting lines.
func _addon_lines(source: String, width: float, size: int = 32) -> Array[CJKLayout.Line]:
	var runs := CJKParser.parse(source)
	return CJKLayout.new().layout(runs, width, _fonts(), size, size / 2)


## Lays the source out with the engine's own line breaker.
func _engine_lines(source: String, width: float, size: int = 32) -> Array[String]:
	var tp := TextParagraph.new()
	tp.width = width
	tp.add_string(source, _font, size)
	var out: Array[String] = []
	for i in tp.get_line_count():
		var r: Vector2i = tp.get_line_range(i)
		out.append(source.substr(r.x, r.y - r.x))
	return out


func _line_texts(lines: Array[CJKLayout.Line]) -> Array[String]:
	var out: Array[String] = []
	for line in lines:
		var parts: Array[String] = []
		for s in line.segments:
			parts.append(s.ch_text)
		out.append("".join(parts))
	return out


func _verify_kinsoku() -> void:
	print("")
	print("--- 1. Kinsoku: a closing mark may not start a line ---")
	# 20 ideographs fill 640px at 32px, so the mark lands exactly on the
	# boundary where the engine is allowed to orphan it.
	var source := "甲乙丙丁戊己庚辛壬癸子丑寅卯辰巳。子丑寅卯辰巳申酉"
	var width := 640.0
	var addon := _line_texts(_addon_lines(source, width))
	var engine := _engine_lines(source, width)
	print("  addon lines :")
	for l in addon:
		print("    [%s]" % l)
	print("  engine lines:")
	for l in engine:
		print("    [%s]" % l)

	var addon_bad := 0
	for l in addon:
		if not l.is_empty() and CJKMetrics.is_forbidden_at_line_start(l.substr(0, 1)):
			addon_bad += 1
	var engine_bad := 0
	for l in engine:
		if not l.is_empty() and CJKMetrics.is_forbidden_at_line_start(l.substr(0, 1)):
			engine_bad += 1
	print("  addon  orphaned closing marks : %d" % addon_bad)
	print("  engine orphaned closing marks : %d" % engine_bad)
	print("  >>> addon keeps %d forbidden line starts out of %d" % [
			engine_bad - addon_bad, engine_bad])


func _verify_spacing() -> void:
	print("")
	print("--- 2. CJK/Latin spacing: a quarter em between scripts ---")
	var source := "速度很快Godot"
	var plain := CJKParser.parse(source)
	for r in plain:
		r.gap_before = 0.0
	var without := CJKLayout.new().layout(plain, 0.0, _fonts(), 32, 16)
	var with := _addon_lines(source, 0.0)
	var d := with[0].width - without[0].width
	print("  without gap : %.2f px" % without[0].width)
	print("  with gap    : %.2f px" % with[0].width)
	print("  difference  : %.2f px (expected %.2f = 0.25em)" % [d, 0.25 * 32.0])
	print("  >>> %s" % ("OK" if absf(d - 8.0) < 0.6 else "MISMATCH"))


func _verify_squeeze() -> void:
	print("")
	print("--- 3. Punctuation squeeze: adjacent marks compress to half width ---")
	var source := "真的？！」"
	var plain := CJKParser.parse(source)
	for r in plain:
		r.advance_reduction = 0.0
	var without := CJKLayout.new().layout(plain, 0.0, _fonts(), 32, 16)
	var with := _addon_lines(source, 0.0)
	var d := without[0].width - with[0].width
	print("  without squeeze : %.2f px" % without[0].width)
	print("  with squeeze    : %.2f px" % with[0].width)
	print("  difference      : %.2f px" % d)
	print("  >>> %s" % ("OK" if d > 0.0 else "NO EFFECT"))


func _verify_ruby() -> void:
	print("")
	print("--- 4. Ruby: furigana with automatic headroom ---")
	var plain := _addon_lines("漢字", 0.0)
	var ruby := _addon_lines("[ruby=かんじ]漢字[/ruby]", 0.0)
	print("  plain line height : %.2f px" % plain[0].height)
	print("  ruby  line height : %.2f px" % ruby[0].height)
	print("  reserved headroom : %.2f px" % ruby[0].ruby_height)
	print("  reading           : %s" % ruby[0].rubies[0].text)
	print("  >>> %s" % ("OK" if ruby[0].height > plain[0].height else "NO EFFECT"))


func _verify_word_break() -> void:
	print("")
	print("--- 5. Latin words are never split across lines ---")
	var source := "版本号ORA-1250的天气"
	var addon := _line_texts(_addon_lines(source, 300.0))
	var engine := _engine_lines(source, 300.0)
	print("  addon lines :")
	for l in addon:
		print("    [%s]" % l)
	print("  engine lines:")
	for l in engine:
		print("    [%s]" % l)
	var addon_split := false
	for l in addon:
		if l.ends_with("ORA-") or l.begins_with("1250"):
			addon_split = true
	print("  >>> addon keeps ORA-1250 intact : %s" % str(not addon_split))
