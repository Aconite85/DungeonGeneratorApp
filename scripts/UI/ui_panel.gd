extends CanvasLayer

@onready var params_container: VBoxContainer = $PanelContainer/VBoxContainer
@onready var gen_button: Button = $GenButton
@onready var target_generator: Node = $"../Map/DungeonGeneratorBSP"
@onready var map_node : Map = $"../Map"
@onready var list_node : ItemList = $ItemList
@onready var metrics_button: Button = $MetricsButton
@onready var metrics_analyzer: MetricsAnalyzer = $"../Map/MetricsAnalyzer"
@onready var gen_count: SpinBox =$GenCount

var input_labels: Array = []
var input_values: Array = []

func _ready() -> void:
	gen_button.pressed.connect(_on_generate_pressed)
	metrics_button.pressed.connect(_on_metrics_pressed)
	list_node.add_item("BSP")
	list_node.add_item("Digger - Random")
	list_node.add_item("Digger - Controlled")
	list_node.add_item("Cellular Automata")

	list_node.item_activated.connect(_generator_switch)
		

func _generator_switch(index: int) -> void:
	
	match index:
		0:
			if(target_generator ==$"../Map/DungeonGeneratorBSP"):
				_on_generate_pressed()
			else: 
				set_target_generator($"../Map/DungeonGeneratorBSP")
				_on_generate_pressed()
		1:
			if(target_generator ==$"../Map/DungeonGeneratorAgentRandom"):
				_on_generate_pressed()
			else:
				set_target_generator($"../Map/DungeonGeneratorAgentRandom")
				_on_generate_pressed()
		2:
			if(target_generator ==$"../Map/DungeonGeneratorAgentControlled"):
				_on_generate_pressed()
			else:
				set_target_generator($"../Map/DungeonGeneratorAgentControlled")
				_on_generate_pressed()
		3:
			if(target_generator ==$"../Map/DungeonGeneratorCA"):
				_on_generate_pressed()
			else:
				set_target_generator($"../Map/DungeonGeneratorCA")
				_on_generate_pressed()

func set_target_generator(generator: Node) -> void:
	target_generator = generator
	map_node.set_dungeon_generator(generator)
	_build_ui_for_generator(generator)

func _build_ui_for_generator(generator: Node) -> void:
	
	##smaže původní parametry
	for child in params_container.get_children():
		child.queue_free()
		
	input_labels.clear()
	input_values.clear()


	##vezme parametry třídy generátoru
	var script: Script = generator.get_script()
	if script == null:
		push_warning("Target generator has no script attached.")
		return

	var props: Array[Dictionary] = script.get_script_property_list()

	for prop: Dictionary in props:
		##zahrnuje pouze parametry s označením @export
		if prop["usage"] < 4102:
			continue
		if prop["type"] == TYPE_NIL:
			continue

		var name: StringName = prop["name"]
		var type_id: int = prop["type"]
		var value: Variant = generator.get(name)
		
		##vytvoří element Label s textem podle názvu parametru
		var label := Label.new()
		label.text = name.capitalize()
		params_container.add_child(label)
		##pomocná array s názvy parametrů
		input_labels.append(name)

		var control: Control = null
		
		##podle typu parametru vytvoří element pro input
		match type_id:
			TYPE_INT, TYPE_FLOAT:
				var spin := SpinBox.new()
				spin.value = float(value)

				##pokud má parametr nastavené ohraničení hodnot @export_range(), nastaví ohraničení i input elementu
				if prop["hint"] == PROPERTY_HINT_RANGE and prop.has("hint_string") and prop["hint_string"] != "":
					var parts = prop["hint_string"].split(",")
					if parts.size() >= 2:
						spin.min_value = float(parts[0])
						spin.max_value = float(parts[1])
					if parts.size() >= 3:
						spin.step = float(parts[2])
				else:
					##defaultní ohraničení hodnot
					spin.min_value = 0
					spin.max_value = 100
					spin.step = 1.0

				params_container.add_child(spin)
				control = spin

			TYPE_BOOL:
				var check := CheckBox.new()
				check.text = ""
				check.button_pressed = bool(value)
				params_container.add_child(check)
				control = check

			TYPE_STRING:
				var line := LineEdit.new()
				line.text = str(value)
				params_container.add_child(line)
				control = line

			_:
				continue
		

		if control:
			##pomocná array s odkazy na input elementy
			input_values.append(control)

##zmáčknutí tlačítka pro generaci nového dungeonu
##nastaví hodnoty parametrům podle zadaných hodnot v UI elementech
func _on_generate_pressed() -> void:
	if target_generator == null:
		push_warning("No generator assigned")
		return
	
	for i in range(input_values.size()):
		var control = input_values[i]
		var label = input_labels[i]

		var prop_type = typeof(target_generator.get(label))

		if control is SpinBox:
			if prop_type == TYPE_INT:
				target_generator.set(label, int(control.value))
			else:
				target_generator.set(label, control.value)
			
		elif control is CheckBox:
			target_generator.set(label, control.button_pressed)
			
		elif control is LineEdit:
			target_generator.set(label, control.text)
			
	map_node.clear_map()
	map_node.generate()

##generuje x (podle UI elementu) dungeonů se stejnými parametry a ukládá jejich data
func _on_metrics_pressed() -> void:
	for i in range(gen_count.value):
		_on_generate_pressed()
		metrics_analyzer.analyze(map_node.map_data,target_generator.name, target_generator.seed_used)
