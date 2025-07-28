extends CharacterBody3D


signal health_changed(new_health)

const LUNGE_DAMAGE = 30
const BEAM_DAMAGE = 40
const ERUPTION = preload("res://scenes/eruption.tscn")

@onready var model: Node3D = $Model
@onready var animation_player: AnimationPlayer = $Model/AnimationPlayer
@onready var lunge_hitbox: Area3D = $LungeHitbox
@onready var beam: Area3D = $Model/Beam
@onready var beam_sound: AudioStreamPlayer2D = $BeamSound

var health: int = Global.BOSS_MAX_HEALTH * 3
var player: Player # Assigned by the room


func start() -> void:
	while health > 0:
		animation_player.play("idle")
		await get_tree().create_timer(1.5).timeout
		var random_attack = randi_range(1, 3)
		match random_attack:
			1: # Lunge
				model.rotation.y =  PI / 2 if player.position.x > position.x else -PI /2
				animation_player.play("lunge")
				
				await get_tree().create_timer(0.8).timeout
				
				lunge_hitbox.set_collision_mask_value(2, true)
				var tween = create_tween()
				tween.tween_property(self, "position", player.position, 0.5)
				tween.tween_interval(0.5)
				tween.tween_property(self, "position:y", 3, 0.5)
				
				await tween.finished
				
				lunge_hitbox.set_collision_mask_value(2, false)
			2: # Beam
				var tween = create_tween()
				tween.tween_property(self, "position:y", 1, 0.5)
				model.rotation.y =  PI / 2 if player.position.x > position.x else -PI /2
				animation_player.play("beam")
				
				await get_tree().create_timer(2.75).timeout
				
				beam.get_node("Outer").emitting = true
				beam.get_node("Inner").emitting = true
				beam_sound.play()
				if beam.get_overlapping_bodies().has(player):
					player.take_damage(BEAM_DAMAGE)
					
				await get_tree().create_timer(2).timeout
				
				var tween2 = create_tween()
				tween2.tween_property(self, "position:y", 3, 0.5)
			3: # Eruptions
				var tween = create_tween().set_parallel()
				tween.tween_property(self, "position:x", player.position.x, 1)
				tween.tween_property(model, "rotation:y", 0, 1)
				animation_player.play("eruptions")
				
				var new_eruption = ERUPTION.instantiate()
				get_tree().current_scene.add_child(new_eruption)
				new_eruption.position.x = player.position.x
				new_eruption.position.y = -1
				new_eruption.scale = Vector3(2, 2, 2)
				new_eruption.end_early()
				
				await animation_player.animation_finished


func take_damage(amount: int) -> void:
	if health == 0: return
	
	health = clamp(health - amount, 0, Global.BOSS_MAX_HEALTH)
	health_changed.emit(health)
	if health == 0:
		animation_player.play("death")


func _on_lunge_hitbox_body_entered(body: Node3D) -> void:
	if body is Player:
		player.take_damage(LUNGE_DAMAGE)
		lunge_hitbox.set_collision_mask_value(2, false)
