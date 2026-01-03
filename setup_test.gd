extends Node2D

var server_node: Node = null
var client_node: Node = null

const ServerScript = preload("res://net/net_server.gd")
const ClienteScript = preload("res://net/net_client.gd")

func _on_botao_servidor_pressed():
	print("Instanciando Servidor...")

	if server_node != null:
		print("Servidor já existe.")
		return

	server_node = ServerScript.new()
	server_node.name = "ServidorRede"
	add_child(server_node)

	# Novo nome (com underscore)
	if server_node.has_method("_setup_server"):
		server_node._setup_server(8080)
	else:
		print("ERRO: servidor não tem método _setup_server")

	$BotaoServidor.disabled = true


func _on_botao_cliente_pressed():
	print("Instanciando Cliente...")

	if client_node != null:
		print("Cliente já existe.")
		return

	client_node = ClienteScript.new()
	client_node.name = "ClienteRede"
	add_child(client_node)

	# Conecta o sinal antes de conectar no servidor
	if client_node.has_signal("room_list_updated"):
		client_node.room_list_updated.connect(func(salas):
			print("--- CONFIRMAÇÃO DE DADOS ---")
			print("Recebi o sinal! Total de salas: ", salas.size())
			print("Conteúdo bruto: ", salas)
		)
	else:
		print("ERRO: client_node não tem sinal room_list_updated")

	# Novo nome (com underscore)
	if client_node.has_method("_connect_to_server"):
		client_node._connect_to_server("127.0.0.1", 8080)
	else:
		print("ERRO: cliente não tem método _connect_to_server")

	$BotaoCliente.disabled = true


func _on_botao_criar_sala_pressed():
	print("--- Clique no botão Criar Sala ---")

	if client_node == null:
		print("ERRO: client_node ainda é NULL. Clique em Iniciar Cliente Primeiro")
		return


	if client_node.has_method("_create_room"):
		client_node._create_room("SALA_TESTE", "Amanda", Color.BLUE, 2, 6)
	else:
		print("ERRO: client_node existe, mas não tem o método _create_room")
