extends Room


@export var boss: CharacterBody3D
@export var dialogue_boss_defeat: DialogueResource
@onready var boss_health_bar: ProgressBar = $UI/BossHealth
@onready var cycle_hint: Label = $UI/CycleHint
@onready var hit_sound: AudioStreamPlayer2D = $HitSound
@onready var crate: CharacterBody3D = $Crate
var exit: Area3D


func _ready() -> void:
	exit = get_node_or_null("Exit")
	if exit != null:
		exit.visible = false
	boss.player = player
	if boss.name == "Crawler":
		boss.destinations = get_node("Points").get_children()
		get_node("FreezePlatforms").froze.connect(func(freeze_time):
			if boss != null:
				boss.freeze(freeze_time))
				
	var direction_name: String = name.erase(0,4)
	if direction_name == "Left" or direction_name ==  "Right" or direction_name == "Up":
		if Global.scrolls_collected.get(direction_name, false):
			dialogue_resource = load("res://dialogue/Boss" + direction_name + "/BeforeBoss" + direction_name + "ScrollsCollected.dialogue")
		else:
			dialogue_resource = load("res://dialogue/Boss" + direction_name + "/BeforeBoss" + direction_name + "ScrollsNotCollected.dialogue")
	else:
		var scrollsCollected: int = 0
		for scroll in Global.scrolls_collected:
			if Global.scrolls_collected[scroll]:
				scrollsCollected += 1
		if scrollsCollected == 3:
			dialogue_resource = load("res://dialogue/Lucifer/ConfrontingLuciferWith3Scrolls.dialogue")
		else:
			dialogue_resource = load("res://dialogue/Lucifer/ConfrontingLuciferWithout3Scrolls.dialogue")
	
	super()
	await Global.dialogue_Finished
	boss_health_bar.visible = true
	boss_health_bar.max_value = Global.BOSS_MAX_HEALTH
	boss_health_bar.value = boss.health
	boss.health_changed.connect(func(health: int):
		hit_sound.play()
		boss_health_bar.value = health
		player.meter_value = clamp(player.meter_value + 5, 0, 100)
		meter.value = player.meter_value
		if health == 0:
			boss_defeated())
	boss.start()
	crate.spawn()
	crate.get_node("Area3D").body_entered.connect(func(body: Node3D):
		if body is Player and crate.is_active:
			player.meter_value = clamp(player.meter_value + 50, 0, 100)
			meter.value = player.meter_value
			crate.reset())

func boss_defeated() -> void:
	await boss.get_node("Model/AnimationPlayer").animation_finished
	# Play dialogue agai
	var direction_name: String = name.erase(0,4)
	var regular_boss = direction_name == "Left" or direction_name ==  "Right" or direction_name == "Up"
	if regular_boss:
		if Global.scrolls_collected.get(direction_name, false):
			dialogue_boss_defeat = load("res://dialogue/Boss" + direction_name + "/AfterBoss" + direction_name + "ScrollsCollected.dialogue")
		else:
			dialogue_boss_defeat = load("res://dialogue/Boss" + direction_name + "/AfterBoss" + direction_name + "ScrollsNotCollected.dialogue")
	else:
		var scrollsCollected: int = 0
		for scroll in Global.scrolls_collected:
			if Global.scrolls_collected[scroll]:
				scrollsCollected += 1
		if scrollsCollected == 3:
			dialogue_boss_defeat = load("res://dialogue/Lucifer/DefeatingLuciferWith3Scrolls.dialogue")
		else:
			dialogue_boss_defeat = load("res://dialogue/Lucifer/DefeatingLuciferWithNoScrolls.dialogue")
	
	if dialogue_boss_defeat:
		DialogueManager.show_dialogue_balloon(dialogue_boss_defeat, "start")
		
	await Global.dialogue_Finished
	
	if not regular_boss:
		get_tree().call_deferred("change_scene_to_file", "res://scenes/end_screen.tscn")
		return
	
	boss.queue_free()
	
	var room = name.erase(0, 4)
	for upgrade in upgrades.get_children():
		upgrade.modulate.a = 0.5
	if room == "Right":
		Global.upgrades[0].unlocked = true
		Global.selected_upgrade = 0
	elif room == "Left":
		Global.upgrades[1].unlocked = true
		Global.selected_upgrade = 1
	elif room == "Up":
		Global.upgrades[2].unlocked = true
		Global.selected_upgrade = 2
		exit.position.y = get_node("Rising").position.y + 1.5
	upgrades.get_child(Global.selected_upgrade).modulate.a = 1
	
	exit.visible = true
	exit.set_collision_mask_value(2, true)
	get_node("Music").stop()
	Global.bonus_monster_damage += 10
	
	Global.num_upgrades_unlocked += 1
	if Global.num_upgrades_unlocked == 2:
		cycle_hint.visible = true
		await get_tree().create_timer(3).timeout
		cycle_hint.visible = false
	
