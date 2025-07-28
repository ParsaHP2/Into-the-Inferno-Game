extends CharacterBody3D


const CRATE_SPAWN_TIME = 30.0

@export var speed: float = 2.0  # Speed of movement
@export var distance: float = 2.0  # Maximum distance to move

var start_position: Vector3
var direction: int = 1  # Moving forward or backward
var is_active: bool = false  # Control movement


func _ready() -> void:
	start_position = position  # Store the initial position
	visible = false  # Hide the box initially

func _process(delta: float) -> void:
	if not is_active: return

	position.y += direction * speed * delta
	
	# Reverse direction if exceeding the distance limit
	if abs(position.y - start_position.y) >= distance:
		direction *= -1  # Change direction

func spawn() -> void:
	await get_tree().create_timer(CRATE_SPAWN_TIME).timeout
	is_active = true
	visible = true
	set_collision_mask_value(2, true)
	get_node("Area3D").set_collision_mask_value(2, true)
	var current_scene = get_tree().current_scene
	if current_scene.name == "BossUp":
		position.y = current_scene.get_node("Rising").position.y + 3
		start_position = position
	
	
func reset() -> void:
	is_active = false
	visible = false
	set_collision_mask_value(2, false)
	get_node("Area3D").set_collision_mask_value(2, false)
	spawn()
