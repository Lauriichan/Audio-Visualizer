extends Control

signal root_ready(root)

var prevPoint = Vector2();
var dragging = false;

var dropdown = false;
@onready var element = $Dropdown;

var type = 0;

var rainbow_current = 0;

var gradient = Gradient.new();
var gradient_pos = 0;
var gradient_increase = true;

var speed = 0.01;

func _ready():
	get_tree().set_auto_accept_quit(false);
	element._load_data();
	emit_signal("root_ready", self);
	_connect_settings(self, "_update_settings");
	element._save_data();
	
func _connect_settings(node : Node, method : String):
	var _ignore = element.connect("update_settings", Callable(node, method));

func _update_settings():
	type = 0;
	speed = Settings.get_default("AccentSpeed", 100) / 100000.0;
	var accent_type = Settings.get_default("AccentType", "Static");
	if accent_type == "Gradient":
		gradient.set_color(0, Settings.get_data("AccentColor"));
		gradient.set_color(1, Settings.get_data("AccentGradColor"));
		gradient_increase = true;
		gradient_pos = 0;
		type = 1;
	elif accent_type == "Rainbow":
		rainbow_current = Settings.get_data("AccentColor").h;
		type = 2;

func _physics_process(_delta):
	if type == 0:
		return;
	if type == 1:
		if gradient_increase:
			gradient_pos = gradient_pos + speed;
		else:
			gradient_pos = gradient_pos - speed;
		if gradient_pos <= -0.2:
			gradient_increase = true;
		elif gradient_pos >= 1.2:
			gradient_increase = false;
		Settings.set_data("AccentColor", gradient.sample(gradient_pos));
		element._apply_accent();
		return;
	rainbow_current = rainbow_current + speed;
	var color = Color.from_hsv(rainbow_current, 1, 1, 1);
	rainbow_current = color.h;
	Settings.set_data("AccentColor", color);
	element._apply_accent();
	
func _input(_event):
	if not _event is InputEventMouseButton:
		return;
	if _event.button_index == MOUSE_BUTTON_RIGHT and _event.pressed:
		if dropdown:
			dropdown = false;
			element.visible = false;
			element._save_data();
			return;
		dropdown = true;
		element.position = get_local_mouse_position();
		element.visible = true;
	
func _notification(what):
	if what == Node.NOTIFICATION_WM_CLOSE_REQUEST:
		element._save_data();
		get_tree().quit();

func _is_inside() -> bool: 
	var position = get_local_mouse_position();
	return position.x >= element.position.x && position.x <= element.position.x + element.size.x && position.y >= element.position.y && position.y <= element.position.y + element.size.y;
