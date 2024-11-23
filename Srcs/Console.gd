extends Control

class_name Lisp_Console

@onready var input: CodeEdit = $HBoxContainer/VBoxContainer2/HBoxContainer/InputLine
@onready var console: RichTextLabel = $HBoxContainer/VBoxContainer2/ConsoleLines
@onready var AstView: Tree = $HBoxContainer/VBoxContainer/TabContainer/AstViewer
@onready var EnvView: ItemList = $HBoxContainer/VBoxContainer/TabContainer/Environment

@onready var interpreter: Interpreter = $LispInterpreter

const LineStart: String = "[color=white]repl=>[/color]  "

func newLineConsole() -> void:
	console.append_text("\n")
	console.append_text(LineStart)
	
func _ready() -> void:
	console.text = ""
	console.append_text(LineStart)
	console.append_text("[wave amp=50.0 freq=5.0 connected=1][rainbow freq=1.0 sat=0.8 val=0.8]hello world![/rainbow][/wave]")
	newLineConsole()
	
	#var saveFile := FileAccess.open("res://Save.slisp", FileAccess.READ)
	#interpreter.User_env = bytes_to_var_with_objects(saveFile.get_buffer(saveFile.get_length()))

	env_UpdateItem()
	
func astvis_addnode(parseResult:Variant, parent:TreeItem = null) -> void:
	if parseResult is Array:
		for i: Variant in parseResult:
			if i is Array:
				var root: TreeItem = AstView.create_item()
				root.set_text(1, "[EXP]")
				astvis_addnode(i, root)
			else:
				var newNode := AstView.create_item(parent)
				newNode.set_text(0, str(i))
				newNode.set_text(1, "[ATOM]")
	else:
		pass

func env_UpdateItem()->void:
	EnvView.clear()
	for i:String in interpreter.Standard_env.bindings.keys():
		EnvView.add_item("[" + i + "]" + " : " +\
			str(interpreter.Standard_env.bindings.get(i)))
	for i:String in interpreter.User_env.bindings.keys():
		EnvView.add_item("[" + i + "]" + " : " +\
			str(interpreter.User_env.bindings.get(i)))

func _on_send_button_pressed() -> void:
	console.append_text("[color=yellow]" + input.text + "[/color]")
	newLineConsole()
	
	var parseResult: Variant = interpreter.parse(interpreter.tokenize(input.text))
	AstView.clear()
	var astRoot := AstView.create_item()
	astRoot.set_text(1, "[EXP]")
	astvis_addnode(parseResult, astRoot)
	
	console.append_text("[color=green]" + interpreter.RunCode(input.text) + "[/color]")
	newLineConsole()
	input.text = ""
	
	env_UpdateItem()
	
func print_onConsole(a: String) -> void:
	console.append_text(a)

func _on_clear_button_pressed() -> void:
	console.clear()
	console.append_text(LineStart)
	AstView.clear()


#func _on_save_button_pressed() -> void:
	#var saveFile := FileAccess.open("res://Save.slisp", FileAccess.WRITE)
	#saveFile.store_buffer(var_to_bytes_with_objects(interpreter.User_env))
