extends CharacterBody3D

@onready var visuals: Node3D = $Visuals
var current_dir = 8
var is_firing = false

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("Fire") and not is_firing:
		start_firing()
	
	var input_dir := Input.get_vector("Left", "Right", "Up", "Down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction != Vector3.ZERO:
		velocity.x = direction.x * 5.0
		velocity.z = direction.z * 5.0
		determine_direction(direction)
	else:
		velocity.x = move_toward(velocity.x, 0, 5.0)
		velocity.z = move_toward(velocity.z, 0, 5.0)
	
	update_sprite_visiblity()
	move_and_slide()

func determine_direction(dir: Vector3):
	var angle = atan2(dir.x, dir.z)
	var dir_idx = int(round(angle / (PI/4))) % 8
	var mapping = {0:8, 1:7, 2:6, 3:5, 4:4, -3:3, -2:2, -1:1}
	current_dir = mapping.get(dir_idx, 8)

func start_firing():
	is_firing = true
	var fire_anim = "Stand_fire_dir" + str(current_dir)
	var active_sprite = visuals.get_node("AnimatedSprite3D_Dir" + str(current_dir))
	
	active_sprite.play(fire_anim)
	await active_sprite.animation_finished
	is_firing = false

func update_sprite_visiblity():
	if is_firing: return
	if visuals.get_child_count() == 0:
		return
	
	for sprite in visuals.get_children():
		sprite.hide()
	
	var node_name = "AnimatedSprite3D_Dir" + str(current_dir)
	var active_sprite = visuals.get_node(node_name) as AnimatedSprite3D
	active_sprite.show()
	
	if velocity.length() > 0.1:
		active_sprite.play("Walk_fire_dir" + str(current_dir))
	else:
		active_sprite.play("Idle_dir" + str(current_dir))
