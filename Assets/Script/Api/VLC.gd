extends BaseApi
class_name VLC

var request : HTTPClient;
var auth : String;

var host : String;
var port : int;

var ref : FuncRef;

var result = null;

func _ready():
	ref = FuncRef.new();
	ref.function = "_load_image";
	ref.set_instance(self);

func _update() -> Song:
	
	var _ignore = request.poll();
	if request.get_status() != HTTPClient.STATUS_CONNECTED and request.get_status() != HTTPClient.STATUS_BODY:
		if request.get_status() == HTTPClient.STATUS_CONNECTING:
			return null;
		_ignore = request.connect_to_host(host, port, false, true);
		return null;
	var headers = [
		"Authorization: Basic " + auth
	];
	var error = request.request(HTTPClient.METHOD_GET, "/requests/status.xml", headers);
	if error != OK:
		return null;
	
	_ignore = request.poll();
	while request.get_status() == HTTPClient.STATUS_REQUESTING:
		OS.delay_msec(1)
		_ignore = request.poll();
	
	if not request.has_response():
		return null;
	_ignore = request.poll();
	var parser = XMLParser.new();
	error = parser.open_buffer(request.read_response_body_chunk());
	result = null;
	if error != OK:
		return null;
	return _parse_song(parser);

func _parse_song(parser) -> Song:
	var song = Song.new();
	song.image_loader = ref;
	load_until_node(parser, song, "category");
	var _ignore = parser.read();
	while true:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT_END and parser.get_node_name().begins_with("category"):
			break;
		if parser.get_node_type() == XMLParser.NODE_ELEMENT:
			var key = parser.get_node_name();
			_ignore = parser.read();
			if parser.get_node_type() != XMLParser.NODE_TEXT:
				continue;
			read_next(parser, song, key);
		_ignore = parser.read();
	return song;

func read_next(parser, song, key):
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
		"position":
			song.progress = float(parser.get_node_data());
		"state":
			song.playing = parser.get_node_data() == "playing";
		
func load_until_node(parser, song, key):
	var _ignore;
	while true:
		if parser.get_node_type() != XMLParser.NODE_ELEMENT and parser.get_node_type() != XMLParser.NODE_ELEMENT_END:
			_ignore = parser.read();
			continue;
		var current_key = parser.get_node_name();
		_ignore = parser.read();
		if current_key.begins_with(key):
			return;
		if parser.get_node_type() == XMLParser.NODE_TEXT:
			read_next(parser, song, current_key);

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
	host = Settings.get_default("VlcHost", "127.0.0.1");
	port = Settings.get_default("VlcPort", 8080);
	auth = Marshalls.utf8_to_base64(":" + Settings.get_default("VlcPassword", "Password"));

func _on_enable():
	request = HTTPClient.new();
	
func _on_disable():
	request.close();
	request = null;
