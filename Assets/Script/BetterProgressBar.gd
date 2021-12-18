tool
extends Control
class_name BetterProgressBar

export var min_value : float = 0.0 setget set_min_value; 
export var max_value : float = 1.0 setget set_max_value;
export var value : float = 0.0 setget set_value;

var difference : float = 1.0;
var progress : float = 0.0;

var actual_theme : Theme;

func set_min_value(var _min_value):
	if _min_value > max_value:
		min_value = max_value;
		max_value = _min_value;
		return;
	min_value = _min_value;
	
func set_max_value(var _max_value):
	if _max_value < min_value:
		max_value = min_value;
		min_value = _max_value;
		return;
	max_value = _max_value;

func set_value(var _value):
	if _value > max_value:
		value = max_value;
		return;
	if _value < min_value:
		value = min_value;
		return;
	value = _value;

func get_theme_or_root():
	if actual_theme != null:
		return actual_theme;
	var node = self;
	while true:
		if node == null:
			break;
		if node is Control and node.theme != null:
			actual_theme = node.theme;
			return actual_theme;
		node = node.get_node("../");
	actual_theme = Theme.new();
	return actual_theme;
	
func get_box(var box_name):
	var _theme = get_theme_or_root();
	if not _theme.has_stylebox(box_name, "BetterProgressBar"):
		_theme.set_stylebox(box_name, "BetterProgressBar", StyleBoxFlat.new());
	return _theme.get_stylebox(box_name, "BetterProgressBar");

func _draw():
	get_box("background").draw(self.get_canvas_item(), Rect2(0, 0, rect_size.x, rect_size.y));
	get_box("foreground").draw(self.get_canvas_item(), Rect2(0, 0, rect_size.x * progress, rect_size.y));
	
func _process(_delta):
	if Engine.editor_hint:
		update_bar();
	update();
	
func _physics_process(_delta):
	update_bar();
	
func update_bar():
	if value > max_value:
		value = max_value;
	elif value < min_value:
		value = min_value;
	progress = (value - min_value) / (max_value - min_value);
