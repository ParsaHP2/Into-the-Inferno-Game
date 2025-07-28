extends Area3D


@export var connection: String = ""


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		get_tree().call_deferred("change_scene_to_file", connection)
