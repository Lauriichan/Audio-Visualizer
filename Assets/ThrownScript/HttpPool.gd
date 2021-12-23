extends Node
class_name HttpPool

enum HttpMethod {
	GET = 0,
	HEAD = 1,
	POST = 2,
	PUT = 3,
	DELETE = 4,
	OPTIONS = 5,
	TRACE = 6,
	CONNECT = 7,
	PATCH = 8,
	MAX = 9
}

signal request_completed(client, body, headers, code)

var clients = [];
var results = [[]];
var client_data = [];
var available = [];

var min_amount : int;
var max_amount : int;

var host : String;
var port : int;
var ssl : bool;

var queue = []

var thread_pool : ThreadPool;

func _ready():
	thread_pool = ThreadPool.new();
	add_child(thread_pool);
	var _ignore = thread_pool.connect("task_discarded", self, "_task_done");
	
func queue_free():
	thread_pool.queue_free();
	remove_child(thread_pool);
	.queue_free();

func client_task(var index : int, var data : Array):
	var client : HTTPClient = clients[index];
	if not client_data[index]:
		client_data[index] = true;
		client.connect_to_host(host, port, ssl, true);
		while !(client.get_status() == HTTPClient.STATUS_CONNECTED or client.get_status() == HTTPClient.STATUS_BODY):
			OS.delay_msec(1);
			client.poll();
	var error = client.request(data[0], data[1], data[2], data[3]);
	if error != OK:
		return;
	while client.get_status() == HTTPClient.STATUS_REQUESTING:
		client.poll();
		OS.delay_msec(1);
	if not client.has_response():
		results[index] = null;
		return;
	var result = [];
	var body = PoolByteArray();
	while client.get_status() == HTTPClient.STATUS_BODY:
		client.poll();
		var chunk = client.read_response_body_chunk();
		if chunk.size() == 0:
			OS.delay_usec(200);
		else:
			body = body + chunk;
	result.append(body);
	result.append(client.get_response_headers_as_dictionary());
	result.append(client.get_response_code());
	results[index] = result;
	

func _task_done(task_tag):
	var res = results[task_tag];
	if res == null:
		emit_signal("request_completed", clients[task_tag], null, null, 0);
	else:
		emit_signal("request_completed", clients[task_tag], res[0], res[1], res[2]);
	if queue.size() == 0:
		available.append(task_tag);
		return;
	__execute(task_tag, queue.pop_front());
		
func _request_client() -> int:
	while clients.size() < min_amount:
		_create_client();
	if available.size() == 0:
		if clients.size() >= max_amount:
			while clients.size() > max_amount:
				clients.pop_back().queue_free();
				client_data.pop_back();
			return -1;
		_create_client();
	return available.pop_front();
	
func _create_client():
	var client = HTTPClient.new();
	clients.append(client);
	client_data.append(false);
	results.append(null);
	available.append(clients.find(client));

func _set_min_clients(var minimum):
	minimum = max(abs(minimum), 1);
	min_amount = min(max_amount, minimum);
	max_amount = max(max_amount, minimum);
	
func _set_max_clients(var maximum):
	maximum = max(abs(maximum), 1);
	max_amount = max(maximum, min_amount);
	min_amount = min(maximum, min_amount);

func _get_max_clients() -> int:
	return max_amount;
	
func _get_min_clients() -> int:
	return min_amount;

func _get_used_clients() -> int:
	return clients.size();
	
func _get_available_clients() -> int:
	return available;

func connect_to(var host : String, var port : int, var ssl : bool):
	if host == self.host and port == self.port:
		return;
	self.host = host;
	self.port = port;
	self.ssl = ssl;
	for i in range(clients.size()):
		client_data[i] = false;
	queue.clear(); # Clear queue because host changed
	
func is_ready() -> bool:
	return available == 0;

func _execute(var id, var method, var url, var headers, var body):
	__execute(id, [method, url, headers, body]);
	
func __execute(var id, var data : Array):
	thread_pool.submit_task_parameterized(self, "client_task", [id, data], id);

func request(var method : int, var url : String, var headers : PoolStringArray, var body : String = "") -> bool:
	if method < 0 or method >= HttpMethod.MAX:
		return false;
	var client_id = _request_client();
	if client_id != -1:
		_execute(client_id, method, url, headers, body);
		return true;
	queue.append([method, url, headers, body]);
	return true;
