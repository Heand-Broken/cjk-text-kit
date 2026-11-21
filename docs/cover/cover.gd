extends Control

## Generates the itch.io cover image (630 x 250).
##
## Run with:
##   godot --path . --resolution 630x250 -- --cover

const ACCENT := Color("#8ab4f8")
const MUTED := Color("#8b93a7")
const TEXT := Color("#e8eaed")
const PANEL := Color("#151922")

var _font: Font
var _viewport: SubViewport
var _root: Control


func _ready() -> void:
	_font = CJKFonts.create_system_font()
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(630, 250)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)
	_root = Control.new()
	_root.size = Vector2(630, 250)
	_viewport.add_child(_root)
	_build()
	if "--cover" in OS.get_cmdline_user_args():
		_capture.call_deferred()


func _build() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color("#0e1016")
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(backdrop)

	# Accent bar on the left edge.
	var bar := ColorRect.new()
	bar.color = ACCENT
	bar.position = Vector2(0, 0)
	bar.size = Vector2(6, 250)
	_root.add_child(bar)

	var title := Label.new()
	title.text = "CJK Text Kit"
	title.add_theme_font_override("font", _font)
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", TEXT)
	title.position = Vector2(36, 40)
	_root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "for Godot 4  ·  CJK typography"
	subtitle.add_theme_font_override("font", _font)
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", MUTED)
	subtitle.position = Vector2(38, 96)
	_root.add_child(subtitle)

	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 6)
	chips.position = Vector2(36, 132)
	_root.add_child(chips)
	for label_text in ["Furigana", "CJK↔Latin", "Squeeze"]:
		chips.add_child(_chip(label_text))

	var note := Label.new()
	note.text = "Ruby · CJK/Latin spacing · squeezed punctuation"
	note.add_theme_font_override("font", _font)
	note.add_theme_font_size_override("font_size", 12)
	note.add_theme_color_override("font_color", Color("#6f7787"))
	note.position = Vector2(38, 176)
	_root.add_child(note)

	# Live sample on the right, rendered by the addon itself.
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.set_corner_radius_all(8)
	style.set_border_width_all(1)
	style.border_color = Color("#232836")
	panel.add_theme_stylebox_override("panel", style)
	panel.position = Vector2(334, 28)
	panel.size = Vector2(268, 194)
	_root.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 14)
	panel.add_child(margin)

	var sample := CJKText.new()
	sample.font = _font
	sample.ruby_font = _font
	sample.font_size = 20
	sample.ruby_font_size = 9
	sample.default_color = Color("#d7dbe3")
	sample.text = "[ruby=きょう]今日[/ruby]は\n[color=#8ab4f8]Godot 4.7[/color]の" \
		+ "[ruby=てんき]天気[/ruby]です。\n"
	sample.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sample.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(sample)


func _chip(label_text: String) -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#1b2230")
	style.set_corner_radius_all(10)
	style.set_border_width_all(1)
	style.border_color = Color("#2c3648")
	style.content_margin_left = 9.0
	style.content_margin_right = 9.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = label_text
	label.add_theme_font_override("font", _font)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color("#a8c4f0"))
	panel.add_child(label)
	return panel


func _capture() -> void:
	for i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := _viewport.get_texture().get_image()
	var target := "res://docs/screenshots/cover.png"
	DirAccess.make_dir_recursive_absolute("res://docs/screenshots")
	if image.save_png(target) == OK:
		print("cover saved to ", target)
	else:
		print("cover failed")
	get_tree().quit()
