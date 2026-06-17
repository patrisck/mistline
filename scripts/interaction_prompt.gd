extends Label

## Mostra o prompt de acao atual resolvido pelo PlayerInteractor.

@onready var _interactor: PlayerInteractor = $"../../Head/Camera3D/Interactor"


func _process(_delta: float) -> void:
	if _interactor and _interactor.current_prompt != "":
		text = "[Clique] " + _interactor.current_prompt
		visible = true
	else:
		visible = false
