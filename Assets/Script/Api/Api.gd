extends Node
class_name API

var boot_icon : Image = load("boot.png");

@export var refresh_rates : Array[float];
@export var api_names : Array[String];

var selected : String = "";
var refresh_rate : float;

var time : float;

var previous : Song;
var dump_song : bool;
var dump_format : String;

var ui_spectrum : AudioSpectrum;
var ui_bar : BetterProgressBar;
var ui_icon : TextureRect;
var ui_title : Label;
var ui_artist : Label;
var ui_debug : Control;

var started : bool = true;
var reset_spectrum : int = 0;

func _ready():
	ui_debug = get_node("../Debug");
	var body = get_node("../Body");
	ui_spectrum = body.get_node("AudioSpectrum");
	ui_bar = body.get_node("BetterProgressBar");
	ui_icon = body.get_node("TextureRect");
	ui_title = body.get_node("VBoxContainer/Title");
	ui_artist = body.get_node("VBoxContainer/Artist");
	var _ignore = get_node("..").connect("root_ready", Callable(self, "_root_ready"));
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
		
func _start():
	if started:
		return;
	started = true;
	_update_api();
	
func _stop():
	if not started:
		return;
	started = false;
	if not selected.is_empty():
		get_node(selected).disable();

func _update_api():
	if not started:
		return;
	_update_debug();
	_update_dump();
	_update_audio();
	var updated = Settings.get_default("DataApi", "VLC");
	if selected == updated:
		get_node(selected)._update_api();
		return;
	if not selected.is_empty():
		get_node(selected).disable();
	var node = get_node(updated);
	if not node:
		selected = "";
		return;
	refresh_rate = refresh_rates[api_names.find(selected)];
	selected = updated;
	node.enable();
	node._update_api();
	
func _update_debug():
	var debug = Settings.get_default("Debug", false);
	if(!ui_debug):
		return;
	if(debug):
		ui_debug.show();
	elif(ui_debug.visible):
		ui_debug.hide();
	ui_spectrum.debug = debug;
	
func _update_dump():
	dump_song = Settings.get_default("DumpEnabled", false);
	dump_format = Settings.get_default("DumpFormat", "$artist - $title")
	if dump_song and previous != null:
		_dump_to_file();
		
func _update_audio():
	if !ui_spectrum.legacy:
		ui_spectrum.reset = true;
	var device = Settings.get_default("DataAudio", "Default");
	if AudioServer.get_input_device() == device:
		return;
	AudioServer.set_input_device(device);
	
func _physics_process(delta):
	time += delta;
	if time < refresh_rate:
		return;
	time -= refresh_rate;
	if selected.is_empty():
		return;
	var song = get_node(selected)._update();
	if reset_spectrum == 0:
		reset_spectrum = -1;
		ui_spectrum._reset_magnitude();
	else:
		reset_spectrum -= 1;
	if song == null or not song is Song:
		ui_spectrum._reset_magnitude();
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
	if previous == null or (song.title != previous.title):
		previous = song;
		reset_spectrum = 2;
		if dump_song:
			_dump_to_file();
			
func _dump_to_file():
	var file = FileAccess.open("song.txt", FileAccess.WRITE);
	file.store_string(dump_format.replace("$artist", previous.artist).replace("$title", previous.title))
	file.flush();
	file.close();
		
func resize_if_needed(image : Image) -> Image:
	var width = image.get_width();
	var height = image.get_height();
	if height == width:
		return image;
	if width > height:
		return image.get_rect(Rect2((width - height) / 2, 0, height, height));
	return image.get_rect(Rect2(0, (height - width), width, width));
