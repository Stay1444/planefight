extends Control

@export var BarNode: ColorRect

const playNodeType = preload("res://play.gd")

var barNodeMaxWidth: float;
var maxHealth: float = -1;

func setup(node: playNodeType):
	node.entered_game.connect(_on_play_entered_game)
	node.exited_game.connect(_on_play_exited_game)
	

func _ready():
	barNodeMaxWidth = BarNode.size.x

func _on_play_entered_game(game):
	game.on_player_health_changed.connect(_on_player_health_changed)
	game.on_localplayer_respawned.connect(_on_localplayer_respawned)

func _on_play_exited_game(game):
	game.on_player_health_changed.disconnect(_on_player_health_changed)
	game.on_localplayer_respawned.disconnect(_on_localplayer_respawned)

func calculate_new_width(health: float) -> float:
	var healthRatio := health / maxHealth

	return barNodeMaxWidth * healthRatio
func _on_player_health_changed(player: Player, old: float, new: float) -> void:
	if player.IsRemote: return

	if maxHealth == -1:
		maxHealth = old # Maybe a dirty cheat. The first time that the health changes we save the old value to get the maximum health.
	BarNode.size.x = calculate_new_width(new)
	
func _on_localplayer_respawned(_i: int, _p: Vector2):
	BarNode.size.x = barNodeMaxWidth;
