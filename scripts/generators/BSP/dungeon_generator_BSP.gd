class_name DungeonGeneratorBSP
extends Node

@export_category("Generator parameters")

##seed, 0 = náhodný
@export_range(0, 2_147_483_647, 1) 
@warning_ignore("shadowed_global_identifier")
var seed: int = 0

##šířka mapy
@export_range(20, 200, 1)
var map_width: int = 50

##výška mapy
@export_range(20,200, 1)
var map_height: int = 50

##maximální počet dělení (hloubka Bin stromu)
@export_range(2, 50, 1)
var max_depth: int = 10

##minimální velikost místnosti
@export_range(5, 30, 1)
var min_room_size: int = 6

##určuje minimální velikost dělené části
@export_range(1, 5, 1)
var padding: int = 2

var seed_used: int = 0

##nejmenší možná velikost dělené části do které se vejde místnost s hranou
var min_partition_size: int = min_room_size + padding
var _rng := RandomNumberGenerator.new()
var dungeon : MapData


func generate_dungeon() -> MapData:
	min_partition_size = min_room_size + padding
	_rng = RandomNumberGenerator.new()
	if seed == 0:
		seed_used = randi() % 2_147_483_647 + 1
	else:
		seed_used = seed
	
	_rng.seed = seed_used
		
	dungeon = MapData.new(map_width, map_height)
	var root = _make_tree_node(Rect2i(0, 0, map_width, map_height))
	_make_rooms_in_tree(root)
	_connect_rooms(root)
	return dungeon


## tvorba binárního stromu
## pokud lze buňka dělit a není překročen limit dělení, rozdělí buňku (na základě poměru stran nebo náhodně)
## na dvě nové, které pak znovu dělí
func _make_tree_node(rect: Rect2i, depth: int = 0 ) -> BSPNode:
	var node = BSPNode.new(rect)
	
	if (not _can_split_horizontally(rect) and not _can_split_vertically(rect)) or depth >= max_depth:
		return node
	
	var split_hor = false
	var aspect_ratio = float(rect.size.x)/float(rect.size.y)
	
	if aspect_ratio > 1.25:
		split_hor = false
	elif aspect_ratio < 0.8:
		split_hor = true
	else:
		split_hor = _rng.randf() < 0.5
	
	if split_hor and _can_split_horizontally(rect):
		var splits = _horizontal_split(rect)
		var top = splits.get(0)
		var bottom = splits.get(1)
		node.left = _make_tree_node(top, depth + 1)
		node.right = _make_tree_node(bottom, depth + 1)
	elif not split_hor and _can_split_vertically(rect):
		var splits = _vertical_split(rect)
		var left = splits.get(0)
		var right = splits.get(1)
		node.left = _make_tree_node(left, depth + 1)
		node.right = _make_tree_node(right, depth + 1)
	
	return node

## prochází binární strom a v listech tvoří místnosti
func _make_rooms_in_tree(node: BSPNode) -> void:
	if node.left or node.right:
		if node.left:
			_make_rooms_in_tree(node.left)
		if node.right:
			_make_rooms_in_tree(node.right)
	else:
		if node.rect.size.x * 0.8 > min_room_size and node.rect.size.y * 0.8 > min_room_size:
			var width = int(node.rect.size.x * _rng.randf_range(0.5, 0.8))
			var height = int(node.rect.size.y * _rng.randf_range(0.5, 0.8))
			var sx = _rng.randi_range(node.rect.position.x + 1, node.rect.end.x - width - 1)
			var sy = _rng.randi_range(node.rect.position.y + 1, node.rect.end.y - height - 1)
			node.room = Rect2i(sx, sy, width, height)
			_carve_room(node.room)

## prochází sousední listy a pokud mají místnost tak je spojí
func _connect_rooms(node: BSPNode) -> void:
	if node.left and node.right:
		var room_left = _get_room_in_subtree(node.left)
		var room_right = _get_room_in_subtree(node.right)
		if room_left and room_right:
			_tunnel_between(room_left.get_center(), room_right.get_center())
		
		_connect_rooms(node.left)
		_connect_rooms(node.right)

