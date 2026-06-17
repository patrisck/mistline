class_name Vehicle
extends RigidBody3D

## Carro arcade baseado em raycast: suspensao (mola+amortecedor), tracao,
## esterco e grip lateral. Faz o proprio raycast, entao funciona com Jolt.
## Entrar/sair sao chamados pelo PlayerInteractor.
## Aceleracoes saem direto em m/s^2 pois (forca_por_roda * n_rodas / massa) == coeficiente.

@export_group("Suspensao")
@export var suspension_rest := 0.3
@export var wheel_radius := 0.3
@export var spring_strength := 30.0
@export var spring_damping := 3.0

@export_group("Tracao")
@export var engine_force := 12.0
@export var throttle_response := 2.5
@export var max_speed := 22.0
@export var reverse_speed := 8.0
@export var rolling_resistance := 0.05

@export_group("Direcao")
@export var max_steer_deg := 32.0
@export var steer_speed := 5.0
@export var tire_grip := 9.0

@export_group("Freio")
@export var brake_strength := 2.0

@export_group("Acoes")
@export var throttle_action := "move_forward"
@export var reverse_action := "move_back"
@export var steer_left_action := "move_left"
@export var steer_right_action := "move_right"
@export var handbrake_action := "jump"
@export var exit_action := "exit_vehicle"

var controlled := false

var _driver: Node
var _steer := 0.0
var _throttle := 0.0

@onready var _wheels: Array = [$WheelFL, $WheelFR, $WheelRL, $WheelRR]
@onready var _camera: Camera3D = $InteriorCamera
@onready var _exit_point: Node3D = $ExitPoint


func _ready() -> void:
	for w in _wheels:
		w.add_exception(self)
		w.target_position = Vector3(0, -(suspension_rest + wheel_radius), 0)


func enter(driver: Node) -> void:
	if _driver:
		return
	_driver = driver
	if driver.has_method("set_active"):
		driver.set_active(false)
	_camera.current = true
	controlled = true


func exit() -> void:
	if _driver == null:
		return
	controlled = false
	_steer = 0.0
	var d := _driver
	_driver = null
	if d is Node3D:
		(d as Node3D).global_position = _exit_point.global_position
	if d is CharacterBody3D:
		(d as CharacterBody3D).velocity = Vector3.ZERO
	if d.has_method("set_active"):
		d.set_active(true)


func _physics_process(delta: float) -> void:
	if controlled and Input.is_action_just_pressed(exit_action):
		exit()
		return

	_update_steering(delta)
	_update_throttle(delta)

	var up := global_transform.basis.y
	for i in _wheels.size():
		var wheel = _wheels[i]
		if not wheel.is_colliding():
			continue
		_apply_suspension(wheel, up)
		_apply_tire(wheel, i < 2)


func _update_steering(delta: float) -> void:
	var steer_input := 0.0
	if controlled:
		steer_input = Input.get_action_strength(steer_left_action) - Input.get_action_strength(steer_right_action)
	_steer = move_toward(_steer, deg_to_rad(max_steer_deg) * steer_input, steer_speed * delta)


func _update_throttle(delta: float) -> void:
	var raw := 0.0
	if controlled:
		raw = Input.get_action_strength(throttle_action)
	_throttle = move_toward(_throttle, raw, throttle_response * delta)


func _apply_suspension(wheel: RayCast3D, up: Vector3) -> void:
	var rel := wheel.global_position - global_position
	var ray_len := suspension_rest + wheel_radius
	var dist := wheel.global_position.distance_to(wheel.get_collision_point())
	var offset := ray_len - dist
	var point_vel := linear_velocity + angular_velocity.cross(rel)
	var force_mag := (offset * spring_strength - point_vel.dot(up) * spring_damping) * mass
	apply_force(up * force_mag, rel)


func _apply_tire(wheel: RayCast3D, is_front: bool) -> void:
	var rel := wheel.global_position - global_position
	var basis := global_transform.basis
	var forward := -basis.z
	var right := basis.x
	if is_front:
		forward = forward.rotated(basis.y, _steer)
		right = right.rotated(basis.y, _steer)

	var point_vel := linear_velocity + angular_velocity.cross(rel)
	var per_wheel := mass / _wheels.size()

	# Grip lateral: cancela o deslizamento de lado da roda.
	apply_force(right * (-point_vel.dot(right) * tire_grip * per_wheel), rel)

	# Longitudinal: tracao, re, freio de mao e resistencia ao rolamento.
	var forward_speed := linear_velocity.dot(forward)
	var long := -forward_speed * rolling_resistance
	if controlled:
		var throttle := _throttle
		var reverse := Input.get_action_strength(reverse_action)
		if throttle > 0.0 and forward_speed < max_speed:
			long += throttle * engine_force
		if reverse > 0.0 and forward_speed > -reverse_speed:
			long -= reverse * engine_force
		if Input.is_action_pressed(handbrake_action):
			long += -forward_speed * brake_strength
	apply_force(forward * (long * per_wheel), rel)
