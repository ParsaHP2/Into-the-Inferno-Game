extends Area3D


const RESTORE_AMOUNT = 200
@onready var cube: MeshInstance3D = $plus/Cube


func _process(delta: float) -> void:
	cube.rotate_y(deg_to_rad(1.5))


func _on_body_entered(body: Node3D) -> void:
	if not body is Player or body.health >= Player.MAX_HEALTH or not cube.visible: return
	
	body.take_damage(-RESTORE_AMOUNT)
	
	queue_free()
