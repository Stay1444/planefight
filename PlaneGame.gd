extends Node
class_name PlaneGame

signal on_localplayer_died
signal on_localplayer_respawned(planeId: int, planePosition: Vector2)

signal on_remoteplayer_connected(remotePlayer: Player)
signal on_remoteplayer_disconnected(remotePlayer: Player)
signal on_remoteplayer_died(remotePlayer: Player)
signal on_remoteplayer_respawned(remotePlayer: Player, planeId: int, planePosition: Vector2)

signal on_player_killed(killer: Player, victim: Player)
signal on_player_health_changed(player: Player, old: float, new: float)
signal on_player_stats_changed(player: Player)

var IsServer: bool;
var LocalId: int; 

var Players: Array[Player];

func _init(localId: int, isServer: bool) -> void:
	super()
	IsServer = isServer;
	LocalId = localId;

func getPlayer(id: int) -> Player:
	for i in Players.size():
		var player := Players[i]
		if player.Id == id:
			return player
	return null

func getPlayerIndex(id: int) -> int:
	for i in Players.size():
		var player := Players[i]

		if player.Id == id:
			return i
	return -1

func getLocalPlayer() -> Player:
	return getPlayer(LocalId) 	# Probably should cache the local player to skip
								# this constant iteration, but it won't make a difference since
								# the max players is 32
