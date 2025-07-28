extends Control


@onready var score_label: Label = $ScoreLabel


func _ready() -> void:
	score_label.text = "LEVEL COMPLETE\nYOUR SCORE IS:\n" + str(Global.current_score) + "\nRANK: "
	
	var first_interval_max = Global.max_score / 3
	var second_interval_max = Global.max_score * 2 / 3
	var final_score = 0
	if Global.current_score > second_interval_max:
		score_label.text += "A"
	elif Global.current_score > first_interval_max:
		score_label.text += "B"
	else:
		score_label.text += "C"


func _on_continue_pressed() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://scenes/rooms/hub.tscn")
