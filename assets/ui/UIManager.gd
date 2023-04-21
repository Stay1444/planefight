extends CanvasLayer

@export var GameUI: CanvasLayer;
@export var MenuUI: CanvasLayer;

const playNode = preload("res://play.gd")

func setup(node: playNode):
	node.entered_game.connect(_on_play_entered_game)
	node.exited_game.connect(_on_play_exited_game)
	GameUI.setup(node)
	MenuUI.setup(node)

func _ready():
	GameUI.hide()
	MenuUI.show()

func _on_play_entered_game(game: PlaneGame):
	MenuUI.hide()
	GameUI.show()


func _on_play_exited_game(game: PlaneGame):
	MenuUI.show()
	GameUI.hide()
