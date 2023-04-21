extends CenterContainer

class PlayerScore:
	var PlayerId: int
	var NameNode: Label
	var KillsNode: Label
	var DeathsNode: Label
	var PingNode: Label
	var OtherNodes: Array[Control]

const playNode = preload("res://play.gd")

var game: PlaneGame;

func setup(node: playNode) -> void:
	node.entered_game.connect(_on_entered_game)
	node.exited_game.connect(_on_exited_game)

func _on_entered_game(tgame: PlaneGame):
	game = tgame
	game.on_player_stats_changed.connect(_on_player_stats_changed)
	game.on_remoteplayer_connected.connect(_on_remoteplayer_connected)
	game.on_remoteplayer_disconnected.connect(_on_remoteplayer_disconnected)
	addScore(game.LocalId)
	updateScore(game.getLocalPlayer())
func _on_exited_game():
	game.on_player_stats_changed.disconnect(_on_player_stats_changed)
	game.on_remoteplayer_connected.disconnect(_on_remoteplayer_connected)
	game.on_remoteplayer_disconnected.disconnect(_on_remoteplayer_disconnected)
	game = null;
	
var scores = {}

func hasScore(playerId: int) -> bool:
	return scores.has(playerId)

func getScore(playerId: int) -> PlayerScore:
	return scores[playerId]

func addScore(playerId: int) -> PlayerScore:
	var playerScore := PlayerScore.new()
	
	playerScore.PlayerId = playerId
	playerScore.NameNode = Label.new()
	playerScore.KillsNode = Label.new()
	playerScore.DeathsNode = Label.new()
	playerScore.PingNode = Label.new()
	
	var nameCenterNode = CenterContainer.new()
	var killsCenterNode = CenterContainer.new()
	var deathsCenterNode = CenterContainer.new()
	var pingCenterNode = CenterContainer.new()

	nameCenterNode.add_child(playerScore.NameNode)
	killsCenterNode.add_child(playerScore.KillsNode)
	deathsCenterNode.add_child(playerScore.DeathsNode)
	pingCenterNode.add_child(playerScore.PingNode)

	playerScore.OtherNodes.append(nameCenterNode)
	playerScore.OtherNodes.append(killsCenterNode)
	playerScore.OtherNodes.append(deathsCenterNode)
	playerScore.OtherNodes.append(pingCenterNode)

	$Panel/Columns/NameColumn.add_child(nameCenterNode)
	$Panel/Columns/KillsColumn.add_child(killsCenterNode)
	$Panel/Columns/DeathsColumn.add_child(deathsCenterNode)
	$Panel/Columns/PingColumn.add_child(pingCenterNode)
	
	scores[playerId] = playerScore

	return playerScore

func updateScore(player: Player) -> void:
	var playerScore := getScore(player.Id)

	playerScore.NameNode.text = str(player.Nickname)
	playerScore.KillsNode.text = str(player.KillCount)
	playerScore.DeathsNode.text = str(player.DeathCount)
	playerScore.PingNode.text = str(69) # TODO

func removeScore(playerId: int) -> void:
	var playerScore = getScore(playerId)
	if playerScore != null:
		for node in playerScore.OtherNodes:
			node.queue_free()
	scores.erase(playerId) 

func _ready():
	visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("Scoreboard"):
		visible = true
	elif Input.is_action_just_released("Scoreboard"):
		visible = false

func _on_player_stats_changed(player: Player) -> void:
	if not hasScore(player.Id):
		addScore(player.Id)
	
	updateScore(player)

func _on_remoteplayer_connected(player: Player) -> void:
	addScore(player.Id)
	updateScore(player)

func _on_remoteplayer_disconnected(player: Player) -> void:
	removeScore(player.Id)
