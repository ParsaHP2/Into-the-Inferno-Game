class_name Room extends Node3D


@export var dialogue_resource: DialogueResource
@onready var player: Player = $Player
@onready var health_bar: ProgressBar = $UI/HealthBar
@onready var meter: ProgressBar = $UI/Meter
@onready var upgrades: HBoxContainer = $UI/Upgrades


func _ready() -> void:
	if Global.selected_upgrade != -1:
		upgrades.get_child(Global.selected_upgrade).modulate.a = 1
	
	player.upgrades_cycled.connect(func(previous_index: Variant, new_index: Variant):
		upgrades.get_child(previous_index).modulate.a = 0.5
		upgrades.get_child(new_index).modulate.a = 1)
		
	player.beam_fired.connect(func():
		player.meter_value = 0
		meter.value = 0)
		
	player.damaged.connect(func(killed: bool):
		health_bar.value = player.health
		if killed:
			var tween = create_tween()
			tween.tween_property(get_node("UI/FadeToBlack"), "color:a", 1, 2)
			await tween.finished
			get_tree().call_deferred("change_scene_to_file", "res://scenes/rooms/hub.tscn"))
		
	if dialogue_resource:
		DialogueManager.show_dialogue_balloon(dialogue_resource, "start")
		
	var final_boss_door: Area3D = get_node_or_null("DoorFinalBoss")
	if final_boss_door != null and Global.num_upgrades_unlocked == 3:
		get_node("Lucifer").visible = false
		final_boss_door.visible = true
		final_boss_door.body_entered.connect(func(body: Node):
			for scroll in Global.scrolls_collected:
				if not Global.scrolls_collected[scroll]:
					get_tree().call_deferred("change_scene_to_file", "res://scenes/rooms/boss_avatris.tscn")
					return
			get_tree().call_deferred("change_scene_to_file", "res://scenes/rooms/boss_lucifer.tscn"))
