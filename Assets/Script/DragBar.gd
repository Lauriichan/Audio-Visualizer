extends Control

var prevPoint = Vector2();
var dragging = false;
var last = 0;
var count = 0;

@onready var api = get_node("/root/Root/Api");
@onready var window = get_window();

func _physics_process(delta):
	if last > 0:
		last -= delta;

func _input(_event):
	if _event is InputEventMouseButton:
		_button(_event);
	if _event is InputEventMouseMotion:
		_motion(_event);

func _button(_event : InputEventMouseButton):
	if _event.button_index == MOUSE_BUTTON_LEFT:
		if _event.pressed and _is_inside():
			if last > 0:
				fullscreen();
				last = 0;
			else:
				last = 0.75;
		if _event.pressed and not dragging and _is_inside():
			prevPoint = get_global_mouse_position();
			dragging = true;
			return;
		elif not _event.pressed and dragging:
			dragging = false;
			return;
			
func fullscreen():
	window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN if window.mode != Window.MODE_EXCLUSIVE_FULLSCREEN else Window.MODE_WINDOWED;
	var _ignore;
	api._stop();
	if window.mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
		_ignore = get_tree().change_scene_to_file("res://Fullscreen.tscn");
	else:
		_ignore = get_tree().change_scene_to_file("res://Scene.tscn");

func _motion(_event : InputEventMouseMotion):
	if dragging:
		window.position = Vector2i((Vector2(window.position) - prevPoint) + get_global_mouse_position());

func _is_inside() -> bool: 
	var pos = get_local_mouse_position();
	return pos.x >= position.x && pos.x <= position.x + size.x && pos.y >= position.y && pos.y <= position.y + size.y;
