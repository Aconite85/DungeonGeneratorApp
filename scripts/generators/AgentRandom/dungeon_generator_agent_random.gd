class_name DungeonGeneratorAgentRandom
extends Node

@export_range(0, 2_147_483_647, 1) 
@warning_ignore("shadowed_global_identifier")
var seed: int = 0

@export_range(20, 200, 1)
var map_width: int = 50

@export_range(20, 200, 1)
var map_height: int = 50

@export_range(1,100,1)
var direction_chance: = 5

@export_range(1,100,1)
var room_chance: = 5

@export_range(0,100,1)
var chance_increase: = 5

@export_range(1,1000,1)
var max_steps: = 100


var dungeon : MapData
var _rng := RandomNumberGenerator.new()
var start_tile : Tile
var digger : Digger
var rand_x : int = 0
var rand_y : int = 0


var step := 0

var seed_used: int = 0

func generate_dungeon() -> MapData:
	var init_room_chance:= room_chance
	var init_direction_chance:= direction_chance
	dungeon = MapData.new(map_width, map_height)
	digger = Digger.new()
	
	_rng = RandomNumberGenerator.new()
	if seed == 0:
		seed_used = randi() % 2_147_483_647 + 1
	else:
		seed_used = seed
	
	_rng.seed = seed_used
	
	step = 0
	_run_digger()
	room_chance = init_room_chance
	direction_chance = init_direction_chance
	return dungeon

##Hlavní cyklus kopáče, začne na náhodném místě s náhodný směrem a kope dokud 'step < max_steps'
func _run_digger() -> void:
	rand_x = _rng.randi_range(0,map_width-1)
	rand_y = _rng.randi_range(0,map_height-1)
	
	start_tile = dungeon.get_tile(Vector2i(rand_x, rand_y))
	start_tile.set_tile_color(Color.BLUE_VIOLET)
	
	digger.set_position(Vector2i(rand_x, rand_y))
	_pick_random_direction()
	
	_carve_tile(digger.position)
	
	while step <= max_steps:
		_dig_in_dir()
		step += 1
		
	dungeon.get_tile(digger.position).set_tile_color(Color.AQUA)

##Posune kopáče o jedno políčko a rozhoduje jestli změní směr či vytvoří místnost; čím déle bez změny směru/místnosti, tím větší šance
func _dig_in_dir() -> void:
	var next_offset := _dir_to_offset(digger.direction)

	var next_position := digger.position + next_offset

	if dungeon.is_in_bounds(next_position):
		digger.position = next_position
		_carve_tile(digger.position)
	else: 
		_pick_random_direction() ##náhodný směr pokud narazí do zdi
		return
	
	var roll_dir := _rng.randi_range(0, 100)
	
	if roll_dir < direction_chance:
		_pick_random_direction()
		direction_chance = 0
	else:
		direction_chance = min(direction_chance + chance_increase, 100)
		
	var roll_room := _rng.randi_range(0, 100)
	
	if roll_room < room_chance:
		_dig_room(digger.position, _rng.randi_range(3,7))
		room_chance = 0
	else:
		room_chance = min(room_chance + chance_increase, 100)

##Vytvoří místnost velikosti 'room_size' se středem v 'center'
func _dig_room(center: Vector2i, room_size: int) -> void:
	@warning_ignore("integer_division")
	var half := room_size / 2
	var top_left := center - Vector2i(half, half)

##pokud je jakékoliv pole mimo mapu, místnost se nevytvoří
	for x in range(room_size):
		for y in range(room_size):
			var pos := top_left + Vector2i(x, y)
			if not dungeon.is_in_bounds(pos):
				return

	for x in range(room_size):
		for y in range(room_size):
			var pos := top_left + Vector2i(x, y)
			_carve_tile(pos)


##Vybere náhodný směr pro kopáče
func _pick_random_direction() -> void:
	digger.set_direction(_rng.randi_range(0,3))

func _carve_tile(position : Vector2i) -> void:
		var tile: Tile = dungeon.get_tile(position)
		tile.set_tile_type(dungeon.tile_types.floor)

##Převede směr kopání na vektor pro počítání pozic
func _dir_to_offset(direction: Digger.Direction) -> Vector2i:
	match direction:
		Digger.Direction.UP:    return Vector2i(0, -1)
		Digger.Direction.DOWN:  return Vector2i(0, 1)
		Digger.Direction.LEFT:  return Vector2i(-1, 0)
		Digger.Direction.RIGHT: return Vector2i(1, 0)
	return Vector2i.ZERO
