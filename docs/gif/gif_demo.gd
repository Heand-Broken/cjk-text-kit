extends Control

## Animation used for the itch.io demo GIF.
##
## Run with:
##   godot --path . --resolution 1280x720 --write-movie res://docs/gif/frame.png \
##         res://docs/gif/gif_demo.tscn
##
## The frames are then converted to a GIF by tools/frames_to_gif.py.

const EXAMPLES := [
	{
		"label": "Ruby / furigana",
		"text": "[ruby=きょう]今日[/ruby]は[color=#8ab4f8]Godot 4.7[/color]の[ruby=てんき]天気[/ruby]。" \
			+ "[ruby=まいにち]毎日[/ruby]、[ruby=にほん]日本[/ruby]語を[ruby=よむ]読[/ruby]む。",
	},
	{
		"label": "CJK / Latin spacing",
		"text": "ORA-1250 的固件在 Godot 4.7 上运行，VSCode 插件同步更新了，帧率稳定在 60 FPS。",
	},
	{
		"label": "Punctuation squeezing",
		"text": "「真的？！」他喊道：「不要动！」（别跑）……然后一切都结束了。",
	},
]

const HOLD := 1.1
const TYPE_STEP := 0.055

var _font: Font
var _cjk: CJKText
var _native: RichTextLabel
var _caption: Label
var _index := 0
var _typed := 0.0
var _hold := 0.0
var _source := ""
var _elapsed := 0.0
var _visible_total := 1
## Total length of the recording in seconds.
const DURATION := 13.5


func _ready() -> void:
	_font = CJKFonts.create_system_font()
	_build()
	_apply(0)


func _build() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("#0e1016")
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 44)
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 22)
	margin.add_child(column)

	var title := Label.new()
	title.text = "CJK Text Kit  for Godot 4"
	title.add_theme_font_override("font", _font)
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color("#e8eaed"))
	column.add_child(title)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 34)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(columns)

	columns.add_child(_panel("CJKText", true))
	columns.add_child(_panel("RichTextLabel  (engine)", false))

	_caption = Label.new()
	_caption.add_theme_font_override("font", _font)
	_caption.add_theme_font_size_override("font_size", 22)
	_caption.add_theme_color_override("font_color", Color("#8ab4f8"))
	column.add_child(_caption)


func _panel(heading_text: String, use_addon: bool) -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#151922")
	style.set_corner_radius_all(10)
	style.set_border_width_all(1)
	style.border_color = Color("#232836")
	panel.add_theme_stylebox_override("panel", style)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var inner := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		inner.add_theme_constant_override(side, 22)
	panel.add_child(inner)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	inner.add_child(box)

	var heading := Label.new()
	heading.text = heading_text
	heading.add_theme_font_override("font", _font)
	heading.add_theme_font_size_override("font_size", 20)
	heading.add_theme_color_override("font_color",
			Color("#8ab4f8") if use_addon else Color("#7a8296"))
	box.add_child(heading)

	if use_addon:
		_cjk = CJKText.new()
		_cjk.font = _font
		_cjk.ruby_font = _font
		_cjk.font_size = 34
		_cjk.ruby_font_size = 16
		_cjk.default_color = Color("#d7dbe3")
		_cjk.size_flags_vertical = Control.SIZE_EXPAND_FILL
		box.add_child(_cjk)
	else:
		_native = RichTextLabel.new()
		_native.bbcode_enabled = true
		_native.fit_content = true
		_native.scroll_active = false
		_native.add_theme_font_override("normal_font", _font)
		_native.add_theme_font_size_override("normal_font_size", 34)
		_native.add_theme_color_override("default_color", Color("#d7dbe3"))
		_native.size_flags_vertical = Control.SIZE_EXPAND_FILL
		box.add_child(_native)

	return panel


func _apply(index: int) -> void:
	var example: Dictionary = EXAMPLES[index]
	_source = String(example["text"])
	_visible_total = maxi(1, CJKParser.strip_tags(_source).length())
	_caption.text = String(example["label"])
	_typed = 0.0
	_hold = 0.0
	_cjk.text = ""
	_native.text = ""


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= DURATION:
		get_tree().quit()
		return
	if _source.is_empty():
		return
	if _typed < float(_visible_total):
		_typed += delta / TYPE_STEP
		var visible := mini(int(_typed), _visible_total)
		# Map the visible character count back onto the raw source so the
		# typing speed follows the text the viewer actually reads.
		var raw := mini(int(round(float(visible) / float(_visible_total)
				* float(_source.length()))), _source.length())
		var prefix := _source.substr(0, raw)
		_cjk.text = prefix
		# The engine side uses the same source string, so both panels show
		# exactly the same amount of text. Using visible_characters here
		# would count differently and drift out of sync.
		_native.text = prefix
		return
	_hold += delta
	if _hold >= HOLD:
		_hold = 0.0
		_index = (_index + 1) % EXAMPLES.size()
		_apply(_index)
