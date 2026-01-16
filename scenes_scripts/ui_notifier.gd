extends CanvasLayer  

#Componente de UI Global
# Escuta os eventos vindos do Global (que também possui um message Bus)
# O UI Notifier vai mostrar mensagems para o usuário em Accept Dialogs
# A mensagem aparece apenas uma vez e depois adicionamos tratamentos simples após o OK


@onready var global := get_node("/root/Global")
@onready var dialog: AcceptDialog = $ErrorDialog

const Messages = preload("res://domain/messages.gd")

var _showing := false   #evita abrir dois diálogos ao mesmo tempo
var _current_event: Dictionary = {}  #guarda o evento que está sendo exibido no momento

func _ready():
	global.ui_event_pushed.connect(_try_show_next)

	# conecta sinais de fechamento no mesmo HANDLER 
	if not dialog.confirmed.is_connected(_on_dialog_closed):
		dialog.confirmed.connect(_on_dialog_closed)  # fechado por "ok"
	if not dialog.close_requested.is_connected(_on_dialog_closed):
		dialog.close_requested.connect(_on_dialog_closed) # fechado por "x"

	_try_show_next({})  

func _try_show_next(_ev := {}) -> void:  #tenta mostrar a próxima mensagem da fila
	if _showing: # se já tiver mostrando
		return
	if not global.has_ui_event(): #se não tem evento na fila
		return

	_current_event = global.pop_ui_event()
	if _current_event.is_empty(): #se evento está vazio
		return

	_showing = true  #se chegou aqui, tudo está ok e pode mostrar a mensagem
	dialog.title = "Aviso"
	dialog.dialog_text = str(_current_event.get("message", ""))
	dialog.popup_centered()

func _on_dialog_closed() -> void: 
	_showing = false
	_handle_event(_current_event) #vai para o tratamento de erro
	_current_event = {}
	_try_show_next({})

func _handle_event(ev: Dictionary) -> void:
	var code := str(ev.get("code", ""))

	match code:
		Messages.EVT_CONNECTION_ESTABLISH_FAILED:
			print("[UI] Mostrando mensagem de falha na conexão") # Podemos adicionar algo pra ser feito após isso
			pass
		Messages.EVT_CONNECTION_LOST: 
			print("[UI] Mostrando mensagem de perda de conexão") # 
			pass
		_:
			print("[UI] Evento desconhecido: ", code)
