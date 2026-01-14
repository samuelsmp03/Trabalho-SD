extends Control

@onready var ranking_container: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/RankingContainer
@onready var exit_button: Button = $MarginContainer/VBoxContainer/Button

const EMPTY_TEXT := "Nenhum ranking disponível"

func _ready() -> void:

	exit_button.pressed.connect(_on_exit_pressed)

	var payload: Dictionary = Global.last_game_result
	var ranking: Array = payload.get("ranking", [])

	
	
	_update_ranking(ranking)

func _update_ranking(ranking: Array) -> void:
	# limpa
	for c in ranking_container.get_children():
		c.queue_free()

	if ranking.is_empty():
		_add_line(EMPTY_TEXT)
		return

	# ordena por score desc
	ranking.sort_custom(func(a, b):
		return int(a.get("score", 0)) > int(b.get("score", 0))
	)

	for i in range(ranking.size()):
		var row: Dictionary = ranking[i]
		var p_name: String = str(row.get("name", "Jogador"))
		var score: int = int(row.get("score", 0))
		_add_line("%dº  %s  -  %d" % [i + 1, p_name, score])
		


func _add_line(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	lbl.add_theme_color_override("font_color", Color.BLACK)
	lbl.add_theme_font_size_override("font_size", 28)
	
	ranking_container.add_child(lbl)




func _on_exit_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn") 
