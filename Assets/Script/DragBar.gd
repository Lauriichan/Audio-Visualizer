extends Control

var prevPoint = Vector2();
var dragging = false;
var last = 0;
var count = 0;

func _physics_process(delta):
	if last > 0:
		last -= delta;

func _input(_event):
	if _event is InputEventMouseButton:
		_button(_event);
	if _event is InputEventMouseMotion:
		_motion(_event);

func _button(_event : InputEventMouseButton):
	if _event.button_index == BUTTON_LEFT:
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
	OS.window_fullscreen = !OS.window_fullscreen;
	if OS.window_fullscreen:
		get_tree().change_scene("res://Fullscreen.tscn");
	else:
		get_tree().change_scene("res://Scene.tscn");

func _motion(_event : InputEventMouseMotion):
	if dragging:
		OS.window_position = (OS.window_position - prevPoint) + get_global_mouse_position();

func _is_inside() -> bool: 
	var position = get_local_mouse_position();
	return position.x >= rect_position.x && position.x <= rect_position.x + rect_size.x && position.y >= rect_position.y && position.y <= rect_position.y + rect_size.y;
