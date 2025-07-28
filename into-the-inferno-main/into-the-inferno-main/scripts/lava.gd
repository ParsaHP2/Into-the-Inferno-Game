extends Area3D


var player: Player
var t: float = 0.0


func _process(delta: float) -> void:
	if not player: return
	
	t += delta
	if t >= 0.1:
		player.take_damage(1)
		t = 0.0


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		player = body


func _on_body_exited(body: Node3D) -> void:
	player = null
