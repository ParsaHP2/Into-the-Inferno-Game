extends Node3D

signal froze(PAUSE_TIME)

const PAUSE_TIME = 3.0

@onready var targets: Node3D = $Targets
@onready var platforms: Node3D = $Platforms
var frozen: bool = false


func freeze_platforms() -> void:
	if frozen: return
	frozen = true
	froze.emit(PAUSE_TIME)
	
	for path: Path3D in platforms.get_children():
		path.get_node("AnimationPlayer").pause()
		var mesh = path.get_node("AnimatableBody3D/MeshInstance3D")
		mesh.material_override.albedo_color.g = 1
		var tween = create_tween()
		tween.tween_property(mesh, "material_override:albedo_color:g", 0, PAUSE_TIME)
		
	await get_tree().create_timer(PAUSE_TIME).timeout
	
	for path: Path3D in platforms.get_children():
		path.get_node("AnimationPlayer").play()
		
	frozen = false
