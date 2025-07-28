extends CharacterBody3D


signal health_changed(new_health)

const BOSS_DURATION = 180.0 # Only for this particular boss because of rising lava
const BEAM_DAMAGE = 20
const ERUPTION = preload("res://scenes/eruption.tscn")
const ENEMY_FIREBALL = preload("res://scenes/enemy_fireball.tscn")

@onready var animation_player: AnimationPlayer = $Model/AnimationPlayer
@onready var beam: Area3D = $Beam

var rise_tween: Tween
var health: int = Global.BOSS_MAX_HEALTH
var player: Player # Assigned by the room
var touching_lava: bool = false
var t: float = 0.0


func _physics_process(delta: float) -> void:
	t += delta
	if touching_lava and t >= 0.1:
		player.take_damage(1)
		t = 0.0


func start() -> void:
	var rising = get_parent()
	
	rise_tween = create_tween()
	rise_tween.tween_property(rising, "position:y", 50, BOSS_DURATION)
	
	var lava = rising.get_node("Lava/Area3D")
	lava.body_entered.connect(func(body: Node):
		if body is Player:
			touching_lava = true)
	lava.body_exited.connect(func(body: Node):
		if body is Player:
			touching_lava = false)
	
	while health > 0:
		animation_player.play("idle")
		await get_tree().create_timer(3).timeout
		if health == 0: return
		
		var random_attack = randi_range(1, 3)
		match random_attack:
			1: # Shoot fireball
				animation_player.play("shoot")
				await get_tree().create_timer(0.5).timeout
				var fireball = ENEMY_FIREBALL.instantiate()
				get_tree().current_scene.add_child(fireball)
				fireball.position = global_position + Vector3(0, 1, 0)
				fireball.launch_with_target(player)
				await animation_player.animation_finished
			2: # Pillar
				var tween = create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				tween.tween_property(self, "position", Vector3(5, -1, 0), 1)
				tween.tween_property(self, "rotation:y", -PI / 2, 1)
				await tween.finished
				animation_player.play("pillar")
				var eruption = ERUPTION.instantiate()
				get_tree().current_scene.add_child(eruption)
				eruption.position = player.position
				eruption.end_early()
				await animation_player.animation_finished
				var tween2 = create_tween()
				tween2.tween_property(self, "position:y", 2, .5)
			3: # Beam
				var tween = create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				tween.tween_property(self, "position", Vector3(-5, -1, 0), 1)
				tween.tween_property(self, "rotation:y", PI / 2, 1)
				await tween.finished
				animation_player.play("beam")
				await get_tree().create_timer(1.3).timeout
				beam.get_node("Outer").emitting = true
				beam.get_node("Inner").emitting = true
				if beam.get_overlapping_bodies().has(player):
					player.take_damage(BEAM_DAMAGE)
				await animation_player.animation_finished
				var tween2 = create_tween()
				tween2.tween_property(self, "position:y", 2, .5)


func take_damage(amount: int) -> void:
	if health == 0: return
	
	health = clamp(health - amount, 0, Global.BOSS_MAX_HEALTH)
	health_changed.emit(health)
	if health == 0:
		rise_tween.stop()
		animation_player.play("death")
