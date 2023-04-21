extends HBoxContainer

@export var messageLabel: Label;

func set_data(message: String):
	messageLabel.text = message;


func _on_timer_timeout():
	queue_free()
