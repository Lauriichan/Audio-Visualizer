extends Node

export(Array, float) var refresh_rates;
export(Array, String) var api_names;

var selected : String = "";
var refresh_rate : float;

var time : float;

func _ready():
	var _ignore = get_node("..").connect("root_ready", self, "_root_ready");
	
func _root_ready(root):
	root._connect_settings(self, "_update_api");
	for api_name in api_names:
		var gdscript = load("Assets/Script/Api/" + api_name + ".gd");
		var node = Node.new();
		node.set_name(api_name);
		node.set_script(gdscript);
		add_child(node);

func _update_api():
	_update_audio();
	var updated = Settings.get_default("DataApi", "VLC");
	if selected == updated:
		get_node(selected)._update_api();
		return;
	if not selected.empty():
		get_node(selected).disable();
	var node = get_node(updated);
	if not node:
		selected = "";
		return;
	refresh_rate = refresh_rates[api_names.find(selected)];
	selected = updated;
	node.enable();
	
func _update_audio():
	var device = Settings.get_default("DataAudio", "Default");
	if AudioServer.capture_get_device() == device:
		return;
	AudioServer.capture_set_device(device);
	
func _physics_process(delta):
	time += delta;
	if time < refresh_rate:
		return;
	time -= refresh_rate;
	if selected.empty():
		return;
	get_node(selected)._update();
