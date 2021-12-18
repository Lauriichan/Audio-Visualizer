extends Node
class_name BaseApi

onready var song_struct = load("Assets/Script/Api/SongStruct.gd");

var enabled : bool;

func enable():
	if enabled:
		return;
	enabled = true;
	_on_enable();
	
func disable():
	if not enabled:
		return;
	enabled = false;
	_on_disable();
	
func is_enabled() -> bool:
	return enabled;
	
func _update() -> Song:
	return null;
	
func _update_api():
	pass
	
func _on_enable():
	pass
	
func _on_disable():
	pass
