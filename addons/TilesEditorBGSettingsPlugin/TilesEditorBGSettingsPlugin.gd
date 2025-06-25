@tool
extends EditorPlugin

var editor_interface: EditorInterface

var tile_map_editor: Control = null
var tile_map_background_left: Control
var tile_map_background_right: Control
var tile_map_dropdown: OptionButton
var tile_map_bg_left: Control
var tile_map_base_left: Control
var tile_map_left_bg_tex: TextureRect
var tile_map_bg_right: Control
var tile_map_base_right: Control
var tile_map_right_bg_tex: TextureRect
var tile_map_color_picker: ColorPickerButton
var tile_map_bg_color: Color = Color(1.0, 1.0, 1.0, 1.0)

var tile_set_editor: Control = null
var tile_set_background_left: Control
var tile_set_background_right: Control
var tile_set_dropdown: OptionButton
var tile_set_bg_left: Control
var tile_set_base_left: Control
var tile_set_left_bg_tex: TextureRect
var tile_set_bg_right: Control
var tile_set_base_right: Control
var tile_set_right_bg_tex: TextureRect
var tile_set_color_picker: ColorPickerButton
var tile_set_bg_color: Color = Color(1.0, 1.0, 1.0, 1.0)

var color_button_tex: Texture = preload("res://addons/TilesEditorBGSettingsPlugin/ColorPickerButton.svg")

var default_checker: Texture = preload("res://addons/TilesEditorBGSettingsPlugin/Checkerboard.svg")
var dark_checker: Texture = preload("res://addons/TilesEditorBGSettingsPlugin/CheckerboardDark.svg")
var blank_checker: Texture = preload("res://addons/TilesEditorBGSettingsPlugin/Blank.svg")

func _enter_tree() -> void:
	editor_interface = get_editor_interface()
	
	setup_tileset()
	setup_tilemap()
	
	tile_set_change_checks(0)

func setup_tilemap():
	var base = editor_interface.get_base_control()
	tile_map_editor = find_tilemap_editor(find_tile_map_base_editor(base))
	
	if tile_map_editor:
		print(tile_map_editor.name)
		var panel: Panel = tile_map_editor.get_child(0)
		var center_container: CenterContainer = panel.get_child(0)
		var margin_contailer: MarginContainer = center_container.get_child(1)
		var hbox: HBoxContainer = margin_contailer.get_child(0)
		var leftbox: VBoxContainer = hbox.get_child(0)
		var base_left: Control = hbox.get_child(0)
		var base_right: Control = hbox.get_child(1)
		
		tile_map_base_left = base_left.get_child(1)
		tile_map_base_right = base_right.get_child(1)
		tile_map_bg_left = tile_map_base_left.get_child(0)
		tile_map_bg_right = tile_map_base_right.get_child(0)
		
		tile_map_left_bg_tex = TextureRect.new()
		tile_map_left_bg_tex.texture = default_checker
		tile_map_left_bg_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile_map_left_bg_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tile_map_left_bg_tex.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		tile_map_left_bg_tex.stretch_mode = TextureRect.STRETCH_TILE
		tile_map_base_left.add_child(tile_map_left_bg_tex)
		tile_map_left_bg_tex.show_behind_parent = true
		tile_map_bg_left.visible = false
		
		tile_map_right_bg_tex = TextureRect.new()
		tile_map_right_bg_tex.texture = default_checker
		tile_map_right_bg_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile_map_right_bg_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tile_map_right_bg_tex.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		tile_map_right_bg_tex.stretch_mode = TextureRect.STRETCH_TILE
		tile_map_base_right.add_child(tile_map_right_bg_tex)
		tile_map_right_bg_tex.show_behind_parent = true
		tile_map_bg_right.visible = false
		
		tile_map_dropdown = OptionButton.new()
		tile_map_dropdown.add_item("Show Checks")
		tile_map_dropdown.add_item("Dark Checks")
		tile_map_dropdown.add_item("No Checks")
		tile_map_dropdown.set_anchors_preset(Control.PRESET_CENTER_TOP)
		tile_map_editor.add_child(tile_map_dropdown)
		tile_map_dropdown.position.x -= tile_map_dropdown.size.x
		tile_map_dropdown.position.y -= tile_map_dropdown.size.y
		tile_map_dropdown.connect("item_selected", tile_map_change_checks)
		
		tile_map_color_picker = ColorPickerButton.new()
		tile_map_color_picker.set_anchors_preset(Control.PRESET_CENTER_TOP)
		tile_map_color_picker.icon = color_button_tex
		tile_map_color_picker.color = tile_map_bg_color
		tile_map_editor.add_child(tile_map_color_picker)
		tile_map_color_picker.position = tile_map_dropdown.position - Vector2(tile_map_color_picker.size.x * 1.2, 0)
		tile_map_color_picker.connect("color_changed", tile_map_color_picker_button_color_changed)

