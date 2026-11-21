extends Control

## Demo scene for the CJK Text addon.
##
## The scene puts the addon side by side with the engine's own
## [RichTextLabel] so the difference is visible at a glance: the same
## source text, typeset by the addon on the left and by the engine on the
## right.

const SAMPLE := "「[ruby=きょう]今日[/ruby]は[color=#8ab4f8]Godot 4.7[/color]の" \
	+ "[ruby=てんき]天気[/ruby]が[color=#f28b82]悪い[/color]ね。」" \
	+ "彼は[font_size=22]ORA-1250[/font_size]の" \
	+ "[ruby=よほう]予想[/ruby]を[color=#81c995]確認[/color]した。" \
	+ "「……[ruby=まいにち]毎日[/ruby]、[ruby=にほん]日本[/ruby]語" \
	+ "の[ruby=もじ]文字[/ruby]を[ruby=よむ]読[/ruby]むのは" \
	+ "たいへんだ。」"

const SAMPLE_2 := "他说：「今天的会议改到明天上午十点，请大家准时参加。」" \
	+ "（不要迟到）……然后大家都散了。"

var _cjk: CJKText
var _cjk2: CJKText
var _native: RichTextLabel
var _native2: RichTextLabel
var _line_report: Label
var _font: Font


func _ready() -> void:
	_font = CJKFonts.create_system_font()
	_build_ui()
	_refresh()
	if "--screenshot" in OS.get_cmdline_user_args():
		_capture.call_deferred()


## Saves a screenshot of the demo and quits. Used to produce the store
## images without a manual screenshot pass.
func _capture() -> void:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var target := "res://docs/screenshots/demo.png"
	DirAccess.make_dir_recursive_absolute("res://docs/screenshots")
	if image.save_png(target) == OK:
		print("screenshot saved to ", target)
	else:
		print("screenshot failed")
	get_tree().quit()


func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("#0e1016")
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		root.add_theme_constant_override(side, 28)
	add_child(root)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	root.add_child(column)

	var title := Label.new()
	title.text = "CJK Text Kit  —  Godot 4 的 CJK 排版控件"
	title.add_theme_font_override("font", _font)
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("#e8eaed"))
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "左侧：CJKText    右侧：引擎原生 RichTextLabel（同一段源码）"
	subtitle.add_theme_font_override("font", _font)
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color("#8b93a7"))
	column.add_child(subtitle)

	var claim := Label.new()
	claim.text = "引擎未提供、左侧已实现的三项能力：① 振假名注音（右侧 [ruby] 标签被当作字面文本输出）" \
		+ "  ② 中西文之间 1/4 em 自动间距（实测 +8px @32px）  ③ 相邻全角标点半角挤压（实测 −16px @32px）"
	claim.add_theme_font_override("font", _font)
	claim.add_theme_font_size_override("font_size", 14)
	claim.add_theme_color_override("font_color", Color("#7fb069"))
	column.add_child(claim)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 24)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(columns)

	columns.add_child(_build_panel("CJKText", true))
	columns.add_child(_build_panel("RichTextLabel（引擎原生）", false))

	var options := HBoxContainer.new()
	options.add_theme_constant_override("separation", 22)
	column.add_child(options)
	options.add_child(_make_toggle("中西文间距", true, func(on): _cjk.cjk_latin_spacing = on))
	options.add_child(_make_toggle("标点挤压", true, func(on): _cjk.squeeze_punctuation = on))
	options.add_child(_make_toggle("避头尾禁则", true, func(on): _cjk.kinsoku = on))
	options.add_child(_make_toggle("注音", true, func(on): _cjk2.visible = on))

	_line_report = Label.new()
	_line_report.add_theme_font_override("font", _font)
	_line_report.add_theme_font_size_override("font_size", 14)
	_line_report.add_theme_color_override("font_color", Color("#6f7787"))
	column.add_child(_line_report)


func _build_panel(title_text: String, use_addon: bool) -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#151922")
	style.set_corner_radius_all(8)
	style.set_border_width_all(1)
	style.border_color = Color("#232836")
	panel.add_theme_stylebox_override("panel", style)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 18)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var heading := Label.new()
	heading.text = title_text
	heading.add_theme_font_override("font", _font)
	heading.add_theme_font_size_override("font_size", 16)
	heading.add_theme_color_override("font_color",
			Color("#8ab4f8") if use_addon else Color("#8b93a7"))
	box.add_child(heading)

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(body)

	if use_addon:
		_cjk = CJKText.new()
		_cjk.font = _font
		_cjk.ruby_font = _font
		_cjk.font_size = 27
		_cjk.ruby_font_size = 13
		_cjk.default_color = Color("#d7dbe3")
		_cjk.text = SAMPLE
		_cjk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_cjk.custom_minimum_size = Vector2(0, 250)
		body.add_child(_cjk)

		_cjk2 = CJKText.new()
		_cjk2.font = _font
		_cjk2.ruby_font = _font
		_cjk2.font_size = 27
		_cjk2.ruby_font_size = 13
		_cjk2.default_color = Color("#d7dbe3")
		_cjk2.text = SAMPLE_2
		_cjk2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_cjk2.custom_minimum_size = Vector2(0, 120)
		body.add_child(_cjk2)
	else:
		_native = RichTextLabel.new()
		_native.bbcode_enabled = true
		_native.fit_content = true
		_native.scroll_active = false
		_native.add_theme_font_override("normal_font", _font)
		_native.add_theme_font_size_override("normal_font_size", 27)
		_native.add_theme_color_override("default_color", Color("#d7dbe3"))
		_native.text = SAMPLE
		body.add_child(_native)

		_native2 = RichTextLabel.new()
		_native2.bbcode_enabled = true
		_native2.fit_content = true
		_native2.scroll_active = false
		_native2.add_theme_font_override("normal_font", _font)
		_native2.add_theme_font_size_override("normal_font_size", 27)
		_native2.add_theme_color_override("default_color", Color("#d7dbe3"))
		_native2.text = SAMPLE_2
		body.add_child(_native2)

	return panel


func _make_toggle(label_text: String, pressed: bool, on_change: Callable) -> Control:
	var check := CheckBox.new()
	check.text = label_text
	check.button_pressed = pressed
	check.add_theme_font_override("font", _font)
	check.add_theme_font_size_override("font_size", 15)
	check.add_theme_color_override("font_color", Color("#c3c9d6"))
	check.toggled.connect(on_change)
	return check


func _refresh() -> void:
	if _cjk == null:
		return
	await get_tree().process_frame
	await get_tree().process_frame
	var starts := ""
	for i in _cjk.get_line_count():
		var t := _cjk.get_line_text(i)
		if t.is_empty():
			continue
		starts += "「%s」" % t.substr(0, 1)
	_line_report.text = "每行首字符：%s    （禁则保证闭标点不会出现在行首；引擎的 ICU 断行同样具备此项，本插件可扩展禁则集）" % starts
