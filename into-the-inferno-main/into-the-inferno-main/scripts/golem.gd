class_name Golem extends CharacterBody3D

signal health_changed(new_health)

const SPEED = 3.0
const CHARGE_SPEED = 10.0  # Faster speed for charge
const MOVE_DISTANCE = 5.0
const MAX_HEALTH = 250
const BASE_DAMAGE = 25
const ATTACK_DISTANCE = 2.1
const CHARGE_DISTANCE = 8.0  # Distance to trigger charge
const METER_FILL_AMOUNT = 20

@onready var model: Node3D = $Model
@onready var animation_player: AnimationPlayer = $Model/AnimationPlayer
@onready var detection_area: Area3D = $DetectionArea
@onready var health_bar: ProgressBar = $SubViewport/HealthBar
@onready var player: CharacterBody3D = null
@onready var attack_cooldown: Timer = $AttackCooldown

var health = MAX_HEALTH
var start_position: Vector3
var moving_left = true
var can_attack: bool = true
var charging: bool = false

func _ready():
	start_position = global_transform.origin  # Save starting position
	animation_player.play("idle")
	health_bar.value = MAX_HEALTH


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if player:
		var direction = (player.global_transform.origin - global_transform.origin).normalized()
		var distance_to_player = (player.position - position).length()
		
		if distance_to_player <= ATTACK_DISTANCE and can_attack:
			can_attack = false
			player.take_damage(BASE_DAMAGE + Global.bonus_monster_damage)
			attack_cooldown.start()
			
		if not charging:
			model.rotation.y = PI / 2 if direction.x > 0 else -PI / 2
			animation_player.play("charge")
			charging = true
			await get_tree().create_timer(1).timeout
			animation_player.play("charging")
			velocity.x = direction.x * CHARGE_SPEED
			await get_tree().create_timer(1).timeout
			animation_player.play("idle")
			velocity.x = 0
			await get_tree().create_timer(0.5).timeout
			charging = false
	#else:
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
	health_bar.value = clamp(health_bar.value - amount, 0, MAX_HEALTH)
	health_changed.emit(health_bar.value)
	if health_bar.value == 0:
		queue_free()
		
