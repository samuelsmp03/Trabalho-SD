extends Node

@export var board_view: Control
var board_logic: BoardState

var local_player_id: int
var current_turn_id: int
var player_scores: Dictionary = {}

func _ready() -> void:
	local_player_id = multiplayer.get_unique_id()
	
	var size = 5 
	board_logic = BoardState.new(size, size)
	
	board_view.setup_view(size, size, board_logic)
	board_view.line_clicked.connect(_on_player_attempt_move)
	
	current_turn_id = 1 


func _on_player_attempt_move(type: String, x: int, y: int) -> void:
	if multiplayer.get_unique_id() != current_turn_id:
		print("Não é o seu turno!")
		return
	
	if board_logic.is_move_legal(type, x, y):

		rpc_id(1, "request_move", type, x, y)


@rpc("any_peer", "call_remote", "reliable")
func request_move(type: String, x: int, y: int) -> void:
	if multiplayer.is_server():
		rpc("execute_move", type, x, y, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_local", "reliable")
func execute_move(type: String, x: int, y: int, sender_id: int) -> void:
	var closed_boxes = board_logic.apply_move(type, x, y, sender_id)
	
	var p_color = _get_player_color(sender_id)
	board_view.update_line_visual(type, x, y, p_color)
	
	if closed_boxes.size() > 0:
		for box_coord in closed_boxes:
			board_view.spawn_box(box_coord.x, box_coord.y, p_color)
		
		_update_score(sender_id, closed_boxes.size())
	else:
		_switch_turn()


func _switch_turn() -> void:

	if current_turn_id == 1:
		current_turn_id = _get_opponent_id()
	else:
		current_turn_id = 1
	print("Turno do jogador: ", current_turn_id)

func _update_score(p_id: int, points: int) -> void:
	if not player_scores.has(p_id):
		player_scores[p_id] = 0
	player_scores[p_id] += points

	print("Jogador ", p_id, " fez ", points, " ponto(s). Total: ", player_scores[p_id])

func _get_player_color(p_id: int) -> Color:

	return Color.RED if p_id == 1 else Color.BLUE

func _get_opponent_id() -> int:
	return 0 
