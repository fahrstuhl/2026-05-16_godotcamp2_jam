extends CharacterBody3D

signal retarget

@export var movement_speed: float = 9
@export var topdown: bool = false: set = set_topdown
@onready var navigation_agent: NavigationAgent3D = get_node("NavigationAgent3D")

func set_topdown(value: bool):
	topdown = value
	if not is_node_ready():
		return
	if topdown:
		$TopdownShape.show()
		$TopdownShape.disabled = false
		$FPSShape.hide()
		$FPSShape.disabled = true
	else:
		$TopdownShape.hide()
		$TopdownShape.disabled = true
		$FPSShape.show()
		$FPSShape.disabled = false

func _ready() -> void:
	set_topdown(topdown)
	$Retarget.timeout.connect(func()->void: retarget.emit($"."))
	if topdown:
		$TopdownShape/Sprite3D.play("default")
	else:
		$FPSShape/Sprite3D.play("default")

func set_movement_target(movement_target: Vector3):
	navigation_agent.set_target_position(movement_target)

func _physics_process(delta):
	# Do not query when the map has never synchronized and is empty.
	if NavigationServer3D.map_get_iteration_id(navigation_agent.get_navigation_map()) == 0:
		return
	if navigation_agent.is_navigation_finished():
		return

	var next_path_position: Vector3 = navigation_agent.get_next_path_position()
	velocity = global_position.direction_to(next_path_position) * movement_speed
	move_and_slide()
