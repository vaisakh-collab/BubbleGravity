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

var base_y: float
var time_passed: float = 0.0
var screen_top_margin: float = 50.0

func _ready() -> void:
	# Set the initial hover height to where you place it in the editor
	base_y = global_position.y

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
			
		State.DEAD:
			velocity = Vector2.ZERO

	move_and_slide()

# --- GAME LOGIC TRIGGERS ---

func on_correct_answer() -> void:
	if current_state == State.HOVERING:
		# Shift the anchor point higher. The physics_process will smoothly glide it up.
		base_y -= glide_amount

func on_wrong_answer() -> void:
	# Trigger visual degradation animation here (e.g., $AnimationPlayer.play("degrade"))
	current_state = State.FALLING

func on_emergency_survived() -> void:
	# Restore thrust engine, lock in the new lower position so they don't rubber-band up
	current_state = State.HOVERING
	base_y = global_position.y
	# Trigger repair animation here

func _on_lava_area_entered(area: Area2D) -> void:
	# Connect your lava Area2D to this or check collisions
	emit_signal("hit_lava")
	current_state = State.DEAD
