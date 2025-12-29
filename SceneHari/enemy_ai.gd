extends CharacterBody3D

# Movement variables
var speed = 3.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var target = null

# Reference to the search area
@onready var search_area = $SearchArea
@onready var los_ray = $LOSRay

var last_known_pos = Vector3.ZERO
var reached_memory = true


func _ready():
	add_to_group("enemies")
	# Connect area signals for body detection
	search_area.body_entered.connect(_on_search_area_body_entered)
	search_area.body_exited.connect(_on_search_area_body_exited)

	print("SearchArea:", search_area)
	print("LOSRay:", los_ray)


func _physics_process(delta):
	# 1. Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 2. Check Line of Sight (LOS)
	var can_see_target = false
	
	if target:
		# Update ray direction toward player
		var local_target_pos = los_ray.to_local(target.global_position)
		los_ray.target_position = local_target_pos.normalized() * 20.0
		
		# Check if the ray is hitting the target (ignoring walls/obstacles)
		if los_ray.is_colliding() and los_ray.get_collider() == target:
			can_see_target = true
			last_known_pos = target.global_position # Update memory
			reached_memory = false

	# 3. Decision Making: Where are we moving?
	var move_destination = Vector3.ZERO
	var active_movement = false

	if can_see_target:
		# STATE: CHASE
		move_destination = target.global_position
		active_movement = true
	elif not reached_memory:
		# STATE: SEARCH (Go to last known spot)
		move_destination = last_known_pos
		active_movement = true
		
		# Check if we have arrived at the memory spot
		if global_position.distance_to(last_known_pos) < 0.5:
			reached_memory = true
			active_movement = false
			print("Reached last seen location. Target lost.")

	# 4. Apply Velocity based on the destination
	if active_movement:
		var direction = (move_destination - global_position).normalized()
		direction.y = 0 # Keep movement on the horizontal plane
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		
		# Optional: Make the enemy look where they are going
		look_at(Vector3(move_destination.x, global_position.y, move_destination.z), Vector3.UP)
	else:
		# STATE: IDLE
		velocity.x = 0
		velocity.z = 0

	# 5. Execute Movement
	move_and_slide()

func _on_search_area_body_entered(body):
	# Check if the body is the player (assuming player is named "Cube")
	if body.is_in_group("player"):
		target = body
		print("TARGET SET:", body)

func _on_search_area_body_exited(body):
	# Clear target if player leaves the area
	if body == target:
		target = null
		print("TARGET CLEARED")
