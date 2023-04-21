extends Node2D


enum WindDirection {
	North,
	South,
	East,
	West
}

@export var northSpawn: ColorRect;
@export var southSpawn: ColorRect;
@export var eastSpawn: ColorRect;
@export var westSpawn: ColorRect;
@export var windDirection: WindDirection;
@export var spawnTimer: Timer;
@export var cloudPrefab: PackedScene;
@export var spawnTargetNode: Node2D;
@export var spawnTimerRangeBegin: float = 0.5;
@export var spawnTimerRangeEnd: float = 10;
@export_category("Clouds")
@export var cloudSpeedRangeBegin: float = 30.0;
@export var cloudSpeedRangeEnd: float = 100;
@export var cloudScaleRangeBegin: float = 1.0;
@export var cloudScaleRangeEnd: float = 5.0;

# Called when the node enters the scene tree for the first time.
func _ready():
	windDirection = get_random_direction();


func get_random_pos_along_node(node: ColorRect) -> Vector2:
	var calculatedScale: Vector2 = node.size * node.scale
	var calculateArea: Vector2 = node.global_position + calculatedScale
	return Vector2(randf_range(node.global_position.x, calculateArea.x), randf_range(node.global_position.y, calculateArea.y))

func get_random_direction() -> WindDirection:
	return randi_range(0, WindDirection.size()-1) as WindDirection


func get_wind_direction_velocity(direction: WindDirection) -> Vector2:
	match direction:
		WindDirection.North: 
			return Vector2(0, 1)
		WindDirection.South:
			return Vector2(0, -1)
		WindDirection.East:
			return Vector2(-1, 0)
		WindDirection.West:
			return Vector2(1, 0)
	return Vector2.ZERO;

func get_wind_direction_spawn_position(direction: WindDirection) -> Vector2:
	match direction:
		WindDirection.North: 
			return get_random_pos_along_node(northSpawn)
		WindDirection.South:
			return get_random_pos_along_node(southSpawn)
		WindDirection.East:
			return get_random_pos_along_node(eastSpawn)
		WindDirection.West:
			return get_random_pos_along_node(westSpawn)
	return Vector2.ZERO;
	
@rpc("authority", "call_local")
func _on_sky_spawn_cloud(velocity: Vector2, spawnPosition: Vector2, cspeed: float, cscale: float, pickedCloud: int, zindex: int):
	var instance := cloudPrefab.instantiate();
	instance.velocity = velocity;
	instance.global_position = spawnPosition;
	instance.cspeed = cspeed;
	instance.pickedCloud = pickedCloud
	instance.cscale = cscale;
	instance.z_index = zindex;
	spawnTargetNode.add_child(instance)

@rpc("authority", "call_local")
func _on_sky_change_direction(newDirection: WindDirection):
	windDirection = newDirection;
	print_debug("Changing wind direction to %s" % WindDirection.keys()[newDirection])

func _on_spawn_timer_timeout():
	if not multiplayer.is_server():
		spawnTimer.stop()
		print_debug("Trying to spawn cloud but its not the server, cancelling")
		return
	
	var instance := cloudPrefab.instantiate();
	var pickedCloud = instance.pickCloud();
	var cScale = randf_range(cloudScaleRangeBegin, cloudScaleRangeEnd);

	var cloudZIndex = instance.getZIndex(cScale, cloudScaleRangeBegin, cloudScaleRangeEnd)
	instance.queue_free()

	rpc("_on_sky_spawn_cloud", 
		get_wind_direction_velocity(windDirection), 
		get_wind_direction_spawn_position(windDirection),
		randf_range(cloudSpeedRangeBegin, cloudSpeedRangeEnd),
		cScale,
		pickedCloud,
		cloudZIndex)

	spawnTimer.stop()
	spawnTimer.wait_time = randf_range(spawnTimerRangeBegin, spawnTimerRangeEnd)
	spawnTimer.start(0)


func _on_change_cloud_direction_timer_timeout():
	if not multiplayer.is_server():
		$ChangeCloudDirectionTimer.stop()
		print_debug("Trying to change direction but its not the server, cancelling")
		return
	
	rpc("_on_sky_change_direction", get_random_direction())
	$ChangeCloudDirectionTimer.stop()
	$ChangeCloudDirectionTimer.start(0)
