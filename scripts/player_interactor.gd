class_name PlayerInteractor
extends RayCast3D

## Detecta Interactables na mira (raycast a partir da camera) e os aciona.

@export var interact_action := "interact"

var player: CharacterBody3D
var current_interactable: Interactable


func _ready() -> void:
	player = _find_player()
	if player:
		add_exception(player)


func _physics_process(_delta: float) -> void:
	if is_colliding():
		current_interactable = get_collider() as Interactable
	else:
		current_interactable = null

	if current_interactable and Input.is_action_just_pressed(interact_action):
		current_interactable.interact(player)


func _find_player() -> CharacterBody3D:
	var node := get_parent()
	while node:
		if node is CharacterBody3D:
			return node
		node = node.get_parent()
	return null
