extends CharacterBody3D


signal health_changed(new_health)
signal movement_finished

enum {NONE, WALKING, JUMPING}

const JUMP_HEIGHT = 6
const ERUPTION = preload("res://scenes/eruption.tscn")
const ENEMY_FIREBALL = preload("res://scenes/enemy_fireball.tscn")

@onready var model: Node3D = $Model
@onready var animation_player: AnimationPlayer = $Model/AnimationPlayer

var health: int = Global.BOSS_MAX_HEALTH * 3
var player: Player # Assigned by the room
var direction_facing: int = -1

# For walking and jumping
var destination_x: int = 0
var movement = NONE

# For jumping
var start_position: Vector3 = Vector3.ZERO
var middle_position: Vector3 = Vector3.ZERO
var t: float = 0.0


func _physics_process(delta: float) -> void:
	if movement == WALKING:
		move_and_slide()
		if abs(destination_x - position.x) <= 0.1 or abs(position.x) > 10:
			velocity.x = 0
			movement = NONE
			movement_finished.emit()
	elif movement == JUMPING:
		t += delta
		var end_position = Vector3(destination_x, 0, 0)
		position = middle_position + pow(1 - t, 2) * (start_position - middle_position) + pow(t, 2) * (end_position - middle_position)
		if t >= 1.0:
			movement = NONE
			movement_finished.emit()


func start() -> void:
	while health > 0:
		animation_player.play("idle")
		await get_tree().create_timer(0.5).timeout
		var random_attack = randi_range(1, 4)
		match random_attack:
			1: # Walk
				destination_x = randi_range(-10, 10)
				direction_facing = 1 if destination_x > position.x else -1
				
				velocity.x = Player.SPEED * direction_facing
				model.rotation.y = PI / 2  * direction_facing
				
				animation_player.play("run")
				movement = WALKING
				await movement_finished
			2: # Jump 
				destination_x = randi_range(-10, 10)
				direction_facing = 1 if destination_x > position.x else -1
				
				start_position = position
				middle_position = start_position.lerp(Vector3(destination_x, 0, 0), 0.5) + Vector3(0, JUMP_HEIGHT, 0)
				t = 0.0
				model.rotation.y = PI / 2  * direction_facing
				
				animation_player.play("jump")
				movement = JUMPING
				
				await get_tree().create_timer(0.5).timeout
				
				var new_fireball = ENEMY_FIREBALL.instantiate()
				get_tree().current_scene.add_child(new_fireball)
				new_fireball.position = position + Vector3(0, 1, 0)
				new_fireball.launch_with_angle(7 * PI / 6 if direction_facing == -1 else 11 * PI / 6)
				
				await movement_finished
			3: # Multi fireball
				var left_angle = PI if direction_facing == -1 else 0
				var fireballs = [ENEMY_FIREBALL.instantiate()]
				fireballs.back().launch_with_angle(left_angle)
				fireballs.append(ENEMY_FIREBALL.instantiate())
				fireballs.back().launch_with_angle(left_angle + PI / 4)
				fireballs.append(ENEMY_FIREBALL.instantiate())
				fireballs.back().launch_with_angle(left_angle - PI / 4)
				
				var current_scene = get_tree().current_scene
				for fireball in fireballs:
					current_scene.add_child(fireball)
					fireball.position = position + Vector3(0, 1, 0)
			4: # Backwards fireball
				var new_fireball = ENEMY_FIREBALL.instantiate()
				get_tree().current_scene.add_child(new_fireball)
				new_fireball.position = position + Vector3(0, 1, 0)
				new_fireball.launch_with_angle(0)
				
				var new_fireball2 = ENEMY_FIREBALL.instantiate()
				get_tree().current_scene.add_child(new_fireball2)
				new_fireball2.position = position + Vector3(0, 1, 0)
				new_fireball2.launch_with_angle(PI)


func take_damage(amount: int) -> void:
	if health == 0: return
	
	health = clamp(health - amount, 0, Global.BOSS_MAX_HEALTH)
	health_changed.emit(health)
	if health == 0:
		animation_player.play("death")
