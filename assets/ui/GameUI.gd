extends CanvasLayer

const playNode = preload("res://play.gd")

var Game: PlaneGame;

func setup(node: playNode):
	Game = node.game;

	$KillFeed.setup(node)
	$HealthBar.setup(node)
	$ScoreBoard.setup(node)
