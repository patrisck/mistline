extends VehicleBody3D
class_name Car
## Simcade RWD car with power-over drift and a third-person chase camera.
##
## Drift emerges from PHYSICS, not assists: torque vs rear grip. In low gears
## the high torque (big gear ratio) overwhelms the reduced rear grip and the
## back steps out; in high gears there isn't enough torque, so it stays
## planted — like real life. Rear-wheel drive (traction rear, steering front).
##
## Enter/exit (click / F), manual gearbox (E up / Q down).

@export_group("Drivetrain")
@export var max_engine_force: float = 1200.0
@export var max_brake: float = 5.0
@export var max_steer: float = 0.55
@export var steer_speed: float = 2.5
## index 0=Reverse, 1=Neutral, 2..=1st..5th
@export var gear_ratios: Array[float] = [-2.8, 0.0, 2.6, 1.7, 1.2, 0.95, 0.78]

@export_group("Grip (drift tuning)")
## Front grip > rear grip so the rear breaks loose under power (RWD drift).
@export var front_grip: float = 4.5
@export var rear_grip: float = 2.5
## While the handbrake is held, rear grip drops to this (locks the rear -> slide).
@export var handbrake_rear_grip: float = 0.6
## Wheel roll torque. LOWER = more roll-stable (0 = won't tip); higher = leans/tips.
@export var roll_influence: float = 0.0
## Suspension stiffness (N/mm). Higher = less sag/less body movement.
@export var suspension_stiffness: float = 150.0

@export_group("Chase camera")
@export var cam_distance: float = 6.0
@export var cam_height: float = 2.4
@export var cam_look_height: float = 1.0
@export var cam_follow_speed: float = 6.0

var _occupied: bool = false
var _driver: Node = null
var _gear: int = 1
var _steer: float = 0.0
var _cam_pos: Vector3 = Vector3.ZERO

@onready var _camera: Camera3D = $ChaseCamera
@onready var _exit_point: Marker3D = $ExitPoint
@onready var _hud: CanvasLayer = $CarHUD
@onready var _speed_label: Label = $CarHUD/Panel/VBox/Speed
@onready var _gear_label: Label = $CarHUD/Panel/VBox/Gear
@onready var _front_wheels: Array = [$WheelFL, $WheelFR]
@onready var _rear_wheels: Array = [$WheelRL, $WheelRR]


func _ready() -> void:
	add_to_group("interactable")
	_hud.visible = false
	_apply_grip(false)


func get_prompt() -> String:
	return "[LMB] Enter car"


func interact(player: Node) -> void:
	_enter(player)


func _enter(player: Node) -> void:
	_driver = player
	_occupied = true
	_gear = 1
	if player.has_method("enter_vehicle"):
		player.enter_vehicle()
	_snap_camera()
	_camera.current = true
	_hud.visible = true


func _exit_car() -> void:
	_occupied = false
	_hud.visible = false
	engine_force = 0.0
	brake = max_brake
	steering = 0.0
	if _driver != null and _driver.has_method("exit_vehicle"):
		_driver.exit_vehicle(_exit_point.global_transform)
	_driver = null


func _unhandled_input(event: InputEvent) -> void:
	if not _occupied:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			_shift(1)
		elif event.keycode == KEY_Q:
			_shift(-1)
		elif event.keycode == KEY_F:
			_exit_car()


func _shift(dir: int) -> void:
	_gear = clampi(_gear + dir, 0, gear_ratios.size() - 1)


func _physics_process(delta: float) -> void:
	if not _occupied:
		return
	var throttle := Input.get_action_strength("move_forward")
	var brake_in := Input.get_action_strength("move_back")
	var steer_in := Input.get_action_strength("move_left") - Input.get_action_strength("move_right")
	var handbrake := Input.is_action_pressed("jump")

	# Handbrake drops rear grip (locks the rear -> slide). Also keeps grip in
	# sync with live-tuned values from the debug menu.
	_apply_grip(handbrake)

	# Sign flipped: the car's front (wheels/camera) is at -Z, but
	# VehicleBody3D's positive engine_force pushes toward +Z.
	engine_force = -throttle * max_engine_force * gear_ratios[_gear]
	brake = brake_in * max_brake

	_steer = move_toward(_steer, steer_in * max_steer, steer_speed * delta)
	steering = _steer
	_update_hud()


func _process(delta: float) -> void:
	if _occupied:
		_update_camera(delta)


# --------------------------------------------------------------------------
# Grip / drift
# --------------------------------------------------------------------------

func _apply_grip(handbrake: bool) -> void:
	for w in _front_wheels:
		w.wheel_friction_slip = front_grip
		w.wheel_roll_influence = roll_influence
		w.suspension_stiffness = suspension_stiffness
	var rg := handbrake_rear_grip if handbrake else rear_grip
	for w in _rear_wheels:
		w.wheel_friction_slip = rg
		w.wheel_roll_influence = roll_influence
		w.suspension_stiffness = suspension_stiffness


# --------------------------------------------------------------------------
# Third-person chase camera (position lags -> shows the drift angle nicely)
# --------------------------------------------------------------------------

func _car_back_dir() -> Vector3:
	var fwd := -global_transform.basis.z
	fwd.y = 0.0
	if fwd.length() < 0.01:
		fwd = Vector3.FORWARD
	return -fwd.normalized()


func _cam_target() -> Vector3:
	return global_position + _car_back_dir() * cam_distance + Vector3.UP * cam_height


func _snap_camera() -> void:
	_cam_pos = _cam_target()
	_camera.global_position = _cam_pos
	_camera.look_at(global_position + Vector3.UP * cam_look_height, Vector3.UP)


func _update_camera(delta: float) -> void:
	# Frame-rate independent smoothing.
	var t := 1.0 - exp(-cam_follow_speed * delta)
	_cam_pos = _cam_pos.lerp(_cam_target(), t)
	_camera.global_position = _cam_pos
	_camera.look_at(global_position + Vector3.UP * cam_look_height, Vector3.UP)


# --------------------------------------------------------------------------
# HUD
# --------------------------------------------------------------------------

func _update_hud() -> void:
	_speed_label.text = "%d km/h" % int(linear_velocity.length() * 3.6)
	_gear_label.text = "Gear: %s" % _gear_name()


func _gear_name() -> String:
	if _gear == 0:
		return "R"
	if _gear == 1:
		return "N"
	return str(_gear - 1)
