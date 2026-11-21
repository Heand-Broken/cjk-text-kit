extends SceneTree

func _init() -> void:
	for fam in ["Microsoft YaHei", "Microsoft YaHei UI", "Yu Gothic", "Meiryo", "SimHei", "MS Gothic"]:
		var sf := SystemFont.new()
		sf.font_names = PackedStringArray([fam])
		sf.allow_system_fallback = true
		print("  %-20s rids=%d has_char(漢)=%s has_char(あ)=%s has_char(한)=%s" % [
			fam, sf.get_rids().size(), str(sf.has_char(0x6F22)), str(sf.has_char(0x3042)),
			str(sf.has_char(0xD55C))])
	var combo := SystemFont.new()
	combo.font_names = PackedStringArray(["Microsoft YaHei", "Yu Gothic", "Meiryo"])
	combo.allow_system_fallback = true
	print("  combo rids=%d has_char(漢)=%s has_char(あ)=%s" % [
		combo.get_rids().size(), str(combo.has_char(0x6F22)), str(combo.has_char(0x3042))])
	print("  installed families: ", CJKFonts.detect_installed())
	quit()
