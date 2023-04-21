extends Node2D

@export var Speed: float = 300;
@export var Damage: float = 15;
@export var HitParticles: PackedScene;

@export_category("Multiplayer")
@export var PositionThreshold: float = 55;

var LastPositionUpdate: Vector2;

var parentBody: Node2D
var shooterId: int;
var bulletId: int = 0;

const PlaneController = preload("res://assets/prefabs/plane/PlaneController.gd")

var gameNode: Node2D;

# Called when the node enters the scene tree for the first time.
func _ready():
	var parent = get_parent();
	
	while parent.name != "Game":
		parent = parent.get_parent();
	
	gameNode = parent;


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if multiplayer.is_server():
		if position.distance_to(LastPositionUpdate) > PositionThreshold:
			LastPositionUpdate = position
			rpc("_rpc_update_bullet_position", bulletId, position, rotation_degrees)

	position += transform.x * Speed * delta;

@rpc("authority")
func _rpc_update_bullet_position(id: int, tpos: Vector2, rangle: float) -> void:
	if id != bulletId: return
	position = tpos
	rotation_degrees = rangle

@rpc("authority", "call_local")
func _rpc_bullet_delete(id: int):
	if id != bulletId: return
	queue_free()

func _on_timer_timeout():
	queue_free()

@rpc("call_local")
func _rpc_bullet_particles(tpos: Vector2, trot: float):
	var particles := HitParticles.instantiate() as CPUParticles2D;
	particles.global_position = tpos
	particles.global_rotation = trot
	particles.emitting = true
	get_parent().add_child(particles)

func _on_area_2d_area_entered(area):
	if area.get_parent() == parentBody:
		return
	
	if multiplayer.is_server():
		rpc("_rpc_bullet_delete", bulletId)
	
		if area.get_parent() is PlaneController:
			var controller = area.get_parent() as PlaneController;
			gameNode.rpc("_rpc_plane_hit", shooterId, controller.ownerId, Damage)
			rpc("_rpc_bullet_particles", global_position, controller.global_position.angle_to(global_position))
