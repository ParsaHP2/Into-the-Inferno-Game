extends Node3D


const ERUPTION_DAMAGE = 20

@onready var hitbox: Area3D = $Hitbox
@onready var lava: GPUParticles3D = $Lava
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	await get_tree().create_timer(1).timeout
	lava.emitting = true
	animation_player.play("erupt")


func _on_hitbox_body_entered(body: Node3D) -> void:
	if not body is Player: return
	
	body.take_damage(ERUPTION_DAMAGE)


func end_early() -> void:
	await get_tree().create_timer(2.9).timeout
	queue_free()
