class_name PlayerController
extends CharacterBody3D

## Controller de jogador em primeira pessoa do Mistline.
## Yaw (horizontal) aplicado no corpo; pitch (vertical) no Head; view bobbing na camera.

@export_group("Movimento")
@export var walk_speed := 4.0
@export var sprint_speed := 7.0
@export var jump_velocity := 4.5
@export var ground_acceleration := 12.0
@export var air_acceleration := 3.0
@export var friction := 50.0
@export var air_friction := 2.0

@export_group("Camera")
@export var mouse_sensitivity := 0.0025
@export_range(0.0, 90.0) var pitch_limit_deg := 89.0

@export_group("View Bobbing")
@export var bob_enabled := true
@export var bob_frequency := 2.0
@export var bob_amplitude := 0.05
@export var bob_return_speed := 10.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var _pitch := 0.0
var _bob_time := 0.0
var _camera_base_position: Vector3


func _ready() -> void:
	_camera_base_position = camera.position
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		var limit := deg_to_rad(pitch_limit_deg)
		_pitch = clampf(_pitch - event.relative.y * mouse_sensitivity, -limit, limit)
		head.rotation.x = _pitch
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_jump()
	_handle_movement(delta)
	move_and_slide()
	_update_head_bob(delta)


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta


func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity


func _handle_movement(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var target_speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed

	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	if direction != Vector3.ZERO:
		var accel := ground_acceleration if is_on_floor() else air_acceleration
		horizontal = horizontal.move_toward(direction * target_speed, accel * delta)
	else:
		var decel := friction if is_on_floor() else air_friction
		horizontal = horizontal.move_toward(Vector3.ZERO, decel * delta)

	velocity.x = horizontal.x
	velocity.z = horizontal.z


func _update_head_bob(delta: float) -> void:
	var target := _camera_base_position
	if bob_enabled and is_on_floor():
		var horizontal_speed := Vector2(velocity.x, velocity.z).length()
		if horizontal_speed > 0.1:
			_bob_time += delta * horizontal_speed
			target.y += sin(_bob_time * bob_frequency) * bob_amplitude
			target.x += cos(_bob_time * bob_frequency * 0.5) * bob_amplitude * 0.5
	camera.position = camera.position.lerp(target, bob_return_speed * delta)
