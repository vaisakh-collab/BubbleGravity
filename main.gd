extends Node2D

@export_category("Game Connections")
@export var player_bubble: CharacterBody2D
@export var question_label: Label
@export var timer_label: Label
@export var emergency_overlay: ColorRect
@export var answer_buttons: Array[Button] = []

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
	{"q": "What force pulls objects to the ground?", "options": ["Magnetism", "Friction", "Gravity", "Inertia"], "correct": 2}
]

var emergency_questions = [
	{"q": "QUICK! 8 x 7 = ?", "options": ["54", "56", "64", "62"], "correct": 1},
	{"q": "Is the sun a planet or a star?", "options": ["Planet", "Star", "Asteroid", "Comet"], "correct": 1}
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
		
	if emergency_overlay:
		emergency_overlay.visible = false
	
	load_next_question()

func _process(_delta: float) -> void:
	if not normal_timer.is_stopped():
		timer_label.text = "Time: " + str(ceil(normal_timer.time_left))
	elif not emergency_timer.is_stopped():
		timer_label.text = "EMERGENCY: " + str(ceil(emergency_timer.time_left))

func load_next_question() -> void:
	if current_question_index >= normal_questions.size():
		current_question_index = 0
		
	var q_data = normal_questions[current_question_index]
	setup_ui_for_question(q_data)
	normal_timer.start(normal_time_limit)

func trigger_emergency() -> void:
	is_emergency = true
	normal_timer.stop()
	
	if emergency_overlay:
		emergency_overlay.visible = true
	
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
		if emergency_overlay:
			emergency_overlay.visible = false
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
	question_label.text = "GAME OVER - MELTED IN LAVA"
	if emergency_overlay:
		emergency_overlay.visible = true
	for btn in answer_buttons:
		btn.hide()

func _on_level_complete() -> void:
	normal_timer.stop()
	emergency_timer.stop()
	question_label.text = "LEVEL COMPLETE!"
	for btn in answer_buttons:
		btn.hide()
	
	await get_tree().create_timer(1.0).timeout
	var next_level = "res://level_2.tscn"
	var error = get_tree().change_scene_to_file(next_level)
	if error != OK:
		print("Failed to load next level: ", error)


func _on_lava_body_entered(body: Node2D) -> void:
	if body == player_bubble:
		_on_game_over()
