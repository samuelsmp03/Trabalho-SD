extends TextureRect



@onready var code_input: LineEdit = $MarginContainer/HBoxContainer/codeRoom
func _on_ok_button_pressed() -> void:
	var text: String = code_input.text
	print("Texto digitado: " + text)
