extends Node2D
var rede_node = null


const ServerScript = preload("res://net/net_server.gd")
const ClienteScript = preload("res://net/net_client.gd")


func _on_botao_servidor_pressed():
	print("Instanciando Servidor...")
	rede_node = ServerScript.new()
	rede_node.name = "Rede"
	add_child(rede_node)
	rede_node.setup_server(8080)
	$BotaoServidor.disabled = true

func _on_botao_cliente_pressed():
	
	#Isso é só um teste, ele cria o cliente várias vezes se eu ficar clicando no botão
	print("Instanciando Cliente...")
	rede_node = ClienteScript.new()
	rede_node.name = "Rede"
	add_child(rede_node)
	
	# Recebe a lista de salas assim que entra no jogo
	rede_node.room_list_updated.connect(func(salas): 
		print("--- CONFIRMAÇÃO DE DADOS ---")
		print("Recebi o sinal! Total de salas: ", salas.size())
		print("Conteúdo bruto: ", salas)
	) 
	
	rede_node.connect_to_server("127.0.0.1", 8080)
	$BotaoCliente.disabled = true
	
	
func _on_botao_criar_sala_pressed():
	print("--- Clique no botão Criar Sala ---")
	
	if rede_node == null:
		print("ERRO: rede_node ainda é NULL. Clique em Iniciar Cliente Primeiro")
		return
		
	if rede_node.has_method("create_room"):
		rede_node.create_room("SALA_TESTE", "Amanda", Color.BLUE, 2, 6)
	else:
		print("ERRO: rede_node existe, mas não tem o método create_room. É um Servidor ou o script deu erro.")
		
