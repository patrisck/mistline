extends VehicleBody3D
class_name Car
## Carro simcade (VehicleBody3D = suspensão raycast embutida).
## Entrar/sair (clique), câmera 1ª pessoa no banco, caixa manual (E/Q), volante.
## Autocontido: assume o input quando ocupado; o player fica desativado.

@export var max_engine_force: float = 220.0
@export var max_brake: float = 6.0
@export var max_steer: float = 0.6
@export var steer_speed: float = 3.0
@export var mouse_sensitivity: float = 0.0025
## índice 0=Ré, 1=Neutro, 2..=1ª..5ª
@export var gear_ratios: Array[float] = [-2.8, 0.0, 2.6, 1.8, 1.3, 1.0, 0.78]

var _occupied: bool = false
var _driver: Node = null
var _gear: int = 1
var _steer: float = 0.0

@onready var _head: Node3D = $Head
@onready var _camera: Camera3D = $Head/Camera3D
@onready var _exit_point: Marker3D = $ExitPoint
@onready var _hud: CanvasLayer = $CarHUD
@onready var _speed_label: Label = $CarHUD/Panel/VBox/Speed
@onready var _gear_label: Label = $CarHUD/Panel/VBox/Gear


func _ready() -> void:
	add_to_group("interactable")
	_hud.visible = false


func get_prompt() -> String:
	return "[Esq] Entrar no carro"


func interact(player: Node) -> void:
	_enter(player)


func _enter(player: Node) -> void:
	_driver = player
	_occupied = true
	_gear = 1
	if player.has_method("enter_vehicle"):
		player.enter_vehicle()
	_camera.current = true
	_hud.visible = true
	set_physics_process(true)


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
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_head.rotate_y(-event.relative.x * mouse_sensitivity)
		_camera.rotate_x(-event.relative.y * mouse_sensitivity)
		_camera.rotation.x = clampf(_camera.rotation.x, deg_to_rad(-70.0), deg_to_rad(70.0))
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

	engine_force = throttle * max_engine_force * gear_ratios[_gear]
	brake = brake_in * max_brake
	if Input.is_action_pressed("jump"):
		brake = max_brake * 2.5  # freio de mão

	_steer = move_toward(_steer, steer_in * max_steer, steer_speed * delta)
	steering = _steer
	_update_hud()


func _update_hud() -> void:
	_speed_label.text = "%d km/h" % int(linear_velocity.length() * 3.6)
	_gear_label.text = "Marcha: %s" % _gear_name()


func _gear_name() -> String:
	if _gear == 0:
		return "R"
	if _gear == 1:
		return "N"
	return str(_gear - 1)
