extends MeshInstance3D


const BREAK_TIME = 1.0
const GONE_TIME = 3.0

@onready var static_body_3d: StaticBody3D = $StaticBody3D
@onready var area_3d: Area3D = $Area3D

var landed_on: bool = false


func _on_area_3d_body_entered(body: Node3D) -> void:
	if not body is Player or landed_on: return
	
	landed_on = true
	var tween = create_tween()
	tween.tween_property(self, "material_override:albedo_color:a", 0, BREAK_TIME)
	
	await tween.finished
	
	static_body_3d.set_collision_layer_value(1, false)
	
	await get_tree().create_timer(GONE_TIME).timeout
	
	if area_3d.get_overlapping_bodies().has(body):
		body.position.x = position.x - 2
		
	static_body_3d.set_collision_layer_value(1, true)
	landed_on = false
	material_override.albedo_color.a = 1
