extends CanvasLayer


@onready var pause: TextureRect = $Pause
@onready var meter: ProgressBar = $Meter


func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("pause"):
		var tree = get_tree()
		tree.paused = not get_tree().paused
		pause.visible = not pause.visible


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_meter_value_changed(value: float) -> void:
	if meter.value != 100: return
	
	meter.self_modulate = Color(1, 0, 0)
	while meter.value == 100:
		var tween = create_tween()
		tween.tween_property(meter, "self_modulate:r", 0.5, 0.5)
		tween.tween_property(meter, "self_modulate:r", 1, 0.5)
		await tween.finished
	meter.self_modulate = Color(1, 1, 1)
