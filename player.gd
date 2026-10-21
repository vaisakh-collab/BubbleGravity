extends CharacterBody2D

signal reached_top
signal hit_lava

enum State { HOVERING, FALLING, DEAD }
var current_state: State = State.HOVERING

@export_category("Bubble Physics")
@export var gravity: float = 120.0
@export var bob_amplitude: float = 15.0  # How high/low it bobs
@export var bob_frequency: float = 3.0   # How fast it bobs
@export var glide_amount: float = 120.0  # Pixels to move up on correct answer

@export_category("Bubble Visuals")
@export var bubble_sprites: Array[Texture2D] = [] # Drag Stage1 to Stage7 here
@export var emergency_fall_duration: float = 3.0
@onready var sprite_2d: Sprite2D = $Sprite2D

var base_y: float
var time_passed: float = 0.0
var screen_top_margin: float = 50.0
var current_degrade_stage: int = 0 	#Tracks stages 0 to 5 (Stage1 to Stage6)
var fall_timer: float = 0.0

func _ready() -> void:
	# Set the initial hover height to where you place it in the editor
	base_y = global_position.y
	update_sprite()

func _physics_process(delta: float) -> void:
	match current_state:
		State.HOVERING:
			time_passed += delta
			
			# Calculate the ideal Y position including the sine wave bob
			var target_y = base_y + sin(time_passed * bob_frequency) * bob_amplitude
			
			# Smoothly apply velocity towards the target to simulate thrust countering gravity
			var difference = target_y - global_position.y
			velocity.y = difference * 10.0  
			
			# Check win condition (reaching the top)
			if global_position.y <= screen_top_margin:
				emit_signal("reached_top")
				current_state = State.DEAD # Stop moving temporarily
				velocity.y = 0
				
		State.FALLING:
			# Thrust fails; gravity takes full control
			velocity.y += gravity * delta
			
			# Track time spent falling
			fall_timer += delta
			
			# Map the fall time across the 6 stages based on your custom duration
			var stage_index = int((fall_timer / emergency_fall_duration) * 6)
			current_degrade_stage = clamp(stage_index, 0, 5)
			update_sprite()
			
		State.DEAD:
			velocity = Vector2.ZERO

	move_and_slide()

# --- SPRITE HELPER ---

func update_sprite() -> void:
	if bubble_sprites.size() > current_degrade_stage:
		sprite_2d.texture = bubble_sprites[current_degrade_stage]

# --- GAME LOGIC TRIGGERS ---

func on_correct_answer() -> void:
	if current_state == State.HOVERING:
		# Shift the anchor point higher. The physics_process will smoothly glide it up.
		base_y -= glide_amount
		
		# Flash the "correct answer" sprite (Stage7 is at index 6) if available
		if bubble_sprites.size() > 6:
			sprite_2d.texture = bubble_sprites[6]
			await get_tree().create_timer(1.0).timeout
			update_sprite()

func on_wrong_answer() -> void:
	current_state = State.FALLING
	fall_timer = 0.0  # <--- Reset timer so the degradation starts fresh from Stage 1
	current_degrade_stage = 0
	update_sprite()

func on_emergency_survived() -> void:
	# Restore thrust engine, lock in the new lower position so they don't rubber-band up
	current_state = State.HOVERING
	base_y = global_position.y
	# Reset degradation back to healthy state (Stage1 at index 0)
	current_degrade_stage = 0
	update_sprite()

func _on_lava_area_entered(area: Area2D) -> void:
	# Connect your lava Area2D to this or check collisions
	emit_signal("hit_lava")
	current_state = State.DEAD
