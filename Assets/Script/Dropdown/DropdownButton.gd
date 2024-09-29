extends MenuButton
class_name DropdownButton

@export var itemList : PackedStringArray: set = _set_item_list
@export var selected : String: set = _set_selected
	
func _set_item_list(value):
	itemList = value;
	_update_item_list();

func _get_selected() -> String:
	return selected;

func _set_selected(value):
	var idx = itemList.find(value);
	if idx == -1:
		selected = "";
		return;
	if selected != "":
		var sid = itemList.find(selected);
		if sid != -1:
			get_popup().set_item_checked(sid, false);
	selected = value;
	get_popup().set_item_checked(idx, true);
	
func _update_item_list():
	var popup : PopupMenu = get_popup();
	popup.clear();
	for item in itemList:
		popup.add_check_item(item);
	_set_selected(selected);

func _ready():
	_update_item_list();
	var _ignore = get_popup().connect("id_pressed", Callable(self, "_item_pressed"));
	
func _update():
	pass

func _item_pressed(id):
	_set_selected(itemList[id]);
