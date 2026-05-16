class_name Player
extends CharacterBody3D

@onready var camera: Camera3D = %Camera3D
@onready var fps_cam_target: Node3D = $FPSCamTarget
@onready var top_down_cam_target: Node3D = %TopDownCamTarget

@export var move_speed := 10.0
@export var look_sensitivity := 0.002

@export var is_fps := true

@export var tween_duration := 1.0
@export var fps_fov := 75.0
@export var top_down_size := 20.0
@export var top_down_fov := 11.5

var cam_tween: Tween
var top_down_progress := 0.0

func _physics_process(delta: float) -> void:
	velocity = Vector3.ZERO
	if Input.is_action_just_pressed("switch_perspective"):
		is_fps = not is_fps
		if is_instance_valid(cam_tween):
			cam_tween.kill()
		cam_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
		cam_tween.tween_property(self, "top_down_progress", 1.0 if not is_fps else 0.0, tween_duration)
	if is_fps:
		var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * move_speed
			velocity.z = direction.z * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
	else:
		var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		var direction := (camera.basis * Vector3(input_dir.x, -input_dir.y, 0)).normalized()
		if direction:
			velocity.x = direction.x * move_speed
			velocity.z = direction.z * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)

	move_and_slide()

	if is_fps:
		top_down_cam_target.global_position.x = global_position.x
		top_down_cam_target.global_position.z = global_position.z

func size_from_fov(target_fov: float) -> float:
	return (2 * tan(deg_to_rad(target_fov) / 2))

func smoothst(x: float) -> float:
	return x * x * (3 - 2 * x)

func _process(delta: float) -> void:
	camera.global_transform = fps_cam_target.global_transform.interpolate_with(top_down_cam_target.global_transform, smoothst(top_down_progress))
	camera.fov = lerp(fps_fov, top_down_fov, top_down_progress)
	if top_down_progress == 1.0:
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		camera.size = top_down_size
		fps_cam_target.rotation.x = 0.0
	else:
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if not is_fps:
		var mouse_pos := get_viewport().get_mouse_position()
		var world_pos := camera.project_ray_origin(mouse_pos)
		# rotate player y to look at mouse position:
		var to_mouse := world_pos - global_position
		to_mouse.y = 0
		if to_mouse.length() > 0.1:
			look_at(global_position + to_mouse, Vector3.UP)
	

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if is_fps:
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * look_sensitivity)
			fps_cam_target.rotate_x(-event.relative.y * look_sensitivity)
			fps_cam_target.rotation_degrees.x = clamp(fps_cam_target.rotation_degrees.x, -90, 90)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == Key.KEY_ESCAPE:
		get_tree().quit()
