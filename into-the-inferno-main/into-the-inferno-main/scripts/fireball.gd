class_name Fireball extends Area3D


const SPEED = 10

var damage = 10
# Assigned when player shoots
var velocity_x: float = 0.0
var velocity_y: float = 0.0
var big: bool = false

		
func initialize(_position: Vector3, direction_facing: int, _big: bool, angle: String, fast: bool) -> void:
	position = _position
	big = _big
	var speed = SPEED * 2 if fast else SPEED
	
	rotation.y = deg_to_rad(90 * direction_facing)
	if big:
		scale = Vector3(.75, .75, .75)
	if angle == "Straight":
		velocity_x = direction_facing * speed
		velocity_y = 0.0
	elif angle == "Up":
		velocity_x = speed * cos(PI / 4) * direction_facing
		velocity_y = speed * sin(PI / 4)
		rotation.x = deg_to_rad(-45)
	elif angle == "Down":
		velocity_x =  speed * cos(PI / 4) * direction_facing
		velocity_y = -speed * sin(PI / 4)
		rotation.x = deg_to_rad(45)


func _physics_process(delta):
	position.x += velocity_x * delta
	position.y += velocity_y * delta
	

func _on_body_entered(body: Node):
	if body is Player: return
	
	if body.has_method("take_damage"):
		body.take_damage(damage)
		if not big:
			queue_free()
		
	var body_parent = body.get_parent()
	if body_parent.name == "Targets":
		body_parent.get_parent().freeze_platforms()
		if not big:
			queue_free()
		

func _on_lifespan_timeout() -> void:
	queue_free()
