#Inicializa servidor e clientes
extends Node

func _ready():
	# Cria uma instância de Servidor
	if "--server" in OS.get_cmdline_args():
		print("[MAIN] Iniciando Servidor")
		NetworkManager.start_dedicated_server(8080)
	else:
		print("[MAIN] Indo para main menu")
		get_tree().call_deferred("change_scene_to_file", "res://scenes/MainMenu.tscn")
