extends CharacterBody3D


signal health_changed(new_health)

const ATTACK_COOLDOWN = 3.0
const ENEMY_FIREBALL = preload("res://scenes/enemy_fireball.tscn")

@onready var animation_player: AnimationPlayer = $Model/AnimationPlayer

var health: int = Global.BOSS_MAX_HEALTH
var player: Player # Assigned by the room
var destinations: Array[Node] # Also assigned by the room
var tween: Tween
var t: float = 0.0
var angle_offset: float = 0


func start() -> void:
	animation_player.play("crawl")
	while health > 0:
		var destination = destinations[randi_range(0, 4)].position
		tween = create_tween()
		tween.tween_property(self, "position", destination, 3)
		await tween.finished


func _physics_process(delta: float) -> void:
	if tween == null: return 
	
	t += delta
	if health == 0 or !tween.is_running() or t < ATTACK_COOLDOWN: return
	
	t = 0.0
	var scene = get_tree().current_scene
	for i in 4:
		var new_fireball = ENEMY_FIREBALL.instantiate()
		scene.add_child(new_fireball)
		new_fireball.position = global_position
		new_fireball.launch_with_angle(PI / 2 * i + angle_offset)
	angle_offset += PI / 4
	
	
func freeze(freeze_time) -> void:
	tween.pause()
	animation_player.pause()
	await get_tree().create_timer(freeze_time).timeout
	tween.play()
	animation_player.play()
	

func take_damage(amount: int) -> void:
	if health == 0: return
	
	health = clamp(health - amount, 0, Global.BOSS_MAX_HEALTH)
	health_changed.emit(health)
	if health == 0:
		animation_player.play("death")
