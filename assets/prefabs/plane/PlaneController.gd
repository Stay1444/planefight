extends CharacterBody2D

@export var speed: float = 300;
@export var turnRate: float = 0.1;
@export var spriteRenderer: AnimatedSprite2D;
@export var bulletSpawnPoint: Node2D;
@export var shootCooldown: Timer;
@export var bulletPrefab: PackedScene;
@export var health: float = 500;

@export_category("Multiplayer")
@export var AngleUpdateThreshold: float = 15;
@export var PositionUpdateThreshold: float = 5;

var maxHealth = health;
var planeId = -1;
var ownerId: int = -1;
var isLocal: bool = false;
var bulletsShot = 0;
var lastSentRotation: float;
var lastSentPosition: Vector2;
var insideScreen: bool = true;
var gameNode: Node2D;
@export var EnemyColor: Color;
@export var AllyColor: Color;

const PlaneController = preload("res://assets/prefabs/plane/PlaneController.gd")

func getRandomPlaneId() -> int:
	return randi() % spriteRenderer.sprite_frames.get_frame_count("default");
func _ready():
	$Plane/PlaneSprite.material = $Plane/PlaneSprite.material.duplicate()
	if isLocal:
		$Plane/PlaneSprite.material.set("shader_param/line_color", AllyColor)
	else:
		$Plane/PlaneSprite.material.set("shader_param/line_color", EnemyColor)

	if planeId == -1:
		planeId = getRandomPlaneId()
	
	spriteRenderer.frame = planeId;

func shoot() -> void:
	shootCooldown.stop()
	shootCooldown.start(0)
	var instance := bulletPrefab.instantiate();
	instance.Speed = instance.Speed + speed
	instance.rotation_degrees = $Plane.rotation_degrees
	instance.parentBody = self
	instance.shooterId = ownerId
	instance.name = "%s-bullet-%s" % [ownerId, bulletsShot]
	instance.bulletId = bulletsShot;
	bulletsShot += 1
	instance.position = bulletSpawnPoint.global_position
	get_parent().add_child(instance)

func can_shoot() -> bool:
	return shootCooldown.is_stopped()

func _physics_process(_delta):
	if (isLocal):
		rotate_plane()

		if abs($Plane.rotation_degrees - lastSentRotation) > AngleUpdateThreshold:
			rpc("_rpc_plane_update_rotation", $Plane.rotation_degrees)
			lastSentRotation = $Plane.rotation_degrees;

		if position.distance_to(lastSentPosition) > PositionUpdateThreshold:
			rpc("_rpc_plane_update_position", position)
			lastSentPosition = position

		handle_shoot()

	move_plane()

func rotate_plane():

	var lerpTarget = get_global_mouse_position();

	if not insideScreen:
		lerpTarget = get_viewport_rect().get_center();

	if !Input.is_action_pressed("Aim"):
		$Plane.rotation = lerp_angle($Plane.rotation, (lerpTarget - $Plane.global_position).normalized().angle(), turnRate)

func move_plane():
	velocity = $Plane.transform.x * speed
	move_and_slide()
	
func handle_shoot():
	if Input.is_action_pressed("Shoot") and can_shoot():
		rpc("_rpc_plane_shoot")


func _on_shoot_cooldown_timeout():
	shootCooldown.stop()

@rpc("any_peer", "unreliable")
func _rpc_plane_update_rotation(rangle: float) -> void:
	var senderId = multiplayer.get_remote_sender_id();
	if senderId != ownerId: return
	$Plane.rotation_degrees = rangle

@rpc("any_peer", "unreliable")
func _rpc_plane_update_position(pos: Vector2) -> void:
	var senderId = multiplayer.get_remote_sender_id();
	if senderId != ownerId: return
	position = pos

@rpc("any_peer", "reliable", "call_local")
func _rpc_plane_shoot():
	shoot()


func _on_visible_on_screen_notifier_2d_screen_entered():
	insideScreen = true;


func _on_visible_on_screen_notifier_2d_screen_exited():
	insideScreen = false


func _on_area_2d_area_entered(area:Area2D):
	if area.get_parent() is PlaneController and area.get_parent() != self and multiplayer.is_server():
		gameNode.rpc("_rpc_plane_explode", self.global_position)
		gameNode.rpc("_rpc_plane_explode", area.get_parent().global_position)
		gameNode.rpc("_rpc_plane_died", self.ownerId)
		gameNode.rpc("_rpc_plane_died", (area.get_parent() as PlaneController).ownerId)
