extends BaseApi
class_name StreamCompanion

var server : TCPServer;
var client : StreamPeerTCP;
var port : int = 7840;
var thread : Thread;

var run : bool = false;

var ref : Callable;
var songData : String;

func _ready():
	ref = Callable(self, "_load_image");
	
func _update() -> Song:
	if songData == null or songData.is_empty():
		return null;
	var song = Song.new();
	song.image_loader = ref;
	var array = songData.split("///&///");
	song.title = array[0];
	song.artist = array[1];
	song.playing = true;
	song.progress = float(array[2]);
	song.image_data = array[3];
	return song;

func _read_update(): 
	while run:
		if client == null || !client.is_connected_to_host():
			client = server.take_connection();
			OS.delay_msec(50);
			continue;
		if client.get_available_bytes() == 0:
			continue;
		var data = client.get_string(client.get_available_bytes());
		_save_song(data);
		OS.delay_msec(100);
		
func _save_song(data : String):
	var idx = data.find("{");
	if idx == -1:
		return;
	var json = JSON.new()
	json.parse(data.substr(idx, data.find("}", idx + 1) - 1));
	var dictionary = json.get_data()
	if "visualizer" in dictionary:
		songData = dictionary["visualizer"];

func _load_image(_data):
	if _data == null or _data.is_empty():
		return null;
	var image = Image.new();
	var error = image.load(_data);
	if error != OK:
		return null;
	return image;
	
func _update_api():
	port = Settings.get_default("StreamCompanionPort", 7840);
	disable();
	enable();
	
func _on_enable():
	server = TCPServer.new();
	var _ignore = server.listen(port, "127.0.0.1");
	thread = Thread.new();
	run = true;
	_ignore = thread.start(Callable(self, "_read_update"));
	
func _on_disable():
	run = false;
	server.stop();
	if client != null:
		client.disconnect_from_host();
	thread.wait_to_finish();
	client = null;
	thread = null;
	server = null;
