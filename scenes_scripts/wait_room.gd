extends TextureRect

@onready var room_code_label = $MarginContainer/VBoxContainer/codSala
func _ready():
	room_code_label.text = "Código da sua sala: %s" % Global.my_id
