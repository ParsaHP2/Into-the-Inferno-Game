class_name Player extends CharacterBody3D

signal upgrades_cycled(previous_index: int, new_index: int)
signal beam_fired
signal damaged(killed: bool)
enum {IDLE, RUN, JUMP, STRESS, DASH, SHOOT, BEAM, DEATH}

const SPEED = 5.0
const JUMP_VELOCITY = 12.0
const GRAVITY_MULTIPLIER = 2.5
const DASH_SPEED = 20.0
const CLIMB_SPEED = 6.0
const LERP_VAL = 0.25
const MAX_HEALTH = 200
const BEAM_DAMAGE = 500
const FIREBALL = preload("res://scenes/fireball.tscn")

@onready var model: Node3D = $Model
@onready var beam: Area3D = $Model/Beam
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_player: AnimationPlayer = $Model/AnimationPlayer
@onready var dash_cooldown: Timer = $DashCooldown
@onready var shoot_cooldown: Timer = $ShootCooldown
@onready var shoot_sound: AudioStreamPlayer2D = $ShootSound
@onready var beam_sound: AudioStreamPlayer2D = $BeamSound

var health: int = MAX_HEALTH
var meter_value: int = 0
var direction_facing: float = 1.0 # Left or right
var shoot_left: bool = true # Alternate hands when firing
var dashing: bool = false
var beaming: bool = false
var can_dash: bool = true
var can_shoot: bool = true
var touching_ladder: bool = false
var died: bool = false


func _unhandled_input(event: InputEvent) -> void:
	if Global.in_dialogue or died: return
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	if Input.is_action_just_pressed("cycle") and Global.selected_upgrade != -1:
		var next_upgrade_index = Global.selected_upgrade + 1
		while true:
			if next_upgrade_index == Global.upgrades.size():
				next_upgrade_index = 0
			var next_upgrade = Global.upgrades[next_upgrade_index]
			if next_upgrade.unlocked or next_upgrade.name == Global.upgrades[Global.selected_upgrade].name:
				upgrades_cycled.emit(Global.selected_upgrade, next_upgrade_index)
				Global.selected_upgrade = next_upgrade_index
				break
			next_upgrade_index += 1
			
	if Input.is_action_just_pressed("beam") and meter_value == 100 and not beaming:
		animate(BEAM)
		beaming = true
		await get_tree().create_timer(1.5).timeout
		beam.get_node("Outer").emitting = true
		beam.get_node("Inner").emitting = true
		beam_sound.play()
		var enemies = beam.get_overlapping_bodies()
		for enemy in enemies:
			if enemy is Player: continue
			if enemy.has_method("take_damage"):
				enemy.take_damage(BEAM_DAMAGE)
		await get_tree().create_timer(1.75).timeout
		velocity.y = 0
		beaming = false
		beam_fired.emit()


func _physics_process(delta: float) -> void:
	if died or beaming: return
	
	if Input.is_action_pressed("climb_up") and touching_ladder:
		velocity.y = CLIMB_SPEED
	
	if Input.is_action_just_pressed("shoot") and can_shoot and not Global.in_dialogue:
		# Closing a scroll, don't shoot if so
		var ui_focus = get_viewport().gui_get_focus_owner()
		if ui_focus and ui_focus is ColorRect:
			ui_focus.visible = false
			return
		
		can_shoot = false
		animate(SHOOT)
		shoot_sound.play()
		shoot_fireballs()
		shoot_cooldown.start()
		
	if Input.is_action_just_pressed("dash") and can_dash and not Global.in_dialogue:
		can_dash = false
		dashing = true
		velocity = Vector3(direction_facing * DASH_SPEED, 0, 0)
		dash_cooldown.start()
		await get_tree().create_timer(.2).timeout
		dashing = false
	
	if dashing:
		animate(DASH)
		move_and_slide()
		return
	
	var direction = Input.get_axis("left", "right")
	if direction != 0:
		if Global.in_dialogue: return
		animate(RUN)
		velocity.x = direction * SPEED
		if direction != direction_facing:
			var tween = create_tween()
			tween.tween_property(model, "rotation:y", deg_to_rad(direction * 90 - 90), 0.1)
		direction_facing = direction
	else:
		animate(IDLE)
		velocity.x = lerp(velocity.x, 0.0, LERP_VAL)
		
	if Global.in_dialogue: return
	if not is_on_floor():
		velocity += get_gravity() * GRAVITY_MULTIPLIER * delta
		animate(JUMP)

	move_and_slide()
	
	
func _on_dash_cooldown_timeout() -> void:
	can_dash = true


func _on_shoot_cooldown_timeout() -> void:
	can_shoot = true


func shoot_fireballs() -> void:
	var fireball_position = position + Vector3(0, 1.25, 0)
	var bonus_damage = meter_value / 3
	
	var fireball = FIREBALL.instantiate()
	fireball.initialize(fireball_position, direction_facing, Global.selected_upgrade == 0, "Straight", Global.selected_upgrade == 2)
	get_tree().root.add_child(fireball)
	fireball.damage += bonus_damage
	fireball.get_node("Core").material_override.albedo_color.g = 1.0 - meter_value / 100.0
	
	if Global.selected_upgrade == 1:
		var fireballs: Array[Fireball] = [fireball]
		fireballs.append(FIREBALL.instantiate())
		fireballs.back().initialize(fireball_position, direction_facing, false, "Up", false)
		get_tree().root.add_child(fireballs.back())
		fireballs.append(FIREBALL.instantiate())
		fireballs.back().initialize(fireball_position, direction_facing, false, "Down", false)
		get_tree().root.add_child(fireballs.back())
		
		for multi_fireball in fireballs:
			fireball.damage = (fireball.damage + bonus_damage) / 3


func take_damage(damage: int) -> void:
	if died: return
	
	health = clamp(health - damage, 0, MAX_HEALTH)
	died = health == 0
	if died and animation_player:
		animate(DEATH)
	damaged.emit(died)


func animate(animation):
	match animation:
		IDLE:
			animation_tree.set("parameters/Movement/transition_request", "Idle")
		RUN:
			animation_tree.set("parameters/Movement/transition_request", "Run")
		JUMP:
			animation_tree.set("parameters/Movement/transition_request", "Jump")
		STRESS:
			animation_tree.set("parameters/Movement/transition_request", "Stress")
		DASH:
			animation_tree.set("parameters/Dash/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		BEAM:
			animation_tree.set("parameters/Beam/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		DEATH:
			animation_tree.set("parameters/Death/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		SHOOT:
			if shoot_left:
				animation_tree.set("parameters/ShootLeft/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			else:
				animation_tree.set("parameters/ShootRight/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			shoot_left = not shoot_left
