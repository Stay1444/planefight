extends Node2D

const PlaneController = preload("res://assets/prefabs/plane/PlaneController.gd")
var Game: PlaneGame;
var LocalPlaneController: PlaneController;
var respawnManager: RespawnManager;

@export var PlanePrefab: PackedScene;
@export var PlaneExplosionParticles: PackedScene;

func setup(game: PlaneGame):
	Game = game

func net_log(message: String):
	assert(Game != null)
	assert(multiplayer != null)

	var localPlayer = Game.getLocalPlayer();

	var type = "CLIENT";

	if multiplayer.is_server():
		type = "SERVER";

	var prefix = "[%s %s %s]: " % [type, localPlayer.Id, localPlayer.Nickname]

	print("%s %s" % [prefix, message]);


func getPlaneController(playerId: int) -> PlaneController:
	for child in $Planes.get_children():
		if child.name == str(playerId):
			return child as PlaneController;
	return null;

func deletePlaneController(playerId: int) -> void:
	var c = getPlaneController(playerId)
	if c != null: c.queue_free()
func createPlaneController(ownerId: int, planeId: int, planePosition: Vector2) -> void:
	var instance := PlanePrefab.instantiate() as PlaneController

	instance.planeId = planeId;
	instance.ownerId = ownerId;
	instance.name = str(ownerId)
	instance.gameNode = self
	print_debug("Created plane controller %s" % instance.name)
	instance.position = planePosition;
	instance.isLocal = ownerId == Game.LocalId;
	$Planes.add_child(instance)

func _process(delta):
	if respawnManager != null:
		respawnManager.update(delta)

func _ready():
	if multiplayer.is_server():
		respawnManager = RespawnManager.new()
		respawnManager.on_remain_time_completed.connect(_on_respawnmanager_remaining_time_completed)
		respawnManager.add(multiplayer.get_unique_id(), 1)

	Game.on_localplayer_respawned.connect(_on_localplayer_respawned)
	Game.on_localplayer_died.connect(_on_localplayer_died)

	Game.on_remoteplayer_connected.connect(_on_remoteplayer_connected)
	Game.on_remoteplayer_disconnected.connect(_on_remoteplayer_disconnected)
	Game.on_remoteplayer_respawned.connect(_on_remoteplayer_respawned)
	Game.on_remoteplayer_died.connect(_on_remoteplayer_died)

	Game.on_player_killed.connect(_on_player_killed)

func _on_localplayer_respawned(planeId: int, planePosition: Vector2) -> void:
	deletePlaneController(Game.LocalId)
	createPlaneController(Game.LocalId, planeId, planePosition)

func _on_localplayer_died() -> void:
	deletePlaneController(Game.LocalId)

func _on_remoteplayer_connected(remotePlayer: Player) -> void:
	if respawnManager != null && multiplayer.is_server():
		respawnManager.add(remotePlayer.Id, 0.5)
		
		for i in Game.Players:
			if i.Id == remotePlayer.Id: continue
			if getPlaneController(i.Id) != null:
				spawn_network_player(i.Id, remotePlayer.Id)
			rpc("_rpc_player_stats_updated", i.Id, i.KillCount, i.DeathCount)
			
func _on_remoteplayer_disconnected(remotePlayer: Player) -> void:
	deletePlaneController(remotePlayer.Id)

func _on_remoteplayer_died(remotePlayer: Player) -> void:
	deletePlaneController(remotePlayer.Id)

func _on_remoteplayer_respawned(remotePlayer: Player, planeId: int, planePosition: Vector2) -> void:
	deletePlaneController(remotePlayer.Id)
	createPlaneController(remotePlayer.Id, planeId, planePosition)

func _on_player_killed(killer: Player, victim: Player) -> void:
	print_debug("%s killed %s" % [killer.Nickname, victim.Nickname])

