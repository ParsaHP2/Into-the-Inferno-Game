extends CharacterBody3D


signal health_changed(new_health)

const MOVE_DAMAGE = 30
const ERUPTION = preload("res://scenes/eruption.tscn")
const ENEMY_FIREBALL = preload("res://scenes/enemy_fireball.tscn")

@onready var animation_player: AnimationPlayer = $Model/AnimationPlayer
@onready var move_hitbox: Area3D = $MoveHitbox

var health: int = Global.BOSS_MAX_HEALTH
var player: Player # Assigned by the room
var direction: int = 1 # Left or right


func start() -> void:
	while health > 0:
		animation_player.play("idle")
		await get_tree().create_timer(3).timeout
		var random_attack = randi_range(1, 3)
		match random_attack:
			1: # Shoot fireball
				animation_player.play("shoot")
				await get_tree().create_timer(0.5).timeout
				var fireball = ENEMY_FIREBALL.instantiate()
				get_tree().current_scene.add_child(fireball)
				fireball.position = global_position + Vector3(-7 * direction, 5, 0)
				fireball.launch_with_target(player)
				await animation_player.animation_finished
			2: # Move
				animation_player.play("move")
				var down_tween = create_tween()
				down_tween.tween_property(self, "position:y", position.y + 2, 1)
				await animation_player.animation_finished
				move_hitbox.set_collision_mask_value(2, true)
				var tween = create_tween()
				tween.tween_property(self, "position", Vector3(-25 * direction, 1.5, 0), 3)
				tween.tween_property(self, "position:y", -1, 1)
				tween.step_finished.connect(func(step):
					if step == 0:
						move_hitbox.set_collision_mask_value(2, false)
						rotate_y(PI)
						position = Vector3(-9 * direction, -10, 0)
						animation_player.play("rise"))
				await tween.finished
				await animation_player.animation_finished
				direction *= -1
			3: # Eruption
				animation_player.play("shoot")
				var x = -5.0
				for i in 5:
					x *= direction
					
					var new_eruption = ERUPTION.instantiate()
					get_tree().current_scene.add_child(new_eruption)
					new_eruption.position.x = x
					new_eruption.end_early()
					
					x += 2.5
					await get_tree().create_timer(0.5).timeout


func take_damage(amount: int) -> void:
	if health == 0: return
	
	health = clamp(health - amount, 0, Global.BOSS_MAX_HEALTH)
	health_changed.emit(health)
	if health == 0:
		animation_player.play("death")


func _on_move_hitbox_body_entered(body: Node3D) -> void:
	if body is Player:
		player.take_damage(MOVE_DAMAGE)
		move_hitbox.set_collision_mask_value(2, false)
