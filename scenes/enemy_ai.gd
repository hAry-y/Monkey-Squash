extends CharacterBody3D

# Movement variables
var speed = 3.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var target = null

# Reference to the search area
@onready var search_area = $SearchArea



func _ready():
	add_to_group("enemies")
	# Connect area signals for body detection
	search_area.body_entered.connect(_on_search_area_body_entered)
	search_area.body_exited.connect(_on_search_area_body_exited)

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Move toward target if one exists
	if target:
		var direction = (target.global_position - global_position).normalized()
		direction.y = 0 # Keep movement on XZ plane
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		# Stop horizontal movement if no target
		velocity.x = 0
		velocity.z = 0

	# Move the enemy
	move_and_slide()

func _on_search_area_body_entered(body):
	# Check if the body is the player (assuming player is named "Cube")
	if body.name == "CharacterBody3D":
		target = body

func _on_search_area_body_exited(body):
	# Clear target if player leaves the area
	if body.name == "CharacterBody3D":
		target = null
