class_name DungeonGeneratorAgentControlled
extends Node

@export_range(0, 2_147_483_647, 1) 
@warning_ignore("shadowed_global_identifier")
var seed: int = 0

@export_range(20, 200, 1)
var map_width: int = 50

@export_range(20, 200, 1)
var map_height: int = 50

var min_room_size: int = 3

@export_range(4, 10, 1)
var max_room_size: int = 7

var min_corridor_length: int = 3

@export_range(4, 10, 1)
var max_corridor_length: int = 7

var dungeon: MapData
var _rng := RandomNumberGenerator.new()

var digger : Digger

var placed_room : bool = false
var placed_corridor : bool = false
var occupancy_matrix : Array

var seed_used: int = 0

enum Occupancy {
	EMPTY = 0,
	ROOM = 1,
	ROOM_EDGE = 2,
	CORRIDOR = 3
}

func generate_dungeon() -> MapData:

	dungeon = MapData.new(map_width, map_height)
	digger = Digger.new()
	
	_rng = RandomNumberGenerator.new()
	if seed == 0:
		seed_used = randi() % 2_147_483_647 + 1
	else:
		seed_used = seed
	
	_rng.seed = seed_used
	
	_setup_occupancy_matrix()
	_setup_digger()
	_build_dungeon()
	_render_occupancy_matrix()
	dungeon.get_tile(digger.position).set_tile_color(Color.AQUA)
	
	return dungeon

##Incializace kopáče na náhodné pozici na mapě (v minimální vzdálenosti od okraje aby pokaždé vytvořil alespoň jednu místnost)
func _setup_digger() -> void:
	var margin := min_room_size
	var rand_x = _rng.randi_range(margin, map_width - margin - 1)
	var rand_y = _rng.randi_range(margin, map_height - margin - 1)
	
	var start_tile = dungeon.get_tile(Vector2i(rand_x, rand_y))
	start_tile.set_tile_color(Color.BLUE_VIOLET)
	
	digger.set_position(Vector2i(rand_x, rand_y))
	digger.set_direction(_rng.randi_range(0,3))

##Incializace "matice obsazenosti" pro kontrolu obsazenosti polí, začíná prázdná
func _setup_occupancy_matrix() -> void:
	occupancy_matrix = []
	for x in range(map_width):
		var row: Array = []
		for y in range(map_height):
			row.append(Occupancy.EMPTY)
		occupancy_matrix.append(row)

##Převod "matice obsazenosti" na vykreslená políčka
func _render_occupancy_matrix() -> void:
	for x in range(map_width):
		for y in range(map_height):
			var occupancy = occupancy_matrix[x][y]
			match occupancy:
				Occupancy.EMPTY, Occupancy.ROOM_EDGE:
					continue
				Occupancy.ROOM, Occupancy.CORRIDOR:
					_carve_tile(Vector2i(x,y))
					continue

func _carve_tile(position : Vector2i) -> void:
		var tile: Tile = dungeon.get_tile(position)
		tile.set_tile_type(dungeon.tile_types.floor)
	
func _is_in_bounds(pos: Vector2i) -> bool:
	return (
		0 <= pos.x
		and pos.x < map_width
		and 0 <= pos.y
		and pos.y < map_height
	)

##Kontroluje, jestli lze umístit místnost o velikosti 'room_w' * 'room_h' na 'center' tak, aby nepřekrývala stávající místnosti nebo nebyla mimo okraje mapy;
##True -> místnost by překryla stávající místnost nebo by byla mimo mapu
func _check_room_intersections(room_w: int, room_h: int, center: Vector2i) -> bool:
	
	##Buffer pro okraj místnosti
	room_w += 2
	room_h += 2
	
	##Levý horní roh místnosti
	@warning_ignore("integer_division")
	var top_left := center - Vector2i(room_w / 2, room_h / 2)

	##Projde všechna potenciální pole místnosti, vrací true pokud by nějaké pole bylo mimo mapu nebo už bylo součástí jiné místnosti
	for x in range(room_w):
		for y in range(room_h):
			var pos := top_left + Vector2i(x, y)

			if not _is_in_bounds(pos):
				return true

			var occ : int = occupancy_matrix[pos.x][pos.y]
			if occ == Occupancy.ROOM or occ == Occupancy.ROOM_EDGE:
				return true

	return false

