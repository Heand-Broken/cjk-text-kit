extends SceneTree

## Exhaustive scan comparing the addon against the engine's line breaker.
##
## For every sample text and every candidate width the scan records whether
## a forbidden character ends up at the start or the end of a line. The
## engine figures come from [TextParagraph], which is exactly what
## [RichTextLabel] uses internally.

const SAMPLE_TEXTS := [
	"甲乙丙丁戊己庚辛壬癸子丑寅卯辰巳。子丑寅卯辰巳申酉戌亥",
	"他说：「今天的会议改到明天上午十点，请大家准时参加。」于是大家都散了。",
	"（重要）这是[color]测试[/color]。真的？！」……好吧",
	"第一段落结束。第二段落开始；第三段落呢？第四段落！第五段落？第六段落。",
	"测试（括号）开始，然后是「引号」，接着是『嵌套』，最后是（结束）。",
	"ORA-1250 的固件在 Godot 4.7 上运行，VSCode 插件同步更新了。",
]

var _font: Font
var _addon_violations_start := 0
var _addon_violations_end := 0
var _engine_violations_start := 0
var _engine_violations_end := 0
var _cases := 0
var _engine_examples: Array[String] = []
var _addon_examples: Array[String] = []


func _init() -> void:
	_font = CJKFonts.create_system_font()
	print("=== Exhaustive kinsoku comparison ===")
	for text in SAMPLE_TEXTS:
		for width in range(80, 760, 4):
			_scan(text, float(width))
	print("  cases scanned              : %d" % _cases)
	print("  engine: forbidden line start: %d" % _engine_violations_start)
	print("  engine: forbidden line end  : %d" % _engine_violations_end)
	print("  addon : forbidden line start: %d" % _addon_violations_start)
	print("  addon : forbidden line end  : %d" % _addon_violations_end)
	print("")
	if _engine_examples.size() > 0:
		print("  engine examples (line end violations):")
		for e in _engine_examples.slice(0, 8):
			print("    ", e)
	if _addon_examples.size() > 0:
		print("  addon examples (line end violations):")
		for e in _addon_examples.slice(0, 8):
			print("    ", e)
	quit()


func _scan(text: String, width: float) -> void:
	_cases += 1
	var engine := _engine_lines(text, width)
	for l in engine:
		if l.is_empty():
			continue
		if CJKMetrics.is_forbidden_at_line_start(l.substr(0, 1)):
			_engine_violations_start += 1
		if CJKMetrics.is_forbidden_at_line_end(l.substr(l.length() - 1, 1)):
			_engine_violations_end += 1
			if _engine_examples.size() < 40:
				_engine_examples.append("w=%d  [%s]" % [int(width), l])
	var addon := _addon_lines(text, width)
	for l in addon:
		if l.is_empty():
			continue
		if CJKMetrics.is_forbidden_at_line_start(l.substr(0, 1)):
			_addon_violations_start += 1
		if CJKMetrics.is_forbidden_at_line_end(l.substr(l.length() - 1, 1)):
			_addon_violations_end += 1
			if _addon_examples.size() < 40:
				_addon_examples.append("w=%d  [%s]" % [int(width), l])


func _engine_lines(text: String, width: float) -> Array[String]:
	var tp := TextParagraph.new()
	tp.width = width
	tp.add_string(text, _font, 32)
	var out: Array[String] = []
	for i in tp.get_line_count():
		var r: Vector2i = tp.get_line_range(i)
		out.append(text.substr(r.x, r.y - r.x))
	return out


func _addon_lines(text: String, width: float) -> Array[String]:
	var runs := CJKParser.parse(text)
	var lines := CJKLayout.new().layout(runs, width,
			{"normal": _font, "bold": _font, "italic": _font, "bold_italic": _font},
			32, 16)
	var out: Array[String] = []
	for line in lines:
		var parts: Array[String] = []
		for s in line.segments:
			parts.append(s.ch_text)
		out.append("".join(parts))
	return out
