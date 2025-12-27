extends CharacterBody3D

var speed = 5.0
var acceleration = 5.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var jump_area = $JumpArea

func _ready():
    jump_area.body_entered.connect(_on_jump_area_entered)

func _on_jump_area_entered(body):
    if body.is_in_group("enemies"):
        var dir = (global_position - body.global_position).normalized()
        body.velocity = dir * 8.0 + Vector3.UP * 5.0

func _physics_process(delta):
    if not is_on_floor():
        velocity.y -= gravity * delta

    var input_dir = Vector2.ZERO
    if Input.is_action_pressed("ui_up"):
        input_dir.y += 1
    if Input.is_action_pressed("ui_down"):
        input_dir.y -= 1
    if Input.is_action_pressed("ui_right"):
        input_dir.x -= 1
    if Input.is_action_pressed("ui_left"):
        input_dir.x += 1

    input_dir = input_dir.normalized()
    var direction = Vector3(input_dir.x, 0, input_dir.y)
    var target_velocity = direction * speed

    # Smoothly interpolate velocity
    velocity.x = lerp(velocity.x, target_velocity.x, acceleration * delta)
    velocity.z = lerp(velocity.z, target_velocity.z, acceleration * delta)

    move_and_slide()