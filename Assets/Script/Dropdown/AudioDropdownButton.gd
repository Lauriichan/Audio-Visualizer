extends DropdownButton
class_name AudioDropdownButton

var time : float;

func _physics_process(delta):
	time += delta;
	if time < 1:
		return;
	time -= 1;
	_update_device();

func _update_device():
	var devices = AudioServer.capture_get_device_list();
	for device in devices:
		if itemList.has(device):
			continue;
		itemList = devices;
		_update_item_list();
		break;

func _ready():
	_update_device();
	_set_selected("Default");
