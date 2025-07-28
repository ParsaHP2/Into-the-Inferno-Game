extends RigidBody3D


const FORCE = 10
const LIFETIME = 3
const DAMAGE = 15

func _ready() -> void:
	await get_tree().create_timer(LIFETIME).timeout
	queue_free()
	

func launch_with_target(target: Player) -> void:
	var direction = target.global_position + Vector3(0, 1, 0) - global_position
	var angle = atan2(direction.y, direction.x)
	launch_with_angle(angle)


func launch_with_angle(angle: float) -> void:
	rotate_z(angle)
	apply_central_impulse(transform.basis.x.normalized() * FORCE)
	

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Player:
		body.take_damage(DAMAGE)
		queue_free()
