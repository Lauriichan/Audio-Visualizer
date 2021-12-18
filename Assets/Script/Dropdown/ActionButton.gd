extends Button

export(String) var action;

onready var eval_script = GDScript.new();
onready var eval_node = Node.new();

func _set_action(var value):
	action = value;
	_update_action();

func _update_action():
	var tmpAction = action;
	if tmpAction.empty():
		tmpAction = "pass";
	eval_script.set_source_code("extends Node\nfunc eval():\n\t" + tmpAction);
	eval_script.reload();
	eval_node.set_script(eval_script);

func _ready():
	var _ignore = connect("pressed", self, "_action");
	_update_action();

func _action():
	add_child(eval_node);
	eval_node.eval();
	remove_child(eval_node);
