class_name Interactable
extends StaticBody3D

## Contrato base de objetos interativos (estilo IInteractable).
## Subclasses sobrescrevem _on_interact() e, se preciso, can_interact().

signal interacted(interactor: Node3D)

@export var prompt := "Interagir"
@export var interactable_enabled := true


func can_interact(_interactor: Node3D) -> bool:
	return interactable_enabled


func interact(interactor: Node3D) -> void:
	if not can_interact(interactor):
		return
	_on_interact(interactor)
	interacted.emit(interactor)


## Comportamento concreto da interacao. Sobrescrever nas subclasses.
func _on_interact(_interactor: Node3D) -> void:
	pass
