extends Node

var boot_icon : Image = load("boot.png");

export(Array, float) var refresh_rates;
export(Array, String) var api_names;

var selected : String = "";
var refresh_rate : float;

var time : float;

var previous : Song;

var ui_bar : BetterProgressBar;
var ui_icon : TextureRect;
var ui_title : Label;
var ui_artist : Label;

func _ready():
	var body = get_node("../Body");
	ui_bar = body.get_node("BetterProgressBar");
	ui_icon = body.get_node("TextureRect");
	ui_title = body.get_node("VBoxContainer/Title");
	ui_artist = body.get_node("VBoxContainer/Artist");
	var _ignore = get_node("..").connect("root_ready", self, "_root_ready");
	ui_bar.smoothing = true;
	ui_bar.target = 0;
	
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
	node._update_api();
	
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
	var song = get_node(selected)._update();
	if song == null or not song is Song:
		return;
	_update_interface(song);
		
func _update_interface(song):
	if not song.playing and song.progress == -1:
		ui_bar.target = 0;
		if previous != null:
			previous = null;
			ui_title.text = "Audio Visualizer";
			ui_artist.text = "by Lauriichan";
			ui_icon.texture.image = boot_icon;
		return;
	if song.playing or previous == null:
		ui_bar.target = song.progress;
	else:
		ui_bar.target = previous.progress;
	if previous == null or song.title != previous.title:
		var image : Image = song.image_loader.call_func(song.image_data);
		if image != null:
			ui_icon.texture.image = resize_if_needed(image);
		else:
			ui_icon.texture.image = boot_icon;
	ui_title.text = song.title;
	ui_artist.text = song.artist;
	if previous == null or song.title != previous.title or song.playing:
		previous = song;
		
func resize_if_needed(image : Image) -> Image:
	var width = image.get_width();
	var height = image.get_height();
	if height == width:
		return image;
	if width > height:
		return image.get_rect(Rect2((width - height) / 2, 0, height, height));
	return image.get_rect(Rect2(0, (height - width), width, width));
