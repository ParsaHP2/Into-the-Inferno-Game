class_name Imp extends CharacterBody3D


signal health_changed(new_health)

const SPEED = 3.0
const MOVE_DISTANCE = 2.5  # How far the enemy moves before turning
const MAX_HEALTH = 100
const BASE_DAMAGE = 10
const ATTACK_DISTANCE = 1.2
const METER_FILL_AMOUNT = 10

@onready var model: Node3D = $Model
@onready var animation_player: AnimationPlayer = $Model/AnimationPlayer
@onready var detection_area: Area3D = $DetectionArea
@onready var health_bar: ProgressBar = $SubViewport/HealthBar
@onready var player: CharacterBody3D = null  # Reference to player
@onready var attack_cooldown: Timer = $AttackCooldown

var start_position: Vector3
var moving_left = true  # Track movement direction
var can_attack: bool = true

func _ready():
	if health_bar == null: return 
	
	start_position = global_transform.origin  # Save starting position
	health_bar.value = MAX_HEALTH

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if player:
		animation_player.play("run")
		var direction = (player.global_transform.origin - global_transform.origin).normalized()
		model.rotation.y = PI / 2 if direction.x > 0 else -PI / 2
		velocity.x = direction.x * SPEED
		var distance_to_player = (player.position - position).length()
		if distance_to_player <= ATTACK_DISTANCE and can_attack:
			can_attack = false
			player.take_damage(BASE_DAMAGE + Global.bonus_monster_damage)
			attack_cooldown.start()
	else:
		animation_player.play("idle")
		velocity.x = 0
		## Move left or right
		#velocity.x = -SPEED if moving_left else SPEED
#
		## Check if the enemy has moved the full distance
		#var distance_moved = abs(global_transform.origin.x - start_position.x)
		#if distance_moved >= MOVE_DISTANCE:
			#moving_left = !moving_left  # Switch direction
			#start_position = global_transform.origin  # Reset starting position

	move_and_slide()


func _on_detection_area_body_entered(body: Node3D) -> void:
	if body is Player:
		player = body


func _on_detection_area_body_exited(body: Node3D) -> void:
	if body is Player:
		player = null


func _on_attack_cooldown_timeout() -> void:
	can_attack = true


func take_damage(amount: int) -> void:
	if health_bar == null: return 
	
	health_bar.value = clamp(health_bar.value - amount, 0, MAX_HEALTH)
	health_changed.emit(health_bar.value)
	if health_bar.value == 0:
		queue_free()
