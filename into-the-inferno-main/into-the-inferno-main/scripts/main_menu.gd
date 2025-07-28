extends Control


func _on_start_pressed() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://scenes/rooms/beginning_room.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()
