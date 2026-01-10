extends Control

@onready var name_input = $MarginContainer/VBoxContainer/NameBox/LineEdit
@onready var color_grid = $MarginContainer/VBoxContainer/GridContainer
@onready var ok_button = $MarginContainer/VBoxContainer/MarginContainer/okButton

var selected_color: Color = Color.WHITE
var color_selected: bool = false 

func _ready():
	for button in color_grid.get_children():
		if button is Button:
			button.pressed.connect(_on_color_selected.bind(button.modulate))
	
	ok_button.pressed.connect(_on_ok_pressed)

func _on_color_selected(color: Color):
	selected_color = color
	color_selected = true 
	ok_button.modulate = color
	print("Cor selecionada confirmada: ", color)

func _on_ok_pressed():
	var p_name = name_input.text.strip_edges()
	
	if p_name.length() < 3:
		_shake_node(name_input)
		print("Erro: Nome muito curto!")
		return
		
	if not color_selected:
		print("Erro: Escolha uma cor antes de continuar!")
		return
	
	Global.my_name = p_name
	Global.my_color = selected_color
	
	if Global.flag == "criar":
		get_tree().call_deferred("change_scene_to_file", "res://Scenes/WaitRoom.tscn")
	else:
		get_tree().call_deferred("change_scene_to_file", "res://Scenes/LobbyRoom.tscn")


func _shake_node(node):
	var tween = create_tween()
	tween.tween_property(node, "position:x", node.position.x + 10, 0.05)
	tween.tween_property(node, "position:x", node.position.x - 10, 0.05)
	tween.set_loops(2)
