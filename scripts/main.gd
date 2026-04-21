class_name Game
extends Node2D


@onready var map: Map = $Map


func _ready() -> void:
	
	var ui_panel = $UIPanel
	var generator = map.dungeon_generator
	ui_panel.set_target_generator(generator)
	map.generate()
	
func get_map_data() -> MapData:
	return map.map_data