func setup_tileset():
	var base = editor_interface.get_base_control()
	tile_set_editor = find_tilset_editor(base)
	if tile_set_editor:
		var panel: Panel = tile_set_editor.get_child(0)
		var center_container: CenterContainer = panel.get_child(0)
		var margin_contailer: MarginContainer = center_container.get_child(1)
		var hbox: HBoxContainer = margin_contailer.get_child(0)
		var leftbox: VBoxContainer = hbox.get_child(0)
		var base_left: Control = hbox.get_child(0)
		var base_right: Control = hbox.get_child(1)
		
		tile_set_base_left = base_left.get_child(1)
		tile_set_base_right = base_right.get_child(1)
		tile_set_bg_left = tile_set_base_left.get_child(0)
		tile_set_bg_right = tile_set_base_right.get_child(0)
		
		tile_set_left_bg_tex = TextureRect.new()
		tile_set_left_bg_tex.texture = default_checker
		tile_set_left_bg_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile_set_left_bg_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tile_set_left_bg_tex.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		tile_set_left_bg_tex.stretch_mode = TextureRect.STRETCH_TILE
		tile_set_base_left.add_child(tile_set_left_bg_tex)
		tile_set_left_bg_tex.show_behind_parent = true
		tile_set_bg_left.visible = false
		
		tile_set_right_bg_tex = TextureRect.new()
		tile_set_right_bg_tex.texture = default_checker
		tile_set_right_bg_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile_set_right_bg_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tile_set_right_bg_tex.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		tile_set_right_bg_tex.stretch_mode = TextureRect.STRETCH_TILE
		tile_set_base_right.add_child(tile_set_right_bg_tex)
		tile_set_right_bg_tex.show_behind_parent = true
		tile_set_bg_right.visible = false
		
		tile_set_dropdown = OptionButton.new()
		tile_set_dropdown.add_item("Show Checks")
		tile_set_dropdown.add_item("Dark Checks")
		tile_set_dropdown.add_item("No Checks")
		tile_set_dropdown.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		tile_set_editor.add_child(tile_set_dropdown)
		tile_set_dropdown.position.x -= tile_set_dropdown.size.x
		tile_set_dropdown.position.y -= tile_set_dropdown.size.y
		tile_set_dropdown.connect("item_selected", tile_set_change_checks)
		
		tile_set_color_picker = ColorPickerButton.new()
		tile_set_color_picker.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		tile_set_color_picker.icon = color_button_tex
		tile_set_color_picker.color = tile_set_bg_color
		tile_set_editor.add_child(tile_set_color_picker)
		tile_set_color_picker.position = tile_set_dropdown.position - Vector2(tile_set_color_picker.size.x * 1.2, 0)
		tile_set_color_picker.connect("color_changed", tile_set_color_picker_button_color_changed)


func _exit_tree() -> void:
	if tile_set_editor:
		tile_set_dropdown.queue_free()
		tile_set_color_picker.queue_free()
		tile_set_editor.remove_child(tile_set_dropdown)
		tile_set_editor.remove_child(tile_set_color_picker)
		tile_set_left_bg_tex.queue_free()
		tile_set_right_bg_tex.queue_free()
	if tile_map_editor:
		tile_map_dropdown.queue_free()
		tile_map_color_picker.queue_free()
		tile_map_editor.remove_child(tile_map_dropdown)
		tile_map_editor.remove_child(tile_map_color_picker)
		tile_map_left_bg_tex.queue_free()
		tile_map_right_bg_tex.queue_free()


func find_tilset_editor(node):
	var name: String = node.name
	if node is Control and name.contains("TileAtlasView"):
		return node
	
	for child in node.get_children():
		if child is Control:
			var result = find_tilset_editor(child)
			if result:
				return result
	return null

func find_tile_map_base_editor(node):
	var name: String = node.name
	if node is Control and name.contains("TileMap"):
		return node
	for child in node.get_children():
		if child is Control:
			var result = find_tile_map_base_editor(child)
			if result:
				return result
	return null

func find_tilemap_editor(node):
	var name: String = node.name
	print(name)
	if node is Control and name.contains("TileAtlasView"):
		return node
	
	for child in node.get_children():
		if child is Control:
			var result = find_tilemap_editor(child)
			if result:
				return result
	return null

func tile_set_change_checks(index: int):
	var selected = tile_set_dropdown.get_item_text(tile_set_dropdown.get_selected_id())
	tile_set_left_bg_tex.modulate = tile_set_bg_color
	tile_set_right_bg_tex.modulate = tile_set_bg_color
	if selected == "Dark Checks":
		tile_set_left_bg_tex.texture = dark_checker
		tile_set_right_bg_tex.texture = dark_checker
	elif selected == "No Checks":
		tile_set_left_bg_tex.texture = blank_checker
		tile_set_right_bg_tex.texture = blank_checker
	else:
		tile_set_left_bg_tex.texture = default_checker
		tile_set_right_bg_tex.texture = default_checker

func tile_map_change_checks(index: int):
	var selected = tile_map_dropdown.get_item_text(tile_map_dropdown.get_selected_id())
	tile_map_left_bg_tex.modulate = tile_map_bg_color
	tile_map_right_bg_tex.modulate = tile_map_bg_color
	if selected == "Dark Checks":
		tile_map_left_bg_tex.texture = dark_checker
		tile_map_right_bg_tex.texture = dark_checker
	elif selected == "No Checks":
		tile_map_left_bg_tex.texture = blank_checker
		tile_map_right_bg_tex.texture = blank_checker
	else:
		tile_map_left_bg_tex.texture = default_checker
		tile_map_right_bg_tex.texture = default_checker

func tile_set_color_picker_button_color_changed(color: Color):
	tile_set_bg_color = color
	tile_set_change_checks(0)

func tile_map_color_picker_button_color_changed(color: Color):
	tile_map_bg_color = color
	tile_map_change_checks(0)
