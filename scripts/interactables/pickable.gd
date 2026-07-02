extends RigidBody3D
class_name Pickable
## Physical item that can be picked up (one at a time). Carry logic lives in
## Player; here we just mark the object as "pickable" and set the context
## text. Adjust mass/friction in the scene inspector.

## Name shown in the prompt (e.g. "Pick up Crate").
@export var display_name: String = "Item"


func _ready() -> void:
	add_to_group("pickable")
	# Keeps colliding even when slow; avoids "sleeping" and getting stuck mid-air.
	can_sleep = true
	contact_monitor = false


func get_prompt() -> String:
	return "Pick up " + display_name
