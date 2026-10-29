extends SceneTree

"""
Ghi lại `default_theme.tres` từ UITheme.make_theme().

Chạy: godot --headless --path . --script res://Scripts/Editor/BuildTheme.gd
"""

const UIThemeScript = preload("res://UI/UITheme.gd")

func _init():
	var err := ResourceSaver.save(UIThemeScript.make_theme(), "res://default_theme.tres")
	if err != OK:
		printerr("Không thể ghi default_theme.tres (lỗi %d)" % err)
	else:
		print("Đã ghi default_theme.tres")
	quit(err)
