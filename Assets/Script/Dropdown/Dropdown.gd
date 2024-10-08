extends Control

signal update_settings

@export var path: String = "user://settings.json";
@export var defaults: Dictionary = {};


func _ready():
	var node : Container = $ScrollContainer/VBoxContainer;
	for child in node.get_children():
		if (child is ColorPickerButton):
			_setup_picker(child);

func _setup_picker(node : ColorPickerButton):
	node.get_picker().scale = Vector2(0.85, 0.85);
	var size = Vector2i(node.get_picker().size * node.get_picker().scale);
	size.x += 10;
	node.get_popup().min_size = size;
	node.get_popup().max_size = size;
	node.get_popup().size = size;
	node.get_picker().size = size;
	node.get_popup().about_to_popup.connect(func(): node.get_popup().position.x = node.get_popup().position.x - size.x);
	
func _resize_popup(popup):
	popup.position.x = popup.position.x - popup.size.x;

func get_data_path() -> String:
	return path.replace("user://", OS.get_user_data_dir() + '/');

func _load_data():
	Settings.clear();
	if not FileAccess.file_exists(path):
		_setup_data();
		return;
	var file = FileAccess.open(path, FileAccess.READ);
	var content = file.get_as_text();
	file.close();
	var json = JSON.new()
	if json.parse(content) != Error.OK:
		_setup_data();
		return;
	var result = json.get_data()
	if not result is Dictionary:
		_setup_data();
		return;
	for key in result.keys():
		if not result[key]:
			continue;
		if key.ends_with("Color"):
			Settings.set_data(key, Color(result[key]));
			continue;
		Settings.set_data(key, result[key]);
	_setup_data();
		
func _setup_data(): # Setup settings dropdown
	for child in $ScrollContainer/VBoxContainer.get_children():
		var key = child.get_name();
		var setting = Settings.get_default(key, _default(key));
		if setting == null:
			continue;
		_apply_value(child, setting);

func _apply_value(node, value):
	if node is SpinBox:
		node.set_value(value);
		return;
	if node is LineEdit:
		node.set_text(value);
		return;
	if node is ColorPickerButton:
		node.color = value;
		return;
	if node is CheckBox:
		node.set_pressed(value);
		return;
	if node is DropdownButton:
		node._set_selected(value);
		return;

func _default(key):
	if key in defaults:
		return defaults[key];
	return null;

func _save_data():
	_read_data();
	_apply_data();
	emit_signal("update_settings");
	var dict = {};
	for key in Settings.data.keys():
		var value = Settings.get_data(key);
		if value == _default(key):
			continue;
		if value is Color:
			dict[key] = Color(value).to_html(false);
			continue;
		dict[key] = value;
	var file = FileAccess.open(path, FileAccess.WRITE);
	file.store_string(JSON.stringify(dict));
	file.flush();
	file.close();
	
func _read_data():
	for child in $ScrollContainer/VBoxContainer.get_children():
		var key = child.get_name();
		if not key in defaults:
			continue;
		var value = _get_if_not_default(child);
		if not value:
			value = _default(key)
			if not value:
				Settings.remove(key);
				continue;
		Settings.set_data(key, value);
	
func _apply_data(): # Apply data to Theme
	color("TextColor", {
		"Label": "font_color"
	});
	style_color("BackgroundColor", {
		"Button": "normal",
		"VScrollBar": [
			"scroll", 
			"scroll_focus"
		]
	});
	style_color("BarBackgroundColor", {
		"BetterProgressBar": "background"
	});
	node_color("BackgroundColor", {
		"../Body/ColorRect": "color"
	});
	node_color("BorderColor", {
		"../Body/ColorRect2": "color"
	});
	_apply_accent();
	
func _apply_accent():
	style_color("AccentColor", {
		"BetterProgressBar": "foreground",
		"VScrollBar": [
			"grabber",
			"grabber_highlight",
			"grabber_pressed"
		]
	});
	node_color("AccentColor", {
		"../Bar/ColorRect": "color",
		"../Body/AudioSpectrum": "BarColor"
	});
	
func color(key, items):
	var value = Settings.get_default(key, _default(key));
	if value == null:
		return;
	for type in items.keys():
		var item = items[type];
		if item is Array:
			for i in item:
				theme.set_color(i, type, value);
			continue
		theme.set_color(item, type, value);
		
func node_color(key, nodes):
	var value = Settings.get_default(key, _default(key));
	if value == null:
		return;
	for node in nodes.keys():
		var obj = get_node(node);
		if obj == null:
			continue;
		var vars = nodes[node];
		if vars is Array:
			for v in vars:
				obj.set(v, value);
			continue
		obj.set(vars, value);
		
func style_color(key, items):
	var value = Settings.get_default(key, _default(key));
	if value == null:
		return;
	for type in items.keys():
		var item = items[type];
		if item is Array:
			for i in item:
				style_color_set(i, type, value);
			continue
		style_color_set(item, type, value);
		
func style_color_set(item, type, value):
	var box = theme.get_stylebox(item, type);
	if not box is StyleBoxFlat:
		return;
	box.bg_color = value;

func _get_if_not_default(node):
	var def = _default(node.get_name());
	var value = _get_value(node);
	if def == value:
		return null;
	return value;

func _get_value(node):
	if node is SpinBox:
		return node.value;
	if node is LineEdit:
		return node.text;
	if node is ColorPickerButton:
		return node.color;
	if node is CheckBox:
		return node.button_pressed;
	if node is DropdownButton:
		return node._get_selected();
	return null;
