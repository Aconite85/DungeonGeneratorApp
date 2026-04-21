class_name MetricsAnalyzer
extends Node

var grid: MapData = null
var file_path := "user://dungeon_metrics.csv"

const OFFSETS := [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(-1,  0),                  Vector2i(1,  0),
	Vector2i(-1,  1), Vector2i(0,  1), Vector2i(1,  1)
]

func analyze(map_data: MapData, algorithm_name: String, seed: int) -> void:
	grid = map_data
	
	var ratio := _floor_wall_ratio()
	var components := _connected_components_reps()

	var comp_count := components.size()
	var max_comp_size := 0

	for val in components.values():
		if val > max_comp_size:
			max_comp_size = val

	var longest_path := _longest_shortest_path()

	var connectivity_ratio :float = float(max_comp_size) / ratio.floors
	var rooms := _detect_rooms()
	var room_count := rooms.size()
	var room_sum := _get_sum(rooms)
	var room_tiles := room_sum
	var room_ratio :float = float(room_tiles) / ratio.floors
	
	var avg_room_size : float = 0.0
	var max_room_size : int = 0
	var min_room_size : int = 0

	if room_count > 0:
		avg_room_size = float(room_sum) / room_count
		max_room_size = rooms.max()
		min_room_size = rooms.min()
	
	var metrics := {
		"algorithm": algorithm_name,
		"seed": seed,
		"floors": ratio.floors,
		"walls": ratio.walls,
		"floor_percent": ratio.floor_percent,
		"wall_percent": ratio.wall_percent,
		"longest_shortest_path": longest_path,
		"component_count": comp_count,
		"max_component_size": max_comp_size,
		"connectivity_ratio": connectivity_ratio,
		"room_count": room_count,
		"avg_room_size": avg_room_size,
		"max_room_size": max_room_size,
		"min_room_size": min_room_size,
		"room_tiles": room_tiles,
		"room_ratio": room_ratio,
		
	}
	#_print_metrics(metrics)
	_save_to_csv(metrics)

	grid = null


func _print_metrics(metrics:Dictionary) -> void:
	print("###########")
	print("Algoritmus: ", metrics.algorithm)
	print("Seed: ", metrics.seed)
	print("Podlahy: ", metrics.floors, " ", metrics.floor_percent * 100, "%")
	print("Zdi: ", metrics.walls, " ", metrics.wall_percent * 100, "%")
	print("Nejdelší nejkratší cesta: ", metrics.longest_shortest_path)
	print("Počet částí: ", metrics.component_count)
	print("Velikost největší části: ", metrics.max_component_size)
	print("Konektivita: ", metrics.connectivity_ratio)
	print("rooms: ", "room count: ", metrics.room_count)
	print("max room s: ", metrics.max_room_size, "min room s: ", metrics.min_room_size)
	print("###########")


func _save_to_csv(metrics: Dictionary) -> void:
	var file_exists := FileAccess.file_exists(file_path)

	var file: FileAccess
	
	##pokud soubor již existuje, zapisuje na konec, jinak začne hlavičkou
	if file_exists:
		file = FileAccess.open(file_path, FileAccess.READ_WRITE)
		file.seek_end()
	else:
		file = FileAccess.open(file_path, FileAccess.WRITE)
		file.store_line("algorithm,seed,floors,walls,floor_percent,wall_percent,longest_shortest_path,component_count,max_component_size,connectivity_ratio,room_count,avg_room_size,max_room_size,min_room_size,room_tiles,room_ratio")

	##tvorba řádku pro zápis do souboru
	var line := "%s,%d,%d,%d,%f,%f,%d,%d,%d,%f,%d,%f,%d,%d,%d,%f" % [ 
		metrics.algorithm,
		metrics.seed,
		metrics.floors,
		metrics.walls,
		metrics.floor_percent,
		metrics.wall_percent,
		metrics.longest_shortest_path,
		metrics.component_count,
		metrics.max_component_size,
		metrics.connectivity_ratio,
		metrics.room_count,
		metrics.avg_room_size,
		metrics.max_room_size,
		metrics.min_room_size,
		metrics.room_tiles,
		metrics.room_ratio
	]

	file.store_line(line)
	file.close()
	
##projde mapu a počítá zdi/podlahy
func _floor_wall_ratio() -> Dictionary:
	var floors: = 0
	var walls: int = 0
	
	for x in range(grid.width):
		for y in range(grid.height):
			if grid.get_tile(Vector2i(x,y)).isWalkable():
				floors += 1
			else:
				walls += 1
	
	var floor_percent := float(floors) / (grid.width * grid.height)
	var wall_percent := float(walls) / (grid.width * grid.height)
	
	return {
		"floors": floors,
		"walls": walls,
		"floor_percent": floor_percent,
		"wall_percent": wall_percent
	}


