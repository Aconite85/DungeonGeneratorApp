class_name DungeonGeneratorCA
extends Node

@export_range(0, 2_147_483_647, 1) 
@warning_ignore("shadowed_global_identifier")
var seed: int = 0

@export_range(20, 200, 1)
var map_width: int = 50

@export_range(20, 200, 1)
var map_height: int = 50

@export_range(1,100,1)
var wall_chance: int = 50

@export_range(0,20,1)
var iterations: int = 2

@export_range(1,8,1)
var min_neighbour_walls: int = 5

@export
var eight_neighbours: bool = true


var _rng := RandomNumberGenerator.new()
var dungeon: MapData

var current_grid: Array
var next_grid: Array

var seed_used: int = 0

const MOORE_OFFSETS := [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(-1,  0),                  Vector2i(1,  0),
	Vector2i(-1,  1), Vector2i(0,  1), Vector2i(1,  1)
]

const NEUMANN_OFFSETS := [
	Vector2i(0, -1),
	Vector2i(-1, 0), Vector2i(1, 0),
	Vector2i(0,  1)
]

func generate_dungeon() -> MapData:
	
	_rng = RandomNumberGenerator.new()
	if seed == 0:
		seed_used = randi() % 2_147_483_647 + 1
	else:
		seed_used = seed
	
	_rng.seed = seed_used
	
	dungeon = MapData.new(map_width, map_height)
	
	_setup_grid()
	_setup_next_grid()
	_init_wall_distribution(current_grid)
	
	_iterator()
	
	_render()
	
	return dungeon

##Cyklus generování, kdy podle aktuálního stavu celého dungeonu vytvoří nový stav
func _iterator() -> void:
	for n in range(iterations):
		_automaton()
		current_grid = next_grid
		_setup_next_grid()
	return

##Mění pole na zeď v pomocné matici 'next_grid' podle počtu sousedních zdí daného pole v aktuální matici 'current_grid'
func _automaton() -> void:
	for x in range(map_width):
		for y in range(map_height):
			if _count_neighbours(x,y) >= min_neighbour_walls:
				next_grid[x][y] = true
			else:
				next_grid[x][y] = false
			
	return

##Počáteční distribuce zdí na mapě
func _init_wall_distribution(grid: Array) -> void:
	for x in range(map_width):
		for y in range(map_height):
			if _rng.randi_range(0, 100) < wall_chance:
				grid[x][y] = true
			
##Vykreslení dungeonu podle pomocné matice
func _render() -> void:
	for x in range(map_width):
		for y in range(map_height):
			if not current_grid[x][y]:
				dungeon.get_tile(Vector2i(x,y)).set_tile_type(dungeon.tile_types.floor)

##Incializace pomocné matice
func _setup_grid() -> void:
	current_grid = []
	for x in range(map_width):
		var row: Array = []
		for y in range(map_height):
			row.append(false)
		current_grid.append(row)

##Incializace pomocné druhé matice
func _setup_next_grid() -> void:
	next_grid = []
	for x in range(map_width):
		var row: Array = []
		for y in range(map_height):
			row.append(false)
		next_grid.append(row)

##Počítá kolik sousedních polí daného pole jsou zdi, rozlišuje 4 a 8 sousednost
func _count_neighbours(x: int, y: int) -> int:
	var wall_count: int = 0
	var offsets: Array
	
	if eight_neighbours:
		offsets = MOORE_OFFSETS 
	else: 
		offsets = NEUMANN_OFFSETS
		
	for off in offsets:
		var pos = Vector2i(x, y) + off
		
		if not _is_in_bounds(pos):
			wall_count += 1
		elif current_grid[pos.x][pos.y]:
			wall_count += 1
	
	return wall_count
	
func _is_in_bounds(pos: Vector2i) -> bool:
	return (
		0 <= pos.x
		and pos.x < map_width
		and 0 <= pos.y
		and pos.y < map_height
	)
