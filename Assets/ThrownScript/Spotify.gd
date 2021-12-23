extends BaseApi
class_name Spotify

const alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"

var auth : String;
var url : String;

var ref : FuncRef;

var result = null;

var client_id;
var basic;
var port;

var access_token;
var refresh_token;
var time = 0;
var expires = 0;

var client : HttpPool;
var http : HTTPRequest;

var song : Song;
var thread : Thread;

var random : RandomNumberGenerator;

var abort : bool = false;
var update_song : bool = false;

var _request_state = 0;

func _ready():
	random = RandomNumberGenerator.new();
	random.randomize();

func _execute_task():
	while not abort:
		var current = OS.get_ticks_msec();
		if access_token == null:
			_request_access_token();
			time = current;
		if current - time >= expires:
			_refresh_access_token();
			time = current;
		if update_song:
			update_song = false;
			_request_song();
			
func _get_query(state) -> String:
	return "response_type=code&client_id=" + client_id + "&redirect_uri=http://localhost:" + port + "/&state=" + state + "&scope=user-read-currently-playing"
	
func _rand_string(var length):
	var output = "";
	for i in range(length):
		output += alphabet.substr(random.randi_range(0, alphabet.length() - 1), 1);
	return output;
	
func _request_access_token():
	var server = HttpServer.new();
	server.listen(port);
	var state = _rand_string(16);
	http.request("https://accounts.spotify.com/authorize?" + _get_query(state).percent_encode());
	var code;
	while true:
		code = server._get_code();
		if code == null:
			OS.delay_msec(1);
			continue;
		break;
	if code.size() == 0 or code[1] != state:
		http.queue_free();
		http = null;
		server.stop();
		server.queue_free();
		server = null;
		return;
	var headers = [
		"Authorization: Basic " + basic,
		"Content-Type: application/x-www-form-urlencoded"
	]
	var data = "grant_type=authorization_code&code=" + code[0] + "&redirect_uri=http://localhost:" + port + "/";
	var _ignore = http.connect("request_completed", self, "_receive_data");
	_request_state = 0;
	http.request("https://accounts.spotify.com/api/token", headers, true, HTTPClient.METHOD_POST, data.percent_encode());
	while _request_state != -1:
		OS.delay_msec(1);
	http.queue_free();
	http = null;
	server.stop();
	server.queue_free();
	server = null;
	
func _refresh_access_token():
	pass

func _request_song():
	pass

func _receive_data(result, response_code, headers, body):
	if not response_code == 200:
		_request_state = -1;
		return;
	match(_request_state):
		0:
			var code_data = JSON.parse(body.get_string_from_utf8());
			expires = code_data["expires_in"] - 180;
			access_token = code_data["access_token"];
			refresh_token = code_data["refresh_token"];
			_request_state = -1;
			return;
		1:
			pass
		2:
			pass

func _request_song_complete(client, body, headers, code):
	pass

func _update() -> Song:
	update_song = true;
	return song;
	
func _update_api():
	var client_id = Settings.get("SpotifyClientId");
	var client_secret = Settings.get("SpotifyClientSecret");
	var port = Settings.get("SpotifyPort");
	var basic = Marshalls.utf8_to_base64(client_id + ':' + client_secret);
	if self.port == port and self.client_id == client_id and self.basic == basic:
		return;
	self.client_id = client_id;
	self.basic = basic;
	self.port = port;
	
func _on_enable():
	abort = false;
	client = HttpPool.new();
	add_child(client);
	client.connect_to("api.spotify.com", 80, true)
	http = HTTPRequest.new();
	add_child(http);
	var _ignore = client.connect("request_completed", self, "_request_song_complete");
	thread = Thread.new();
	_ignore = thread.start(self, "_execute_task");
	
func _on_disable():
	abort = true;
	var _ignore = thread.wait_to_finish();
	remove_child(client);
	remove_child(http);
	http.queue_free();
	http = null;
	client.queue_free();
	client = null;