func start_exit(init: Vector2i) -> Array:
	var tile_a := _bfs(init)
	var start_tile: Vector2i = tile_a["tile"]
	var tile_b := _bfs(start_tile)
	var exit_tile: Vector2i = tile_b["tile"]
	return [start_tile, exit_tile]

##průměr grafu - maximální vzdálenost (nejkratší cestou) mezi 2 poli
func _longest_shortest_path() -> int:
	var reps := _connected_components_reps()
	var global_max := 0

	for start in reps:
		var res_a := _bfs(start)
		var a_tile: Vector2i = res_a["tile"]

		var res_b := _bfs(a_tile)
		var diameter: int = res_b["distance"]

		if diameter > global_max:
			global_max = diameter

	return global_max


func _find_first_floor() -> Vector2i:
	for x in range(grid.width):
		for y in range(grid.height):
			if grid.get_tile(Vector2i(x,y)).isWalkable():
				return Vector2i(x,y)
	
	return Vector2i.ZERO

func _get_neighbours(x: int, y: int) -> Array:
	var neighbours : Array = []
	
	for n in OFFSETS:
		var nx = x + n.x
		var ny = y + n.y
		if grid.is_in_bounds(Vector2i(nx,ny)):
			if grid.get_tile(Vector2i(nx,ny)).isWalkable():
				neighbours.append(Vector2i(nx,ny))
	
	return neighbours

##hledání do šířky, vrací nejvzdálenější pole a jeho vzdálenost od daného pole
func _bfs(start_tile: Vector2i) -> Dictionary:
	var que: Array = []
	var visited = {}
	var distance = {}
	var furthest_tile : Vector2i = start_tile
	var max_distance := 0
	
	que.append(start_tile)
	visited[start_tile] = true
	distance[start_tile] = 0
	
	##dokud neprojde všechny pole
	while not que.is_empty():
		var current = que.pop_front() ##aktuální pole
		for neighbour in _get_neighbours(current.x, current.y): ##projde sousedy aktuálního pole
			if not visited.has(neighbour): ##pokud je ještě neprošel, přidá je do fronty
				visited[neighbour] = true
				distance[neighbour] = distance[current] + 1 
				que.append(neighbour)
		
				if distance[neighbour] > max_distance:
					furthest_tile = neighbour
					max_distance = distance[neighbour]
		
		
	return {
		"tile": furthest_tile,
		"distance": max_distance
	}

##počítá souvislé komponenty a vrací jejich reprezentanty s velikostí komponenty
func _connected_components_reps() -> Dictionary:
	var visited = {}
	var components:= {}
	
	##postupně prochází všechny podlahy, pokud daná podlaha nebyla navštívena, 
	##_flood_fill projde všechny podlahy ve stejné komponentě a spočítá je (velikost komponenty)
	for x in range(grid.width):
		for y in range(grid.height):
			var pos := Vector2i(x, y)
			
			if not grid.get_tile(pos).isWalkable():
				continue
			if visited.has(pos):
				continue
			
			
			var size := _flood_fill(pos, visited)
			components[pos] = size
			
	return components
	
func _flood_fill(start: Vector2i, visited: Dictionary) -> int:
	var que: Array = []
	que.append(start)
	visited[start] = true
	var size:= 0
	
	while not que.is_empty():
		var current: Vector2i = que.pop_front()
		size += 1
		
		for neigh in _get_neighbours(current.x, current.y):
			if not visited.has(neigh):
				visited[neigh] = true
				que.append(neigh)
	
	return size
	
func _is_room_tile(x:int,y:int) -> bool:
	if not grid.get_tile(Vector2i(x,y)).isWalkable():
		return false
	
	return _get_neighbours(x,y).size() >= 5
	
func _detect_rooms() -> Array:
	var visited := {}
	var rooms := []
	
	for x in range(grid.width):
		for y in range(grid.height):
			var pos := Vector2i(x,y)
			
			if visited.has(pos):
				continue
			
			if not _is_room_tile(x,y):
				continue
			
			var size := _flood_fill_room(pos, visited)
			rooms.append(size)
	
	return rooms
	
func _flood_fill_room(start: Vector2i, visited: Dictionary) -> int:
	var que := [start]
	visited[start] = true
	var size := 0
	
	while not que.is_empty():
		var current : Vector2i = que.pop_front()
		size += 1
		
		for n in OFFSETS:
			var nx = current.x + n.x
			var ny = current.y + n.y
			var next := Vector2i(nx,ny)
			
			if not grid.is_in_bounds(next):
				continue
			
			if visited.has(next):
				continue
			
			if not _is_room_tile(nx,ny):
				continue
			
			visited[next] = true
			que.append(next)
	
	return size

func _get_sum(array: Array) -> int:
	var sum := 0
	for i in array:
		sum += i
	
	return sum
