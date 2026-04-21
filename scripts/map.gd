class_name Map
extends Node2D

@onready var dungeon_generator: Node = $DungeonGeneratorBSP
@onready var camera: Camera2D = $Camera2D
var map_data: MapData

var zoom_speed: float = 0.1
var min_zoom: float = 0.3
var max_zoom: float = 3.0
var pan_speed: float = 1.0


func generate() -> void:
	map_data = dungeon_generator.generate_dungeon()
	_place_tiles()
	_center_camera_on_map()
	
func _place_tiles() -> void:
	for row in map_data.tiles:
		for tile in row:
			add_child(tile)

func clear_map() -> void:
	for row in map_data.tiles:
		for tile in row:
			tile.queue_free()

func _center_camera_on_map() -> void:
	if map_data == null or map_data.tiles.is_empty():
		return

	var width = map_data.width
	var height = map_data.height
	
	var tile_size = Grid.tile_size
	camera.position = Vector2i(width/ 2.0, height/ 2.0) * tile_size

	
func set_dungeon_generator(generator: Node) -> void:
	dungeon_generator = generator

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		camera.position -= event.relative * pan_speed

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			camera.zoom = Vector2.ONE * clamp(camera.zoom.x + zoom_speed, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			camera.zoom = Vector2.ONE * clamp(camera.zoom.x - zoom_speed, min_zoom, max_zoom)
