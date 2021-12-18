extends Control

var prevPoint = Vector2();
var dragging = false;

func _input(_event):
	if _event is InputEventMouseButton:
		_button(_event);
	if _event is InputEventMouseMotion:
		_motion(_event);

func _button(_event : InputEventMouseButton):
	if _event.button_index == BUTTON_LEFT:
		if _event.pressed and not dragging and _is_inside():
			prevPoint = get_global_mouse_position();
			dragging = true;
			return;
		elif not _event.pressed and dragging:
			dragging = false;
			return;

func _motion(_event : InputEventMouseMotion):
	if dragging:
		OS.window_position = (OS.window_position - prevPoint) + get_global_mouse_position();

func _is_inside() -> bool: 
	var position = get_local_mouse_position();
	return position.x >= rect_position.x && position.x <= rect_position.x + rect_size.x && position.y >= rect_position.y && position.y <= rect_position.y + rect_size.y;
