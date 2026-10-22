extends Node2D

@export_category("Game Connections")
@export var player_bubble: CharacterBody2D
@export var question_label: Label
@export var timer_label: Label
@export var answer_buttons: Array[Button] = []
@export_file("*.tscn") var next_level_scene: String = "res://level_2.tscn"

@onready var normal_timer: Timer = Timer.new()
@onready var emergency_timer: Timer = Timer.new()

var normal_time_limit: float = 10.0
var emergency_time_limit: float = 4.0

var current_question_index: int = 0
var is_emergency: bool = false
var current_correct_index: int = -1

var normal_questions = [
	{"q": "What planet is known as the Red Planet?", "options": ["Earth", "Mars", "Jupiter", "Venus"], "correct": 1},
	{"q": "What is the chemical symbol for water?", "options": ["H2O", "O2", "CO2", "NaCl"], "correct": 0},
	{"q": "What force pulls objects to the ground?", "options": ["Magnetism", "Friction", "Gravity", "Inertia"], "correct": 2},
	{"q": "Which gas do plants absorb?", "options": ["Oxygen", "Carbon dioxide", "Nitrogen", "Helium"],"correct": 1},

{"q": "How many sides does a hexagon have?",
 "options": ["Five", "Six", "Seven", "Eight"],
 "correct": 1},

{"q": "Which is the largest ocean?",
 "options": ["Atlantic", "Indian", "Arctic", "Pacific"],
 "correct": 3},

{"q": "What is the closest star to Earth?",
 "options": ["Sirius", "The Sun", "Polaris", "Vega"],
 "correct": 1},

{"q": "What is 12 × 8?",
 "options": ["86", "92", "96", "108"],
 "correct": 2},
	{"q": "Earth's natural satellite?", "options": ["Mars", "Moon", "Sun", "Venus"], "correct": 1},
	{"q": "Boiling point of water?", "options": ["50 C", "75 C", "100 C", "150 C"], "correct": 2},
	{"q": "Which is a mammal?", "options": ["Shark", "Dolphin", "Trout", "Frog"], "correct": 1},
	{"q": "A spider has how many legs?", "options": ["6", "8", "10", "12"], "correct": 1},
	{"q": "Which is a prime number?", "options": ["9", "15", "17", "21"], "correct": 2},
	{"q": "Largest planet?", "options": ["Earth", "Saturn", "Jupiter", "Mars"], "correct": 2},
	{"q": "Which organ pumps blood?", "options": ["Lungs", "Heart", "Liver", "Brain"], "correct": 1}
]

var level_2_questions = [
	{"q": "What absorbs water in plants?", "options": ["Leaves", "Roots", "Flowers", "Fruit"], "correct": 1},
	{"q": "How do plants make food?", "options": ["Digestion", "Photosynthesis", "Fermentation", "Melting"], "correct": 1},
	{"q": "Which planet has rings?", "options": ["Mars", "Saturn", "Mercury", "Earth"], "correct": 1},
	{"q": "Hardest natural substance?", "options": ["Iron", "Quartz", "Diamond", "Granite"], "correct": 2},
	{"q": "Main gas in the air?", "options": ["Oxygen", "Nitrogen", "Hydrogen", "Helium"], "correct": 1},
	{"q": "Energy from the Sun?", "options": ["Solar", "Sound", "Wind", "Chemical"], "correct": 0},
	{"q": "Which animal lays eggs?", "options": ["Cat", "Whale", "Turtle", "Dog"], "correct": 2},
	{"q": "What do bees collect?", "options": ["Nectar", "Sand", "Bark", "Stone"], "correct": 0},
	{"q": "Which part makes seeds?", "options": ["Root", "Flower", "Stem", "Bark"], "correct": 1},
	{"q": "Frozen water is called?", "options": ["Steam", "Ice", "Mist", "Dew"], "correct": 1},
	{"q": "Which is a renewable source?", "options": ["Coal", "Petrol", "Sunlight", "Diesel"], "correct": 2},
	{"q": "What is Earth's shape?", "options": ["Cube", "Sphere-like", "Flat disc", "Cylinder"], "correct": 1},
	{"q": "Which animal changes colour?", "options": ["Camel", "Chameleon", "Rabbit", "Horse"], "correct": 1},
	{"q": "What carries water in plants?", "options": ["Xylem", "Petal", "Pollen", "Seed"], "correct": 0},
	{"q": "Which is a gas?", "options": ["Ice", "Oxygen", "Iron", "Salt"], "correct": 1}
]

var active_questions: Array = []

