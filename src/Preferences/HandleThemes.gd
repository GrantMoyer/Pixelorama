extends Node

var theme_index := 0

onready var themes := [
	preload("res://assets/themes/dark/theme.tres"),
	preload("res://assets/themes/gray/theme.tres"),
	preload("res://assets/themes/blue/theme.tres"),
	preload("res://assets/themes/caramel/theme.tres"),
	preload("res://assets/themes/light/theme.tres"),
	preload("res://assets/themes/purple/theme.tres"),
]

onready var buttons_container: BoxContainer = $ThemeButtons
onready var colors_container: BoxContainer = $ThemeColorsSpacer/ThemeColors
onready var theme_color_preview_scene = preload("res://src/Preferences/ThemeColorPreview.tscn")


func _ready() -> void:
	var button_group = ButtonGroup.new()
	for theme in themes:
		var button := CheckBox.new()
		var theme_name: String = theme.resource_name
		button.name = theme_name
		button.text = theme_name
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.group = button_group
		buttons_container.add_child(button)
		button.connect("pressed", self, "_on_Theme_pressed", [button.get_index()])

		var panel_stylebox: StyleBox = theme.get_stylebox("panel", "Panel")
		var panel_container_stylebox: StyleBox = theme.get_stylebox("panel", "PanelContainer")
		if panel_stylebox is StyleBoxFlat and panel_container_stylebox is StyleBoxFlat:
			var theme_color_preview: ColorRect = theme_color_preview_scene.instance()
			var color1 = panel_stylebox.bg_color
			var color2 = panel_container_stylebox.bg_color
			theme_color_preview.get_child(0).color = color1
			theme_color_preview.get_child(1).color = color2
			colors_container.add_child(theme_color_preview)

	if Global.config_cache.has_section_key("preferences", "theme"):
		var theme_id = Global.config_cache.get_value("preferences", "theme")
		if theme_id >= themes.size():
			theme_id = 0
		change_theme(theme_id)
		buttons_container.get_child(theme_id).pressed = true
	else:
		change_theme(0)
		buttons_container.get_child(0).pressed = true


func _on_Theme_pressed(index: int) -> void:
	buttons_container.get_child(index).pressed = true
	change_theme(index)

	# Make sure the frame text gets updated
	Global.current_project.current_frame = Global.current_project.current_frame

	Global.config_cache.set_value("preferences", "theme", index)
	Global.config_cache.save("user://cache.ini")


func change_theme(id: int) -> void:
	theme_index = id
	var theme: Theme = themes[id]
	var icon_color: Color = theme.get_color("modulate_color", "Icons")

	if Global.icon_color_from == Global.IconColorFrom.THEME:
		Global.modulate_icon_color = icon_color

	Global.control.theme = theme

	var panel_stylebox: StyleBox = theme.get_stylebox("panel", "PanelContainer")
	if panel_stylebox is StyleBoxFlat:
		Global.default_clear_color = panel_stylebox.bg_color
	else:
		Global.default_clear_color = icon_color
	VisualServer.set_default_clear_color(Global.default_clear_color)

	# Temporary code
	var layer_button_pcont: PanelContainer = Global.animation_timeline.find_node(
		"LayerButtonPanelContainer"
	)
	var lbpc_stylebox: StyleBoxFlat = layer_button_pcont.get_stylebox("panel", "PanelContainer")
	lbpc_stylebox.bg_color = Global.default_clear_color

	var top_menu_style = theme.get_stylebox("TopMenu", "Panel")
	var ruler_style = theme.get_stylebox("Ruler", "Button")
	Global.top_menu_container.add_stylebox_override("panel", top_menu_style)
	Global.horizontal_ruler.add_stylebox_override("normal", ruler_style)
	Global.horizontal_ruler.add_stylebox_override("pressed", ruler_style)
	Global.horizontal_ruler.add_stylebox_override("hover", ruler_style)
	Global.horizontal_ruler.add_stylebox_override("focus", ruler_style)
	Global.vertical_ruler.add_stylebox_override("normal", ruler_style)
	Global.vertical_ruler.add_stylebox_override("pressed", ruler_style)
	Global.vertical_ruler.add_stylebox_override("hover", ruler_style)
	Global.vertical_ruler.add_stylebox_override("focus", ruler_style)

	change_icon_colors()

	Global.preferences_dialog.get_node("Popups/ShortcutSelector").theme = theme

	# Sets disabled theme color on palette swatches
	Global.palette_panel.reset_empty_palette_swatches_color()


func change_icon_colors() -> void:
	for node in get_tree().get_nodes_in_group("UIButtons"):
		if node is TextureButton:
			node.modulate = Global.modulate_icon_color
			if node.disabled and not ("RestoreDefaultButton" in node.name):
				node.modulate.a = 0.5
		elif node is Button:
			var texture: TextureRect
			for child in node.get_children():
				if child is TextureRect and child.name != "Background":
					texture = child
					break

			if texture:
				texture.modulate = Global.modulate_icon_color
				if node.disabled:
					texture.modulate.a = 0.5
		elif node is TextureRect or node is Sprite:
			node.modulate = Global.modulate_icon_color
