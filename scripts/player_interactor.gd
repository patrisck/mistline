class_name PlayerInteractor
extends RayCast3D

## Detecta Interactables/Pickables na mira e roteia a acao de interagir/pegar/soltar.
## Mantem current_prompt (texto) para o HUD exibir.

@export var interact_action := "interact"

var player: CharacterBody3D
var current_prompt := ""

@onready var carry: PlayerCarry = $"../Carry"

var _target: Node3D


func _ready() -> void:
	player = _find_player()
	if player:
		add_exception(player)


func _physics_process(_delta: float) -> void:
	if is_colliding():
		_target = get_collider() as Node3D
	else:
		_target = null

	current_prompt = _resolve_prompt()

	if Input.is_action_just_pressed(interact_action) and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_do_action()


func _resolve_prompt() -> String:
	if carry and carry.is_holding():
		return "Soltar"
	var interactable := _target as Interactable
	if interactable and interactable.can_interact(player):
		return interactable.prompt
	var pickable := _target as Pickable
	if pickable and pickable.can_pick():
		return pickable.prompt
	var vehicle := _target as Vehicle
	if vehicle:
		return "Entrar"
	return ""


func _do_action() -> void:
	if carry and carry.is_holding():
		carry.drop()
		return
	var interactable := _target as Interactable
	if interactable and interactable.can_interact(player):
		interactable.interact(player)
		return
	var pickable := _target as Pickable
	if pickable and pickable.can_pick() and carry:
		carry.pick_up(pickable)
		return
	var vehicle := _target as Vehicle
	if vehicle:
		vehicle.enter(player)


func _find_player() -> CharacterBody3D:
	var node := get_parent()
	while node:
		if node is CharacterBody3D:
			return node
		node = node.get_parent()
	return null
