extends BaseApi
class_name VLC

var request : HTTPRequest;
var parser : XMLParser;
var auth : String;
var url : String;

var ref : FuncRef;

var result = null;

func _ready():
	ref = FuncRef.new();
	ref.function = "_load_image";
	ref.set_instance(self);

func _update() -> Song:
	var headers = [
		"Authorization: Basic " + auth
	];
	if request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		request.cancel_request();
	var error = request.request(url, headers, true, HTTPClient.METHOD_GET);
	if error != OK:
		return null;
	while not result:
		yield();
	if not result is PoolByteArray:
		return null;
	error = parser.open_buffer(result);
	result = null;
	if error != OK:
		return null;
	return _parse_song();

func _parse_song() -> Song:
	var song = Song.new();
	song.image_loader = ref;
	skip_to_node("state")
	song.playing = parser.get_node_data() == "playing";
	skip_to_node("position");
	song.progress = float(parser.get_node_data());
	skip_to_node("category");
	var _ignore = parser.read();
	while true:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT_END and parser.get_node_name().begins_with("category"):
			break;
		if parser.get_node_type() == XMLParser.NODE_ELEMENT:
			var key = parser.get_node_name();
			_ignore = parser.read();
			if parser.get_node_type() != XMLParser.NODE_TEXT:
				continue;
			read_next(song, key);
		_ignore = parser.read();
	return song;

func read_next(song, key):
	match key:
		"artist":
			song.artist = parser.get_node_data();
		"title":
			song.title = parser.get_node_data();
		"artwork_url":
			var data : String = parser.get_node_data();
			data.erase(0, 8);
			song.image_data = data.http_unescape();
		"filename":
			if song.title.empty() or song.title == "Unknown Title":
				var data = parser.get_node_data();
				song.title = data;
				if data.find(".") != -1:
					var out = "";
					var parts = data.split(".");
					for idx in range(parts.size() - 1):
						out = out + parts[idx];
					song.title = out;

func skip_to_node(key):
	var _ignore;
	while true:
		if parser.get_node_type() != XMLParser.NODE_ELEMENT and parser.get_node_type() != XMLParser.NODE_ELEMENT_END:
			_ignore = parser.read();
			continue;
		if parser.get_node_name().begins_with(key):
			_ignore = parser.read();
			break;
		_ignore = parser.read();

func _load_image(data):
	if data == null or data.empty():
		return null;
	var image = Image.new();
	var error = image.load(data);
	if error != OK:
		return null;
	return image;

func _receive_request(_result, _response_code, _headers, _body):
	if _result != HTTPRequest.RESULT_SUCCESS:
		result = true;
		return;
	if _response_code != 200:
		result = true;
		return;
	result = _body;
	
func _update_api():
	url = "http://" + Settings.get_default("VlcHost", "127.0.0.1") + ":" + str(Settings.get_default("VlcPort", 8080)) + "/requests/status.xml";
	print(url);
	auth = Marshalls.utf8_to_base64(":" + Settings.get_default("VlcPassword", "Password"));

func _on_enable():
	request = HTTPRequest.new();
	parser = XMLParser.new();
	add_child(request);
	var _ignore = request.connect("request_completed", self, "_receive_request");
	
func _on_disalbe():
	remove_child(request);
	parser.queue_free();
	parser = null;
	request.queue_free();
	request = null;
