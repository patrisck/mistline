class_name InteractableLamp
extends Interactable

## Lampada interativa de teste: liga/desliga uma OmniLight3D e a emissao do corpo.

@export var is_on := false

@onready var light: OmniLight3D = $OmniLight3D
@onready var mesh: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	_apply_state()


func _on_interact(_interactor: Node3D) -> void:
	is_on = not is_on
	_apply_state()


func _apply_state() -> void:
	if light:
		light.visible = is_on
	if mesh and mesh.material_override is StandardMaterial3D:
		(mesh.material_override as StandardMaterial3D).emission_enabled = is_on
	prompt = "Apagar lampada" if is_on else "Acender lampada"
