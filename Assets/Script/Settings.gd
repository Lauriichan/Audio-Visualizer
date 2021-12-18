extends Node

var data : Dictionary;

func _ready():
	pass

func get_default(path, default):
	if not path in data:
		return default;
	return data[path];
	
func get(path):
	return get_default(path, null);
	
func set(path, value):
	data[path] = value;

func remove(path):
	var _ignore = data.erase(path);