## hledá místnoti v podstromu daného uzlu
func _get_room_in_subtree(node: BSPNode) -> Rect2i:

	if node.room:
		return node.room
	if node.left:
		var room = _get_room_in_subtree(node.left)
		if room:
			return room
	if node.right:
		var room = _get_room_in_subtree(node.right)
		if room:
			return room
	return Rect2i()

## rozdělí část horizontálně
func _horizontal_split(partition: Rect2i) -> Array:
	var temp_Array: Array = []
	## náhodné y v rozmezí velikosti části, podle kterého se bude část dělit
	var rand_y = _rng.randi_range(
		partition.position.y + min_partition_size,
		partition.end.y - min_partition_size)
		
	var top_height = rand_y - partition.position.y
	var bottom_height = partition.end.y - rand_y
		
	## nové části, spodní a horní
	var bottom_partition = Rect2i(
		partition.position.x,
		rand_y,
		partition.size.x,
		bottom_height
		)
			
	var top_partition = Rect2i(
		partition.position.x,
		partition.position.y,
		partition.size.x,
		top_height
		)
	temp_Array.append(top_partition)
	temp_Array.append(bottom_partition)
	return temp_Array

## rozdělí části vertikálně
func _vertical_split(partition: Rect2i) -> Array:
	var temp_Array: Array = []
	
	## náhodné x v rozmezí velikosti části, podle kterého se bude část dělit
	var rand_x = _rng.randi_range(
	partition.position.x + min_partition_size,
	partition.end.x - min_partition_size)
	
	var left_width = rand_x - partition.position.x
	var right_width = partition.end.x - rand_x
	
	## nové části, levá a pravá
	var left_partition = Rect2i(
		partition.position.x,
		partition.position.y,
		left_width,
		partition.size.y
		)
	var right_partition = Rect2i(
		rand_x,
		partition.position.y,
		right_width,
		partition.size.y
		)
		
	temp_Array.append(left_partition)
	temp_Array.append(right_partition)
	return temp_Array

##kontrola, zda je možné část dále dělit
func _can_split_vertically(partition: Rect2i) -> bool:
	return partition.size.x >= min_partition_size * 2

func _can_split_horizontally(partition: Rect2i) -> bool:
	return partition.size.y >= min_partition_size * 2


## mění danou zeď na podlahu
func _carve_tile(x: int, y: int) -> void:
	var tile_position = Vector2i(x, y)
	var tile: Tile = dungeon.get_tile(tile_position)
	tile.set_tile_type(dungeon.tile_types.floor)

## daný obdélník změní na podlahu
func _carve_room(room: Rect2i) -> void:
	if room.size.x > 0 and room.size.y > 0:
		for y in range(room.position.y, room.end.y):
			for x in range(room.position.x, room.end.x):
				_carve_tile(x, y)

## tvoří horizontální chodbu
func _corridor_horizontal(y: int, x_start: int, x_end: int) -> void:
	var x_min: int = mini(x_start, x_end)
	var x_max: int = maxi(x_start, x_end)
	for x in range(x_min, x_max + 1):
		_carve_tile(x, y)
		
## tvoří vertikální chodbu
func _corridor_vertical(x: int, y_start: int, y_end: int) -> void:
	var y_min: int = mini(y_start, y_end)
	var y_max: int = maxi(y_start, y_end)
	for y in range(y_min, y_max + 1):
		_carve_tile(x, y)

## vytvoří chodbu tvaru L (náhodné orientace) mezi zadanými body
func _tunnel_between(start: Vector2i, end: Vector2i) -> void:
	if _rng.randf() < 0.5:
		_corridor_horizontal(start.y, start.x, end.x)
		_corridor_vertical(end.x, start.y, end.y)
	else:
		_corridor_vertical(start.x, start.y, end.y)
		_corridor_horizontal(end.y, start.x, end.x)
