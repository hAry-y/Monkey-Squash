extends CharacterBody3D

# Movement variables
var speed = 3.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


var normal_radius = .5
var alert_radius = 1.0
@onready var search_shape = $SearchArea/CollisionShape3D

# Reference to the search area
@onready var search_area = $SearchArea
@onready var los_ray = $LOSRay
#@onready var player_search_area = target.get_node("JumpArea")

var last_known_pos = Vector3.ZERO
var reached_memory = true

var jump_force = 5.0 # How high 

var target = Global.targetGlobal



#RE ENFORCEMENT
@export var monkey_scene: PackedScene # Drag the monkey.tscn here in the Inspector
var has_called_backups = false

func _ready():
	
	add_to_group("enemies")
	# Connect area signals for body detection
	search_area.body_entered.connect(_on_search_area_body_entered)
	search_area.body_exited.connect(_on_search_area_body_exited)

	print(Global.targetGlobal)



	#print("SearchArea:", search_area)
	#print("LOSRay:", los_ray)

	
func get_random_point_around_player(player_pos: Vector3, distance: float) -> Vector3:
	var angle = randf_range(0, 2 * PI) # Pick a random direction (0 to 360 degrees)
	var offset = Vector3(cos(angle) * distance, 0, sin(angle) * distance)
	return player_pos + offset

func _physics_process(delta):
	#var target = Global.targetGlobal
	# gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# (LOS)
	var can_see_target = false

	
	
	if Global.targetGlobal:
		target = Global.targetGlobal
		var head_offset = Vector3(0, 1, 0)
		var head_position = target.global_position + head_offset
		#var local_target_pos = los_ray.to_local(head_position)
		# Update ray direction toward player
		var local_target_pos = los_ray.to_local(head_position)
		los_ray.target_position = local_target_pos
		
		#if the ray hitting the target 
		if los_ray.is_colliding() and los_ray.get_collider() == target:
			can_see_target = true
			last_known_pos = target.global_position # Update memory
			reached_memory = false

	#Decision Making
	var move_destination = Vector3.ZERO
	var active_movement = false

	if can_see_target:
		# STATE: CHASE
		move_destination = target.global_position
		active_movement = true

		#alert radius while chasing
		search_shape.shape.radius = alert_radius
		
	elif not reached_memory:
		# STATE: SEARCH (Go to last known spot)
		move_destination = last_known_pos
		active_movement = true
		
		# KEEP radius large while searching
		#search_shape.shape.radius = alert_radius
		
		# Check if we have arrived at the memory spot
		if global_position.distance_to(last_known_pos) < 0.5:
			reached_memory = true
			active_movement = false
			print("Reached last seen location. Target lost.")

	else:
		
		# RESET radius
		search_shape.shape.radius = normal_radius

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

	#execute Movement
	move_and_slide()

	if active_movement and is_on_floor():
		# Check if we hit a wall
			if is_on_wall():
				var collision = get_last_slide_collision()
				if collision:
					var collider = collision.get_collider()

					# Jump if it's not the player 
					if collider.is_in_group("jumpable"):
						velocity.y = jump_force

func spawn_reinforcements():
	for i in range(2): # Number of monkeys to spawn
		if monkey_scene:
			var new_monkey = monkey_scene.instantiate()
			
			# Position them slightly offset from the current monkey
			var offset = Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
			new_monkey.global_position = global_position + offset
			
			# Add to the main scene tree
			get_tree().current_scene.add_child(new_monkey)
			
			# Ensure the new monkey knows who to chase immediately
			# Note: Since your script already checks Global.targetGlobal, 
			# they will start chasing on their next physics frame.

func _on_search_area_body_entered(body):
	# Check if the body is the player
	if body.is_in_group("player"):
		#target = body
		Global.targetGlobal = body
		print("TARGET SET:", body)

		# Call for reinforcements
		if not has_called_backups:
			spawn_reinforcements()
			has_called_backups = true

func _on_search_area_body_exited(body):
	#var target = Global.targetGlobal
	# Clear target if player leaves the area
	if body == Global.targetGlobal:
		#Global.targetGlobal = null
		print("escaped search area")
