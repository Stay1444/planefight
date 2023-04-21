extends PanelContainer

const playNode = preload("res://play.gd")

@export var KillMessagePrefab: PackedScene;
@export var TextMessagePrefab: PackedScene;

func setup(node: playNode) -> void:
	node.entered_game.connect(_on_entered_game)
	node.exited_game.connect(_on_exited_game)

func _on_entered_game(game: PlaneGame):
	game.on_player_killed.connect(_on_player_killed)
	game.on_remoteplayer_connected.connect(_on_remoteplayer_connected)
	game.on_remoteplayer_disconnected.connect(_on_remoteplayer_disconnected)

func _on_exited_game(game: PlaneGame):
	game.on_player_killed.disconnect(_on_player_killed)
	game.on_remoteplayer_connected.disconnect(_on_remoteplayer_connected)
	game.on_remoteplayer_disconnected.disconnect(_on_remoteplayer_disconnected)

func _on_player_killed(killer: Player, victim: Player) -> void:
	var instance = KillMessagePrefab.instantiate()
	instance.set_data(killer.Nickname, victim.Nickname)
	$VBoxContainer.add_child(instance)

func _on_remoteplayer_connected(player: Player) -> void:
	var instance = TextMessagePrefab.instantiate()
	instance.set_data("%s connected" % player.Nickname)
	$VBoxContainer.add_child(instance)

func _on_remoteplayer_disconnected(player: Player) -> void:
	var instance = TextMessagePrefab.instantiate()
	instance.set_data("%s disconnected" % player.Nickname)
	$VBoxContainer.add_child(instance)
