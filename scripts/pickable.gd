class_name Pickable
extends RigidBody3D

## Objeto que pode ser pego e carregado na mira (um por vez).

@export var prompt := "Pegar"
@export var pickable_enabled := true


func can_pick() -> bool:
	return pickable_enabled
