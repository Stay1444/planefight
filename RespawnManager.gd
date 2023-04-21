extends Node

class_name RespawnManager

const RespawnTime: float = 5;

var timers = {}

signal on_remain_time_completed(id: int)

func getRemainingTime(id: int) -> float:
    return timers[id]

func hasRemainingTime(id: int) -> bool:
    return timers[id] > 0

func remove(id: int) -> void:
    timers.erase(id)

func add(id: int, time: float = RespawnTime) -> void:
    timers[id] = time

func update(deltaTime: float) -> void:
    for id in timers:
        timers[id] -= deltaTime;
        if timers[id] < 0:
            on_remain_time_completed.emit(id)

            remove(id)
            update(deltaTime) # I don't really know how iterators work in GDScript, but in c# this is necessary to avoid a concurrent modification exception
            return
            