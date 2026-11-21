class_name CJKFonts
extends RefCounted

## Helpers for picking a font that covers Chinese, Japanese and Korean.
##
## Distributing a CJK font inside the plugin would add tens of megabytes to
## every download, and CJK fonts often carry distribution restrictions.
## The recommended approach is to reference a font that already exists on
## the player's system, which is what these helpers do.

## Font families tried in order. The first family that provides the needed
## glyphs wins, and the operating system fallback covers the rest.
const FAMILIES := [
	"Microsoft YaHei UI",
	"Microsoft YaHei",
	"PingFang SC",
	"Hiragino Sans",
	"Yu Gothic UI",
	"Yu Gothic",
	"Meiryo",
	"MS Gothic",
	"Malgun Gothic",
	"Noto Sans CJK SC",
	"Noto Sans JP",
	"Source Han Sans SC",
	"Source Han Sans",
	"SimHei",
	"SimSun",
	"WenQuanYi Micro Hei",
]


## Creates a [SystemFont] that resolves to an installed CJK family.
##
## The returned font never embeds any file, so it costs nothing in build
## size. On systems without a CJK family the operating system fallback is
## still enabled, which covers most desktop distributions.
static func create_system_font(extra_families: PackedStringArray = PackedStringArray()) -> SystemFont:
	var sf := SystemFont.new()
	var names := PackedStringArray()
	for f in extra_families:
		names.append(f)
	for f in FAMILIES:
		names.append(f)
	sf.font_names = names
	sf.allow_system_fallback = true
	sf.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	sf.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	return sf


## Returns the names of the CJK families that are actually installed.
##
## Useful to warn users whose system has no CJK font at all.
static func detect_installed() -> PackedStringArray:
	var found := PackedStringArray()
	for family in FAMILIES:
		var sf := SystemFont.new()
		sf.font_names = PackedStringArray([family])
		sf.allow_system_fallback = false
		if sf.has_char(0x6F22):  # 漢
			found.append(family)
	return found


## True when the system provides a font able to render Han characters.
static func has_cjk_support() -> bool:
	return not detect_installed().is_empty()
