@tool
extends Control
class_name BetterProgressBar

@export var min_value : float = 0.0: set = set_min_value
@export var max_value : float = 1.0: set = set_max_value
@export var value : float = 0.0: set = set_value

var difference : float = 1.0;
var progress : float = 0.0;
var prev_progress : float = 0.0;

var target : float = 0.0;
var smoothing = false;

var actual_theme : Theme;

func set_min_value(_min_value):
	if _min_value > max_value:
		min_value = max_value;
		max_value = _min_value;
		return;
	min_value = _min_value;
	
func set_max_value(_max_value):
	if _max_value < min_value:
		max_value = min_value;
		min_value = _max_value;
		return;
	max_value = _max_value;

func set_value(_value):
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
	
func get_box(box_name):
	var _theme = get_theme_or_root();
	if not _theme.has_stylebox(box_name, "BetterProgressBar"):
		_theme.set_stylebox(box_name, "BetterProgressBar", StyleBoxFlat.new());
	return _theme.get_stylebox(box_name, "BetterProgressBar");

func _draw():
	get_box("background").draw(self.get_canvas_item(), Rect2(0, 0, size.x, size.y));
	get_box("foreground").draw(self.get_canvas_item(), Rect2(0, 0, size.x * progress, size.y));
	
func _process(_delta):
	if Engine.is_editor_hint():
		update_bar();
	if prev_progress != progress:
		prev_progress = progress;
		queue_redraw();
	
func _physics_process(_delta : float):
	if smoothing:
		if target >= value:
			value = lerp(value, target, _delta);
		else:
			value = lerp(value, target, _delta * 6);
	update_bar();
	
func update_bar():
	if value > max_value:
		value = max_value;
	elif value < min_value:
		value = min_value;
	progress = (value - min_value) / (max_value - min_value);
