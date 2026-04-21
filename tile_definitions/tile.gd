class_name Tile
extends Sprite2D

var _definition: TileDefinition

func _init(grid_position: Vector2i, tile_definition: TileDefinition) -> void:
	centered = false
	position = Grid.grid_to_world(grid_position)
	set_tile_type(tile_definition)


func set_tile_type(tile_definition: TileDefinition) -> void:
	_definition = tile_definition
	texture = _definition.texture

func set_tile_color(color: Color ) -> void:
	modulate = color

func isWalkable() -> bool:
	return _definition.isWalkable
