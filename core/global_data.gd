extends Node
var my_id: int = 0             
var my_name: String = ""      
var my_color: Color = Color.WHITE

var flag: String = ""

var room_id: String = ""      
var is_host: bool = false      
var room_players: Dictionary = {} 

func reset_room_data():
	room_id = ""
	is_host = false
	room_players.clear()
	
