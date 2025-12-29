extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get gravity from project settings
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Track if player is currently shooting
var is_firing = false

@onready var sprite : AnimatedSprite3D = $AnimatedSprite3D


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not is_firing:
		velocity.y = JUMP_VELOCITY
	
	# Handle Shooting Input.
	if Input.is_action_just_pressed("ui_select"):
		start_firing()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction and not is_firing:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		# Flip sprite based on X movement
		if direction.x != 0:
			sprite.flip_h = direction.x < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	# Handle Animations
	update_animations(direction)
	move_and_slide()

func start_firing():
	is_firing = true
	sprite.play("Shooting")
	
	await sprite.animation_finished
	is_firing = false

func update_animations(direction):
	if is_firing:
		return
	
	# Checking if we are in air first
	if not is_on_floor():
		sprite.play("Jump")
		return
	
	# If we are on the ground, handle Run and Idle
	if direction != Vector3.ZERO:
		sprite.play("Run")
	else:
		sprite.play("Idle")