func respawn_network_player(id: int, targetId: int = -1) -> void:
	assert(multiplayer.is_server())
	var instance = PlanePrefab.instantiate()
	var planeId = instance.getRandomPlaneId()
	instance.queue_free();

	var targetPosition = Vector2.ZERO;
	
	var spawnPointCount = $SpawnPoints.get_children().size();
	targetPosition = $SpawnPoints.get_child(randi_range(0, spawnPointCount - 1)).global_position

	if targetId != -1:
		rpc_id(targetId, "_rpc_player_respawned", id, planeId, targetPosition)
	else:
		rpc("_rpc_player_respawned", id, planeId, targetPosition)

func spawn_network_player(id: int, targetId: int = -1) -> void:
	assert(multiplayer.is_server())
	var controller = getPlaneController(id);
	if targetId != -1:
		rpc_id(targetId, "_rpc_player_respawned", id, controller.planeId, controller.position)
	else:
		rpc("_rpc_player_respawned", id, controller.planeId, controller.position)

func _on_respawnmanager_remaining_time_completed(id: int) -> void:
	assert(multiplayer.is_server())
	print_debug("RespawnManager time completed: %s" % id)
	deletePlaneController(id)
	
	respawn_network_player(id)

@rpc("authority", "call_local")
func _rpc_player_respawned(id: int, planeId: int, planePosition: Vector2):
	if id == Game.LocalId:
		Game.on_localplayer_respawned.emit(planeId, planePosition)
	else:
		Game.on_remoteplayer_respawned.emit(Game.getPlayer(id), planeId, planePosition)
	
@rpc("authority", "call_local")
func _rpc_plane_hit(shooterId: int, receiverId: int, damage: float):
	var receiver := Game.getPlayer(receiverId);

	var receiverController := getPlaneController(receiverId);

	if receiverController == null: return

	var oldHealth = receiverController.health;
	receiverController.health -= damage;
	
	if receiverController.health < 0:
		receiverController.health = 0
	
	Game.on_player_health_changed.emit(receiver, oldHealth, receiverController.health)

	if receiverController.health == 0 && multiplayer.is_server():
		rpc("_rpc_plane_killed", shooterId, receiverId)

@rpc("authority", "call_local")
func _rpc_plane_killed(killerId: int, victimId: int):
	var killer := Game.getPlayer(killerId);
	var victim := Game.getPlayer(victimId);

	var victimController = getPlaneController(victimId)

	Game.on_player_killed.emit(killer, victim)

	if victimId == Game.LocalId:
		Game.on_localplayer_died.emit()
	else:
		Game.on_remoteplayer_died.emit(victim)

	rpc("_rpc_plane_explode", victimController.global_position)

	if multiplayer.is_server():
		respawnManager.add(victimId)
		killer.KillCount += 1
		victim.DeathCount += 1
		rpc("_rpc_player_stats_updated", killerId, killer.KillCount, killer.DeathCount)
		rpc("_rpc_player_stats_updated", victimId, victim.KillCount, victim.DeathCount)

@rpc("authority", "call_local")
func _rpc_plane_died(planeId: int):
	if multiplayer.is_server():
		respawnManager.add(planeId)

	if planeId == Game.LocalId:
		Game.on_localplayer_died.emit()
	else:
		Game.on_remoteplayer_died.emit(Game.getPlayer(planeId))
	
@rpc("authority", "call_local")
func _rpc_plane_explode(explosionPosition: Vector2):
	var explosionParticles = PlaneExplosionParticles.instantiate() as CPUParticles2D;
	explosionParticles.global_position = explosionPosition
	add_child(explosionParticles)

@rpc("authority", "call_local")
func _rpc_player_stats_updated(playerId: int, killCount: int, deathCount: int) -> void:
	var player := Game.getPlayer(playerId)

	if player == null: return

	player.KillCount = killCount;
	player.DeathCount = deathCount;

	Game.on_player_stats_changed.emit(player)
