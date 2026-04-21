class_name Digger
extends Node

enum Direction {
	UP = 0,
	DOWN = 1,
	LEFT = 2,
	RIGHT = 3
}

var position : Vector2i = Vector2i(0,0)
var direction : Direction = Direction.UP

func set_position(pos: Vector2i) -> void:
	position = pos

func set_direction(dir: Direction) -> void:
	direction = dir
