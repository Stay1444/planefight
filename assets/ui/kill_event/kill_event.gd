extends HBoxContainer

@export var killer: Label;
@export var victim: Label;

func set_data(killerName: String, victimName: String):
	killer.text = killerName;
	victim.text = victimName;


func _on_timer_timeout():
	$AnimationPlayer.play("fade_out")


func _on_animation_player_animation_finished(anim_name):
	queue_free()
