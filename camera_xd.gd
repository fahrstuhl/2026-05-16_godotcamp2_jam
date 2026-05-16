class_name CameraXD
extends Camera3D

@onready var directional_light: DirectionalLight3D = %DirectionalLight3D

@export var base_fov: float = 75.0 # in degrees

@export var target: Node3D

@export var transition_duration: float = 1.0

@export var projection_type: CameraXD.ProjectionType = CameraXD.ProjectionType.ORTHOGRAPHIC

const MIN_FOV = 1.0

var tween: Tween

enum ProjectionType {
	ORTHOGRAPHIC,
	PERSPECTIVE
}

signal projection_type_changed(projection_type: CameraXD.ProjectionType)

func _ready() -> void:
	match projection_type:
		CameraXD.ProjectionType.ORTHOGRAPHIC:
			projection = Camera3D.PROJECTION_ORTHOGONAL
			fov = MIN_FOV
		
		CameraXD.ProjectionType.PERSPECTIVE:
			projection = Camera3D.PROJECTION_PERSPECTIVE
			fov = base_fov

func set_projection_type(new_projection_type: CameraXD.ProjectionType) -> void:
	if projection_type == new_projection_type:
		return
	
	projection_type = new_projection_type
	if is_instance_valid(tween):
		tween.kill()
	
	tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD).set_parallel(true)
	
	match projection_type:
		CameraXD.ProjectionType.ORTHOGRAPHIC:
			tween.tween_method(update_dolly_zoom, fov, MIN_FOV, transition_duration)
			tween.tween_property(self, "position:y", 1.0, transition_duration)
			tween.tween_property(directional_light, "shadow_opacity", 0.0, transition_duration)
			await tween.finished
			projection = Camera3D.PROJECTION_ORTHOGONAL
		
		CameraXD.ProjectionType.PERSPECTIVE:
			projection = Camera3D.PROJECTION_PERSPECTIVE
			tween.tween_method(update_dolly_zoom, fov, base_fov, transition_duration)
			tween.tween_property(self, "position:y", 3.0, transition_duration)
			tween.tween_property(directional_light, "shadow_opacity", 1.0, transition_duration)
	
	projection_type_changed.emit(projection_type)

func size_from_fov(target_fov: float) -> float:
	return (2 * tan(deg_to_rad(target_fov) / 2))

func update_dolly_zoom(new_fov: float) -> void:
	var target_distance := -to_local(target.global_position).z
	size = target_distance * size_from_fov(fov)
	var new_target_distance := size / size_from_fov(new_fov)
	var dolly_step := new_target_distance - target_distance
	global_position += global_basis.z * dolly_step
	fov = new_fov
	environment.sky_custom_fov = new_fov

	# var dist := global_position.distance_to(target.global_position)
	# far = dist + 400.0
	# near = max(dist - 200, 0.05)
	# DebugDraw2D.set_text("Far", far, 0, Color.RED, 30)
	# DebugDraw2D.set_text("Dist", dist, 0, Color.HOT_PINK, 30)
	# DebugDraw2D.set_text("Near", near, 0, Color.GREEN, 30)

	# TODO: This is a hacky hack
	attributes.dof_blur_amount = remap(fov, MIN_FOV, base_fov, 0.0, 0.1)

func _process(delta):
	if projection_type == CameraXD.ProjectionType.PERSPECTIVE || projection == Camera3D.PROJECTION_PERSPECTIVE:
		look_at(target.global_position)
		# TODO: Hacky
		rotation.y = 0.0
		rotation.z = 0.0
	else:
		var current_rot := Quaternion(transform.basis.orthonormalized())
		var target_rot := Quaternion.IDENTITY
		var smoothrot := current_rot.slerp(target_rot, delta)
		rotation = smoothrot.get_euler()
