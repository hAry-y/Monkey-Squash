extends RayCast3D

var has_los := false

func _ready():
	enabled = true
	add_exception(get_parent())
	print("RayCast READY")

func _physics_process(_delta):
	has_los = false

	if is_colliding():
		var hit = get_collider()
		print("Ray hit:", hit.name)

		if hit and hit.is_in_group("player"):
			has_los = true
