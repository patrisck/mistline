class_name PlayerCarry
extends Node3D

## Ponto de sustentacao a frente da camera. Carrega um Pickable por vez,
## puxando-o ate este ponto por velocidade (continua colidindo com o mundo).

@export var follow_strength := 14.0
@export var max_carry_speed := 12.0
@export var angular_damping := 12.0

var player: CharacterBody3D

var _held: Pickable


func _ready() -> void:
	player = _find_player()


func is_holding() -> bool:
	return _held != null


func pick_up(pickable: Pickable) -> void:
	if _held or pickable == null:
		return
	_held = pickable
	_held.sleeping = false
	_held.gravity_scale = 0.0
	_held.angular_velocity = Vector3.ZERO
	if player:
		_held.add_collision_exception_with(player)


func drop() -> void:
	if _held == null:
		return
	_held.gravity_scale = 1.0
	if player:
		_held.remove_collision_exception_with(player)
	_held = null


func _physics_process(delta: float) -> void:
	if _held == null:
		return
	var desired := (global_position - _held.global_position) * follow_strength
	if desired.length() > max_carry_speed:
		desired = desired.normalized() * max_carry_speed
	_held.linear_velocity = desired
	_held.angular_velocity = _held.angular_velocity.lerp(Vector3.ZERO, clampf(angular_damping * delta, 0.0, 1.0))


func _find_player() -> CharacterBody3D:
	var node := get_parent()
	while node:
		if node is CharacterBody3D:
			return node
		node = node.get_parent()
	return null
