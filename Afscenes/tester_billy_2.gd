extends CharacterBody3D

@export var speed = 50

# --- Camera & Aiming Setup ---
@onready var camera_node = $SpringArm3D/CameraSocket/Camera3D
var is_aiming = false
var default_fov = 105.0
var aim_fov = 30.0 

# Offset for "Over the Shoulder" (Right side, slightly forward)
var default_offset = Vector3(0, 0, 0)
var aim_offset = Vector3(3.5, -1.0, -1.0)

# New Variables for Rotation
var default_rotation_x = -25.0 # current "HD-2D" downward angle
var aim_rotation_x = 0.0      # Almost flat (0 is perfectly straight forward)

@onready var visuals = $Visuals
@onready var sprites = {
	"up" : $Visuals/AS3D_Top,
	"up_right": $Visuals/AS3D_TopRight,
	"right": $Visuals/AS3D_Right,
	"down_right": $Visuals/AS3D_BottomRight,
	"down": $Visuals/AS3D_Bottom,
	"down_left": $Visuals/AS3D_BottomLeft,
	"left": $Visuals/AS3D_Left,
	"up_left": $Visuals/AS3D_TopLeft
}

@onready var camera = get_viewport().get_camera_3d()

# Current facing direction (Default: down)
var current_facing = "down" 

func _physics_process(_delta):
	# 1. Check Aim Input (New Logic)
	handle_aiming_input()

	# 2. Get Movement Input
	var input_dir = Input.get_vector("Left", "Right", "Up", "Down")
	
	# 3. Calculate Direction relative to Camera
	var direction = Vector3.ZERO
	if camera:
		var cam_rot = camera.global_transform.basis.get_euler().y
		direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).rotated(Vector3.UP, cam_rot)
	else:
		direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# 4. Move Character
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

	# 5. Visual Logic (Modified to support Aiming)
	update_visuals(direction)


# --- New Helper Functions ---

func handle_aiming_input():
	if Input.is_action_just_pressed("Aim"):
		toggle_aim(true)
	elif Input.is_action_just_released("Aim"):
		toggle_aim(false)

func toggle_aim(state: bool):
	is_aiming = state
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	
	if is_aiming:
		# Zoom In & Move Camera
		tween.tween_property(camera_node, "fov", aim_fov, 0.2)
		tween.tween_property(camera_node, "position", aim_offset, 0.2)
		
		# ROTATE UP: Look forward like a shooter, not down like an RPG
		tween.tween_property(camera_node, "rotation_degrees:x", aim_rotation_x, 0.2)
	else:
		# Reset to Default
		tween.tween_property(camera_node, "fov", default_fov, 0.2)
		tween.tween_property(camera_node, "position", default_offset, 0.2)
		
		# ROTATE DOWN: Back to HD-2D isometric view
		tween.tween_property(camera_node, "rotation_degrees:x", default_rotation_x, 0.2)

func update_visuals(move_vec: Vector3):
	# PRIORITY 1: If Aiming, force the "up" (Back View) sprite
	if is_aiming:
		if current_facing != "up":
			current_facing = "up" # Force "Top" sprite
			apply_visual_switch()
		
		# Still play animation if moving, otherwise stop
		if move_vec:
			get_active_sprite().play()
		else:
			get_active_sprite().stop()
			get_active_sprite().frame = 0
		return # Stop here! Do not run the normal direction logic below.

	# PRIORITY 2: Normal Movement Logic (Existing Code)
	if move_vec:
		update_facing(move_vec) # Calculate generic 8-way direction
		get_active_sprite().play()
	else:
		get_active_sprite().stop()
		get_active_sprite().frame = 0

func update_facing(move_vec: Vector3):
	# Calculate angle of movement
	var angle = atan2(move_vec.x, move_vec.z)
	
	# Snap the angle to 8 directions
	var octant = int(round(angle / (PI / 4.0)))
	octant = wrapi(octant, 0, 8)
	
	var direction_names = [
		"down",       # 0
		"down_right", # 1
		"right",      # 2
		"up_right",   # 3
		"up",         # 4 (This is AS3D_Top)
		"up_left",    # 5
		"left",       # 6
		"down_left"   # 7
	]
	
	var new_facing = direction_names[octant]
	
	if new_facing != current_facing:
		current_facing = new_facing
		apply_visual_switch()

func apply_visual_switch():
	for key in sprites:
		if key == current_facing:
			sprites[key].visible = true
			sprites[key].play()
		else:
			sprites[key].visible = false

func get_active_sprite():
	return sprites[current_facing]
