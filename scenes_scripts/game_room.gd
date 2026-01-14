extends Node

@export var board_view: Control
@onready var label_turno: Label = $MarginContainer/VBoxContainer/TurnIndicator

@onready var ClientLogic: Node = get_node("/root/ClientLogic")

const DEFAULT_COLOR_HEX := "#FFFFFF"
const TURN_COLOR_MY_TURN := Color.GREEN
const TURN_COLOR_OTHER := Color.WHITE

var board_logic: BoardState
var player_scores: Dictionary = {} # { player_id: int: score: int }

func _ready() -> void:
	var size: int = Global.board_size
	board_logic = BoardState.new(size, size)

	if board_view:
		board_view.setup_view(size, size, board_logic)
		board_view.line_clicked.connect(_on_line_clicked_in_view)

	ClientLogic.move_received.connect(_on_move_received_from_server)
	ClientLogic.send_room_state_changed_to_UI.connect(_on_room_data_updated)
	ClientLogic.game_over.connect(_on_game_over)

	_initialize_scores()
	_update_ui_display()

	print("[GAME] Sala pronta. Meu ID: ", Global.my_id)


func _on_line_clicked_in_view(line_type: String, x: int, y: int) -> void:
	if not ClientLogic.is_my_turn():
		print("Aguarde! É a vez do jogador: ", Global.current_turn_player_id)
		return

	if not board_logic.is_move_legal(line_type, x, y):
		return

	var scored: bool = _predict_if_move_scores(line_type, x, y)
	ClientLogic.make_move(line_type, x, y, scored)


func _on_move_received_from_server(move_data: Dictionary) -> void:
	var line_type: String = str(move_data.get("move_type", "h")).to_lower()
	var x: int = int(move_data.get("pos_x", 0))
	var y: int = int(move_data.get("pos_y", 0))
	var author_id: int = int(move_data.get("author_id", -1))

	var closed_boxes: Array = board_logic.apply_move(line_type, x, y, author_id)
	var color: Color = _get_player_color(author_id)

	if board_view:

		board_view.update_line_visual(line_type, x, y, color)

		if closed_boxes.size() > 0:
			for box_coord in closed_boxes:
				board_view.spawn_box(box_coord.x, box_coord.y, color)

	if closed_boxes.size() > 0:
		_add_points(author_id, closed_boxes.size())

	_update_ui_display()
	
	if _is_game_finished():
		var ranking := _build_ranking()
		var winner_id := int(ranking[0]["id"]) if ranking.size() > 0 else -1
		print("[CLIENT] jogo finalizado, enviando request_game_over")
		ClientLogic.request_game_over(ranking, winner_id)


func _on_room_data_updated(_data: Dictionary) -> void:
	_update_ui_display()


func _initialize_scores() -> void:
	for p_id in Global.room_players.keys():
		player_scores[int(p_id)] = 0


func _add_points(p_id: int, points: int) -> void:
	player_scores[p_id] = int(player_scores.get(p_id, 0)) + points


func _update_ui_display() -> void:
	if label_turno:
		var current_id: int = Global.current_turn_player_id
		var p_name: String = "Desconhecido"

		if Global.room_players.has(current_id):
			p_name = str(Global.room_players[current_id].get("name", "Sem Nome"))

		var turn_color: Color = _get_player_color(current_id)

		if ClientLogic.is_my_turn():
			label_turno.text = "Sua vez!"
			label_turno.modulate = turn_color   
		else:
			label_turno.text = "Vez de: " + p_name
			label_turno.modulate = turn_color   



func _get_player_color(p_id: int) -> Color:
	if not Global.room_players.has(p_id):
		return Color(DEFAULT_COLOR_HEX)

	var hex: String = str(Global.room_players[p_id].get("color", DEFAULT_COLOR_HEX))
	if not hex.begins_with("#"):
		hex = "#" + hex

	return Color(hex)


func _predict_if_move_scores(tipo: String, x: int, y: int) -> bool:
	# Previsão local: se fecha quadrado
	if tipo == "h":
		return _will_box_complete(x, y - 1) or _will_box_complete(x, y)

	return _will_box_complete(x - 1, y) or _will_box_complete(x, y)


func _will_box_complete(bx: int, by: int) -> bool:
	if bx < 0 or bx >= board_logic.width - 1:
		return false
	if by < 0 or by >= board_logic.height - 1:
		return false
	if board_logic.boxes[bx][by] != 0:
		return false

	var count: int = 0
	if board_logic.h_lines[bx][by] != 0: count += 1
	if board_logic.h_lines[bx][by + 1] != 0: count += 1
	if board_logic.v_lines[bx][by] != 0: count += 1
	if board_logic.v_lines[bx + 1][by] != 0: count += 1

	return count == 3

func _is_game_finished() -> bool:
	for x in range(board_logic.width - 1):
		for y in range(board_logic.height - 1):
			if board_logic.boxes[x][y] == 0:
				return false
	return true

func _build_ranking() -> Array:
	var ranking: Array = []
	for p_id in player_scores.keys():
		var id := int(p_id)
		ranking.append({
			"id": id,
			"name": str(Global.room_players[id].get("name", "Jogador")),
			"score": int(player_scores[id])
		})

	ranking.sort_custom(func(a, b): return int(a["score"]) > int(b["score"]))
	return ranking

func _on_game_over(payload: Dictionary) -> void:
	Global.last_game_result = payload
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")