var emergency_questions = [
	{"q": "5 + 7 = ?", "options": ["10", "11", "12", "13"], "correct": 2},
	{"q": "9 x 3 = ?", "options": ["18", "27", "24", "21"], "correct": 1},
	{"q": "Capital of Japan?", "options": ["Seoul", "Tokyo", "Beijing", "Bangkok"], "correct": 1},
	{"q": "Opposite of hot?", "options": ["Warm", "Cold", "Dry", "Bright"], "correct": 1},
	{"q": "8 x 7 = ?", "options": ["54", "56", "64", "62"], "correct": 1},
	{"q": "Sun: planet or star?", "options": ["Planet", "Star", "Comet", "Asteroid"], "correct": 1},
	{"q": "How many days in a week?", "options": ["5", "6", "7", "8"], "correct": 2},
	{"q": "Which is a colour?", "options": ["Circle", "Blue", "Litre", "Heavy"], "correct": 1},
	{"q": "15 - 6 = ?", "options": ["7", "8", "9", "10"], "correct": 2},
	{"q": "Which animal barks?", "options": ["Cat", "Dog", "Cow", "Duck"], "correct": 1},
	{"q": "Half of 20?", "options": ["5", "10", "15", "20"], "correct": 1},
	{"q": "Which is a fruit?", "options": ["Carrot", "Potato", "Apple", "Onion"], "correct": 2}
]

func _ready() -> void:
	add_child(normal_timer)
	normal_timer.timeout.connect(_on_normal_timer_timeout)
	
	add_child(emergency_timer)
	emergency_timer.one_shot = true
	emergency_timer.timeout.connect(_on_emergency_timer_timeout)
	
	if player_bubble:
		player_bubble.reached_top.connect(_on_level_complete)
		player_bubble.hit_lava.connect(_on_game_over)
	
	for i in range(answer_buttons.size()):
		answer_buttons[i].pressed.connect(_on_answer_button_pressed.bind(i))
		
	if get_tree().current_scene.scene_file_path == "res://level_2.tscn":
		active_questions = level_2_questions
	else:
		active_questions = normal_questions
	load_next_question()

func _process(_delta: float) -> void:
	if not normal_timer.is_stopped():
		timer_label.text = "Time: " + str(ceil(normal_timer.time_left))
	elif not emergency_timer.is_stopped():
		timer_label.text = "EMERGENCY: " + str(ceil(emergency_timer.time_left))

func load_next_question() -> void:
	if current_question_index >= active_questions.size():
		current_question_index = 0
		
	var q_data = active_questions[current_question_index]
	setup_ui_for_question(q_data)
	normal_timer.start(normal_time_limit)

func trigger_emergency() -> void:
	is_emergency = true
	normal_timer.stop()
	
	
	var q_data = emergency_questions.pick_random()
	setup_ui_for_question(q_data)
	emergency_timer.start(emergency_time_limit)

func setup_ui_for_question(q_data: Dictionary) -> void:
	question_label.text = q_data["q"]
	current_correct_index = q_data["correct"]
	
	for i in range(answer_buttons.size()):
		if i < q_data["options"].size():
			answer_buttons[i].text = q_data["options"][i]
			answer_buttons[i].disabled = false
			answer_buttons[i].visible = true
		else:
			answer_buttons[i].visible = false

func _on_answer_button_pressed(button_index: int) -> void:
	for btn in answer_buttons:
		btn.disabled = true
		
	if button_index == current_correct_index:
		handle_correct_answer()
	else:
		handle_wrong_answer()

func handle_correct_answer() -> void:
	if is_emergency:
		is_emergency = false
		
		emergency_timer.stop()
		player_bubble.on_emergency_survived()
		
		await get_tree().create_timer(0.5).timeout
		load_next_question()
	else:
		normal_timer.stop()
		player_bubble.on_correct_answer()
		current_question_index += 1
		load_next_question()

func handle_wrong_answer() -> void:
	if is_emergency:
		emergency_timer.stop()
	else:
		normal_timer.stop()
		player_bubble.on_wrong_answer()
		trigger_emergency()

func _on_normal_timer_timeout() -> void:
	handle_wrong_answer()

func _on_emergency_timer_timeout() -> void:
	for btn in answer_buttons:
		btn.disabled = true

func _on_game_over() -> void:
	normal_timer.stop()
	emergency_timer.stop()
	if get_tree().current_scene.scene_file_path == "res://level_2.tscn":
		question_label.text = "GAME OVER - EATEN BY PLANTS!"
	else:
		question_label.text = "GAME OVER - MELTED IN LAVA!"
	
	for btn in answer_buttons:
		btn.hide()
	if timer_label:
		timer_label.text = ""
	
	if player_bubble:
		player_bubble.visible = false          # Makes the player disappear instantly
		player_bubble.set_physics_process(false) # Stops the player from continuing to fall


func _on_level_complete() -> void:
	normal_timer.stop()
	emergency_timer.stop()

	question_label.text = "LEVEL COMPLETE!"

	for btn in answer_buttons:
		btn.hide()

	await get_tree().create_timer(1.0).timeout

	var current_scene = get_tree().current_scene.scene_file_path
	var destination: String

	if current_scene == "res://level_2.tscn":
		destination = "res://Victory.tscn"
	else:
		destination = "res://level_2.tscn"

	var error = get_tree().change_scene_to_file(destination)

	if error != OK:
		push_error("Failed to load scene: " + destination)

func _on_lava_body_entered(body: Node2D) -> void:
	if body == player_bubble:
		_on_game_over()
