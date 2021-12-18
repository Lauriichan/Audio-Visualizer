extends Control

signal root_ready(root)

var prevPoint = Vector2();
var dragging = false;

var dropdown = false;
onready var element = $Dropdown;

func _ready():
	get_tree().set_auto_accept_quit(false);
	element._load_data();
	emit_signal("root_ready", self);
	element._save_data();
	
func _connect_settings(var node : Node, var method : String):
	var _ignore = element.connect("update_settings", node, method);
	
func _input(_event):
	if not _event is InputEventMouseButton:
		return;
	if _event.button_index == BUTTON_RIGHT and _event.pressed:
		if dropdown:
			dropdown = false;
			element.visible = false;
			element._save_data();
			return;
		dropdown = true;
		element.rect_position = get_local_mouse_position();
		element.visible = true;
	
func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		element._save_data();
		get_tree().quit();

func _is_inside() -> bool: 
	var position = get_local_mouse_position();
	return position.x >= element.rect_position.x && position.x <= element.rect_position.x + element.rect_size.x && position.y >= element.rect_position.y && position.y <= element.rect_position.y + element.rect_size.y;
