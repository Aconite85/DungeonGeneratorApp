class_name MapData
extends RefCounted

var width : int
var height : int
var tiles: Array


const tile_types = {
	"floor": preload("res://tile_definitions/floor_def.tres"),
	"wall": preload("res://tile_definitions/wall_def.tres")
}

func _init(map_width: int, map_height: int) -> void:
	width = map_width
	height = map_height
	_setup_tiles()
	
func _setup_tiles() -> void:
	tiles = []
	for x in range(width):  
		var row: Array = []
		for y in range(height):  
			var tile_position := Vector2i(x, y)
			var tile := Tile.new(tile_position, tile_types.wall)
			row.append(tile)
		tiles.append(row)

func get_tile(position: Vector2i) -> Tile:
	return tiles[position.x][position.y]
	
func is_in_bounds(coordinate: Vector2i) -> bool:
	return (
		0 <= coordinate.x
		and coordinate.x < width
		and 0 <= coordinate.y
		and coordinate.y < height
	)
