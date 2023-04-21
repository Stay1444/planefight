extends CanvasLayer

@export var IPBox: TextEdit;
@export var NicknameBox: TextEdit;

const playNodeType = preload("res://play.gd")

func setup(node: playNodeType):
	on_menu_host_game_requested.connect(node._on_menu_ui_on_menu_host_game_requested)
	on_menu_join_game_requested.connect(node._on_menu_ui_on_menu_join_game_requested)

func is_nickname_valid() -> bool:
	return NicknameBox.text != "" && NicknameBox.text != null

func is_ip_valid() -> bool:
	return IPBox.text != "" && NicknameBox.text != null

signal on_menu_join_game_requested(address: IPAddress, nickname: String)
signal on_menu_host_game_requested(address: IPAddress, nickname: String)

func _on_join_button_pressed():
	if not is_nickname_valid() or not is_ip_valid():
		return
	
	var address := IPAddress.parse(IPBox.text)
	on_menu_join_game_requested.emit(address, NicknameBox.text)

func _on_host_button_pressed():
	if not is_ip_valid() or not is_nickname_valid():
		return
	
	var address := IPAddress.parse(IPBox.text)
	on_menu_host_game_requested.emit(address, NicknameBox.text)
