extends Node2D

signal entered_game(game: PlaneGame)
signal exited_game(game: PlaneGame)

@export var UIScenePrefab: PackedScene;
@export var GameScenePrefab: PackedScene;

var gameNode: Node2D;
var uiNode: CanvasLayer;

var game: PlaneGame = null;

func net_log(message: String):

	assert(game != null)
	assert(multiplayer != null)

	var localPlayer = game.getLocalPlayer();

	var type = "CLIENT";

	if multiplayer.is_server():
		type = "SERVER";

	var prefix = "[%s %s %s]: " % [type, localPlayer.Id, localPlayer.Nickname]

	print("%s %s" % [prefix, message]);

func is_dedicated() -> bool:
	return OS.has_feature("dedicated_server")
	
# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().paused = true
	
	if is_dedicated():
		assert(false)
	else:
		initialize_game()

const uiType := preload("res://assets/ui/UIManager.gd")
const gameType := preload("res://assets/scenes/game/Game.gd")

func initialize_game():
	var uiInstance := UIScenePrefab.instantiate() as uiType
	uiInstance.setup(self)
	uiNode = uiInstance
	add_child(uiInstance)

func _on_menu_ui_on_menu_host_game_requested(address: IPAddress, nickname: String):
	var peer := ENetMultiplayerPeer.new()

	if address.Port == null || address.Port == -1:
		address.Port = 5012;

	peer.create_server(address.Port)
	multiplayer.multiplayer_peer = peer;

	game = PlaneGame.new(peer.get_unique_id(), true) # Create game
	var localPlayer := Player.new(peer.get_unique_id(), false, nickname)
	game.Players.append(localPlayer)
	# Connect events
	peer.peer_connected.connect(_on_peer_connected_to_server)
	peer.peer_disconnected.connect(_on_peer_disconnected_from_server)

	gameNode = GameScenePrefab.instantiate() as gameType
	gameNode.setup(game)

	add_child(gameNode)

	entered_game.emit(game)

	get_tree().paused = false

func _on_menu_ui_on_menu_join_game_requested(address: IPAddress, nickname: String):

	var peer := ENetMultiplayerPeer.new()

	if address.Port == null || address.Port == -1:
		address.Port = 5012

	peer.create_client(address.Address, address.Port)

	multiplayer.multiplayer_peer = peer;

	game = PlaneGame.new(peer.get_unique_id(), false)
	var localPlayer := Player.new(peer.get_unique_id(), false, nickname)
	game.Players.append(localPlayer)

	gameNode = GameScenePrefab.instantiate() as gameType
	gameNode.setup(game)
	
	add_child(gameNode)

	entered_game.emit(game)

	multiplayer.connected_to_server.connect(_on_peer_connected_successfully)

	get_tree().paused = false

func _on_peer_connected_to_server(id: int):
	if !multiplayer.is_server():
		return
	
	net_log("Player %s connected to server" % id)

func _on_peer_disconnected_from_server(id: int):
	if !multiplayer.is_server():
		return
		
	net_log("Player %s disconnected from server" % id)

	rpc("_rpc_unregister_player", id) # This should also call the local _rpc_unregister_player function

func _on_peer_connected_successfully():
	net_log("Connected to server")
	rpc("_rpc_player_ready", game.getLocalPlayer().Nickname)

@rpc("any_peer")
func _rpc_player_ready(nickname: String):
	assert(multiplayer.is_server())

	var id := multiplayer.get_remote_sender_id()
	net_log("Player %s %s ready" % [id, nickname])
	var player := Player.new(id, true, nickname);

	for i in game.Players.size():
		var otherPlayer := game.Players[i]

		rpc_id(otherPlayer.Id, "_rpc_register_player", player.Id, player.Nickname)
		rpc_id(player.Id, "_rpc_register_player", otherPlayer.Id, otherPlayer.Nickname)

	game.Players.append(player)

	game.on_remoteplayer_connected.emit(player)

@rpc("authority")
func _rpc_register_player(id: int, nickname: String):
	var player := Player.new(id, true, nickname)
	net_log("Registering player %s %s" % [id, nickname])
	game.Players.append(player)
	game.on_remoteplayer_connected.emit(player)

@rpc("authority", "call_local")
func _rpc_unregister_player(id: int):
	var player := game.getPlayer(id)

	if player == null:
		push_warning("Server sent unregister message for a player that was not registered! %s" % id)
		return
	
	net_log("Unregistering player %s %s" % [id, player.Nickname])

	game.on_remoteplayer_disconnected.emit(player)
	
	game.Players.remove_at(game.getPlayerIndex(player.Id))
