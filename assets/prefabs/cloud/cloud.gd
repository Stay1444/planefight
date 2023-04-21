extends Node2D

var velocity: Vector2;
@export var clouds: Array;

var cspeed: float;
var cscale: float;
var pickedCloud: int;

func pickCloud() -> int:
	return randi_range(0, clouds.size())

func getZIndex(tscale: float, scaleRangeBegin: float, scaleRangeEnd: float) -> int:
	if tscale > (scaleRangeBegin + scaleRangeEnd) / 2:
		return 5
	else:
		return -5


func _ready():
	scale.x = cscale;
	scale.y = cscale;

	for n in clouds.size():
		var cloudSprite := get_child(n);
		if n != pickedCloud:
			cloudSprite.queue_free()
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_position += velocity * cspeed * delta
