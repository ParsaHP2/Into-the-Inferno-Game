class_name Sorcerer extends CharacterBody3D


signal health_changed(new_health)

const MAX_HEALTH = 130
const METER_FILL_AMOUNT = 15
const ENEMY_FIREBALL = preload("res://scenes/enemy_fireball.tscn")

@onready var model: Node3D = $Model
@onready var animation_player: AnimationPlayer = $Model/AnimationPlayer
@onready var detection_area: Area3D = $DetectionArea
@onready var health_bar: ProgressBar = $SubViewport/HealthBar
@onready var attack_cooldown: Timer = $AttackCooldown


func _ready() -> void:
	if health_bar == null: return 
	
	animation_player.play("idle")
	health_bar.value = MAX_HEALTH


func _on_attack_cooldown_timeout() -> void:
	for body in detection_area.get_overlapping_bodies():
		if body is Player:
			var direction = (body.global_transform.origin - global_transform.origin).normalized()
			model.rotation.y = PI / 2 if direction.x > 0 else -PI / 2
			animation_player.play("shoot")
			var new_fireball = ENEMY_FIREBALL.instantiate()
			get_tree().current_scene.add_child(new_fireball)
			new_fireball.position = position + Vector3(0, 1, 0)
			new_fireball.launch_with_target(body)
			await animation_player.animation_finished
			animation_player.play("idle")


func take_damage(amount: int) -> void:
	if health_bar == null: return 
	
	health_bar.value = clamp(health_bar.value - amount, 0, MAX_HEALTH)
	health_changed.emit(health_bar.value)
	if health_bar.value == 0:
		queue_free()
