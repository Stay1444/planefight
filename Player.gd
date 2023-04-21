extends Node

class_name Player

var Id: int;
var IsRemote: bool
var Nickname: String

var KillCount: int
var DeathCount: int

func _init(id: int, isRemote: bool, nickname: String) -> void:
	super()
	Id = id
	IsRemote = isRemote
	Nickname = nickname
