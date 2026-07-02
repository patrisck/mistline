extends VehicleBody3D
class_name Car
## Simcade RWD car with physics-based drift, a clutch/RPM engine, and a
## third-person chase camera.
##
## Godot's VehicleBody3D doesn't couple longitudinal wheelspin to lateral grip
## loss (the real "friction circle"), so pure engine force just accelerates and
## never breaks the rear loose. We approximate the friction circle in script:
## the harder the rear is driven (throttle x gear ratio, plus a clutch kick),
## the more rear grip is shed -> power-over drift that only happens in low gears,
## like real life. Counter-steer to hold the slide.
##
## Clutch (hold Shift): disconnects the engine from the wheels and lets the revs
## climb; release at high RPM to dump a torque "kick" that snaps the rear out.
## Gears (E up / Q down) shift instantly (no clutch needed to shift).
## Enter/exit: click / F.

@export_group("Drivetrain")
@export var max_engine_force: float = 2000.0
@export var max_brake: float = 5.0
@export var max_steer: float = 0.55
@export var steer_speed: float = 2.5
## index 0=Reverse, 1=Neutral, 2..=1st..5th
@export var gear_ratios: Array[float] = [-2.8, 0.0, 2.6, 1.7, 1.2, 0.95, 0.78]

@export_group("Engine / clutch")
@export var idle_rpm: float = 900.0
@export var redline_rpm: float = 7000.0
@export var rev_up_rate: float = 9000.0      # rpm/s while free-revving (clutch in)
@export var rev_down_rate: float = 5000.0
@export var rpm_per_speed: float = 150.0     # engaged rpm from speed x gear
## Release the clutch above this RPM to get a kick.
@export var clutch_kick_min_rpm: float = 3500.0
## Torque/grip-loss burst multiplier on a clutch kick.
@export var clutch_kick_strength: float = 2.5
## How long the kick lasts (seconds).
@export var clutch_kick_time: float = 0.5

@export_group("Grip / drift")
@export var front_grip: float = 4.0
@export var rear_grip: float = 3.0
## Rear grip while the handbrake is held (locks the rear -> slide).
@export var handbrake_rear_grip: float = 1.1
## Above this "drive" (throttle x gear ratio + kick) the rear starts losing grip.
@export var traction_break_point: float = 1.3
## How fast grip is lost past the break point.
@export var traction_sensitivity: float = 1.2
## Rear grip multiplier when fully broken loose (friction-circle approximation).
@export var drift_grip_factor: float = 0.35
@export var roll_influence: float = 0.0
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
var _rpm: float = 900.0
var _kick: float = 0.0
var _clutch_prev: bool = false
var _cam_pos: Vector3 = Vector3.ZERO

@onready var _camera: Camera3D = $ChaseCamera
@onready var _exit_point: Marker3D = $ExitPoint
@onready var _hud: CanvasLayer = $CarHUD
@onready var _speed_label: Label = $CarHUD/Panel/VBox/Speed
@onready var _gear_label: Label = $CarHUD/Panel/VBox/Gear
@onready var _rpm_label: Label = $CarHUD/Panel/VBox/RPM
@onready var _front_wheels: Array = [$WheelFL, $WheelFR]
@onready var _rear_wheels: Array = [$WheelRL, $WheelRR]


func _ready() -> void:
	add_to_group("interactable")
	_hud.visible = false
	_rpm = idle_rpm
	_apply_grip(0.0, false)


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
	var clutch := Input.is_action_pressed("sprint")

	_update_rpm(delta, throttle, clutch)
	_update_kick(delta, clutch)
	_apply_grip(throttle, handbrake)

	if clutch:
		engine_force = 0.0  # clutch disengaged: no power to the wheels
	else:
		# Torque rises with RPM (weak just off idle, strong up top).
		var rpm_factor := clampf(0.45 + 0.55 * (_rpm - idle_rpm) / (5000.0 - idle_rpm), 0.45, 1.0)
		var drive := throttle * max_engine_force * gear_ratios[_gear] * rpm_factor
		var kick := _kick * clutch_kick_strength * max_engine_force * gear_ratios[_gear]
		# Sign flipped: car front is at -Z, positive engine_force pushes +Z.
		engine_force = -(drive + kick)

	brake = brake_in * max_brake
	_steer = move_toward(_steer, steer_in * max_steer, steer_speed * delta)
	steering = _steer
	_update_hud()


func _process(delta: float) -> void:
	if _occupied:
		_update_camera(delta)


# --------------------------------------------------------------------------
# Engine / clutch
# --------------------------------------------------------------------------

func _update_rpm(delta: float, throttle: float, clutch: bool) -> void:
	var target: float
	if clutch or _gear == 1:
		# Free-revving: throttle controls the RPM directly.
		target = lerpf(idle_rpm, redline_rpm, throttle)
	else:
		# Engaged: RPM follows road speed through the current gear.
		var speed := linear_velocity.length()
		target = clampf(idle_rpm + speed * absf(gear_ratios[_gear]) * rpm_per_speed, idle_rpm, redline_rpm)
	var rate := rev_up_rate if target > _rpm else rev_down_rate
	_rpm = move_toward(_rpm, target, rate * delta)


func _update_kick(delta: float, clutch: bool) -> void:
	# On clutch release above the threshold, snap in a kick proportional to RPM.
	if _clutch_prev and not clutch and _rpm > clutch_kick_min_rpm:
		_kick = clampf((_rpm - clutch_kick_min_rpm) / (redline_rpm - clutch_kick_min_rpm), 0.0, 1.0)
	_clutch_prev = clutch
	_kick = move_toward(_kick, 0.0, delta / maxf(clutch_kick_time, 0.01))


# --------------------------------------------------------------------------
# Grip / drift (friction-circle approximation)
# --------------------------------------------------------------------------

func _apply_grip(throttle: float, handbrake: bool) -> void:
	for w in _front_wheels:
		w.wheel_friction_slip = front_grip
		w.wheel_roll_influence = roll_influence
		w.suspension_stiffness = suspension_stiffness

	var rg: float
	if handbrake:
		rg = handbrake_rear_grip
	else:
		# The harder the rear is driven, the more grip it sheds. In low gears
		# the big ratio pushes "drive" past the break point -> the rear slides;
		# in high gears it stays under -> the rear grips.
		var drive := throttle * absf(gear_ratios[_gear]) + _kick * clutch_kick_strength
		var loss := clampf((drive - traction_break_point) * traction_sensitivity, 0.0, 1.0)
		rg = lerpf(rear_grip, rear_grip * drift_grip_factor, loss)

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
	var clutch_tag := "  [CLUTCH]" if Input.is_action_pressed("sprint") else ""
	_rpm_label.text = "%d rpm%s" % [int(_rpm), clutch_tag]


func _gear_name() -> String:
	if _gear == 0:
		return "R"
	if _gear == 1:
		return "N"
	return str(_gear - 1)