##Vytvoří místnost o velikosti 'room_w' * 'room_h' na 'center'
func _build_room(room_w: int, room_h: int, center: Vector2i) -> void:
	##Buffer pro okraj místnosti
	room_w += 2
	room_h += 2
	
	##Levý horní roh místnosti
	@warning_ignore("integer_division")
	var top_left := center - Vector2i(room_w / 2, room_h / 2)

	##Projde všechna pole místnosti a označí je v matici obsazení jako součást místnosti
	for x in range(room_w):
		for y in range(room_h):
			var pos := top_left + Vector2i(x, y)

			var occ = occupancy_matrix[pos.x][pos.y]
			
			##okraj místnosti má speciální označení
			var is_edge := (
				x == 0
				or x == room_w - 1
				or y == 0
				or y == room_h - 1
			)
			
			##pokud by okraj překryl existující koridor, je koridorové pole zachováno pro efekt dveří
			if is_edge:
				if occ != Occupancy.CORRIDOR:
					occupancy_matrix[pos.x][pos.y] = Occupancy.ROOM_EDGE
			else:
				occupancy_matrix[pos.x][pos.y] = Occupancy.ROOM

##Kontroluje jestli může být vytvořen koridor délky 'length' s počátkem 'start' ve směru 'direction';
##První pole koridoru musí být buď okraj místnosti (dveře) nebo součást jiného koridoru, ostatní pole musí být prázdná
func _check_corridor_intersections(length: int, start: Vector2i, direction: Digger.Direction) -> bool:
	var offset := _dir_to_offset(direction)

	for i in range(0, length + 1):
		var pos := start + offset * i

		if not _is_in_bounds(pos):
			return true

		var occ = occupancy_matrix[pos.x][pos.y]
		
		if i == 0:
			if occ != Occupancy.ROOM_EDGE and occ != Occupancy.CORRIDOR:
				return true
		else:
			if occ != Occupancy.EMPTY:
				return true

	return false

##Vytvoří koridor délky 'length' s počátkem 'start' ve směru 'direction', poté posune kopáče na konec koridoru
func _build_corridor(length: int, start: Vector2i, direction: Digger.Direction) -> void:
	var offset := _dir_to_offset(direction)

	for i in range(0, length + 1):
		var pos := start + offset * i
		occupancy_matrix[pos.x][pos.y] = Occupancy.CORRIDOR

	digger.position = start + offset * length


##Hlavní funkce generátoru; Pokud může, vytvoří místnost a/nebo koridor v náhodném směru, končí jakmile nelze vytvořit ani místnost, ani koridor
func _build_dungeon() -> void:
	while true:
		placed_room = false
		placed_corridor = false
		
		##Tvorba největší možné místnosti
		for w in range(max_room_size, min_room_size, -1):
			for h in range(max_room_size, min_room_size, -1):
				if not _check_room_intersections(w, h, digger.position):
					_build_room(w, h, digger.position)
					placed_room = true
					break
			if placed_room:
				break
		
		##Tvorba nejdelšího možného koridoru
		for l in range(max_corridor_length, min_corridor_length, -1):
			var d := _rng.randi_range(0,3)
			var start := _find_corridor_start(digger.position, d)
			
			if start == Vector2i(-1, -1):
				continue
				
			if not _check_corridor_intersections(l, start, d):
				_build_corridor(l, start, d)
				digger.direction = d as Digger.Direction
				placed_corridor = true
				break
			if placed_corridor:
				break
				
		if not placed_room and not placed_corridor:
			break
			
##Určuje kde by měl koridor začínat podle aktuálního kontextu kopáče
func _find_corridor_start(start: Vector2i, direction: Digger.Direction) -> Vector2i:
	var offset := _dir_to_offset(direction)

	var pos := start
	var starting_occ : int = occupancy_matrix[start.x][start.y]

	while _is_in_bounds(pos):
		var occ : int = occupancy_matrix[pos.x][pos.y]

		##pokud je kopáč v místnosti, najde nejbliží okraj místnosti, který pak vrátí jako nový začátek
		if starting_occ == Occupancy.ROOM or starting_occ == Occupancy.ROOM_EDGE:
			if occ == Occupancy.ROOM_EDGE:
				return pos
			if occ == Occupancy.EMPTY:
				return Vector2i(-1, -1)

		##pokud je kopáč v koridoru, vrátí aktuální pozici
		elif starting_occ == Occupancy.CORRIDOR:
			return start

		pos += offset
	
	##chybová pozice
	return Vector2i(-1, -1)

##Převede směr kopání na vektor pro počítání pozic
func _dir_to_offset(direction: Digger.Direction) -> Vector2i:
	match direction:
		Digger.Direction.UP:    return Vector2i(0, -1)
		Digger.Direction.DOWN:  return Vector2i(0, 1)
		Digger.Direction.LEFT:  return Vector2i(-1, 0)
		Digger.Direction.RIGHT: return Vector2i(1, 0)
	return Vector2i.ZERO
