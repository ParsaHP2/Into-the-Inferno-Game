extends Room


const CHALLENGE_DURATION = 30.0
const IMP = preload("res://scenes/imp.tscn")
const SORCEROR = preload("res://scenes/sorceror.tscn")
const GOLEM = preload("res://scenes/golem.tscn")

@onready var scroll: Area3D = $Scroll
@onready var scrolls_ui: Control = $UI/ScrollsUI
@onready var enemies: Node3D = $Enemies
@onready var hit_sound: AudioStreamPlayer2D = $HitSound
@onready var kill_sound: AudioStreamPlayer2D = $KillSound

var challenge_activated: bool = false

func _ready() -> void:
	super()
	for enemy in get_node("Enemies").get_children():
		Global.max_score += enemy.METER_FILL_AMOUNT
	Global.max_score += 300 # For challenge monsters
	var level_name = name.erase(0, 5)
	scroll.body_entered.connect(func(body: Node3D):
		if body is Player:
			var scroll_ui: ColorRect = scrolls_ui.find_child(level_name)
			scroll_ui.visible = true
			scroll_ui.grab_focus()
			Global.scrolls_collected[level_name] = true)
			
	for enemy in enemies.get_children():
		enemy.health_changed.connect(func(health: int):
			hit_sound.play()
			if health != 0: return
			
			Global.current_score += enemy.METER_FILL_AMOUNT
			kill_sound.play()
			if name != "BeginningRoom":
				player.meter_value = clamp(player.meter_value + enemy.METER_FILL_AMOUNT, 0, 100)
			else:
				player.meter_value = 100
			meter.value = player.meter_value)
			
	if name == "BeginningRoom": return
			
	var entrance: MeshInstance3D = $Entrance
	var exit: MeshInstance3D = $Exit
	var challenge_trigger: Area3D = $ChallengeTrigger
	var spawner: Node3D = $Spawner
	var spawner_2: Node3D = $Spawner2
	challenge_trigger.body_entered.connect(func(body: Node3D):
		if not body is Player or challenge_activated: return
		
		challenge_activated = true
		entrance.visible = true
		entrance.get_node("StaticBody3D").set_collision_layer_value(1, true)
		
		var previous_monster = null
		for i in range(CHALLENGE_DURATION / 2):
			var new_monster
			if i < 5:
				new_monster = IMP.instantiate()
			elif i < 10:
				new_monster = SORCEROR.instantiate()
			else:
				new_monster = GOLEM.instantiate()
			get_tree().current_scene.add_child(new_monster)
			var spawner_position = spawner.position if randi_range(0, 1) == 0 else spawner_2.position
			new_monster.position = spawner_position + Vector3((0.25 if spawner_position == spawner.position
			 else -0.25) * i, 0, 0)
			previous_monster = new_monster
			
			new_monster.health_changed.connect(func(health: int):
				hit_sound.play()
				if health != 0: return
				
				Global.current_score += new_monster.METER_FILL_AMOUNT
				kill_sound.play()
				if name != "BeginningRoom":
					player.meter_value = clamp(player.meter_value + new_monster.METER_FILL_AMOUNT, 0, 100)
				else:
					player.meter_value = 100
				meter.value = player.meter_value)
			
			await get_tree().create_timer(2).timeout
		
		entrance.queue_free()
		exit.queue_free())
