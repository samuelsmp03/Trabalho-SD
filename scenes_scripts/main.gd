extends Node

var server_node: Node = null
var client_node: Node = null

const NetServerScript = preload("res://net/net_server.gd")
const NetClientScript = preload("res://net/net_client.gd")

func _ready():
	if "--server" in OS.get_cmdline_args():
		_start_as_server()
	else:
		_start_as_client()

func _start_as_server():
	print("Iniciando modo Servidor Dedicado...")
	
	server_node = NetServerScript.new()
	
	server_node.name = "NetClient" 
	
	get_tree().root.call_deferred("add_child", server_node)
	
	server_node.call_deferred("_setup_server", 8080)

func _start_as_client():
	print("Instanciando Cliente...")
	if has_node("/root/NetClient"):
		client_node = get_node("/root/NetClient")
	else:
		client_node = NetClientScript.new()
		client_node.name = "NetClient"
		get_tree().root.call_deferred("add_child", client_node)
	
	client_node.call_deferred("_connect_to_server", "127.0.0.1", 8080)
	get_tree().call_deferred("change_scene_to_file", "res://scenes/Lobby.tscn")
