extends Label

## Mostra o prompt do Interactable atualmente na mira do jogador.

@export var interactor: PlayerInteractor


func _process(_delta: float) -> void:
	var target := interactor.current_interactable if interactor else null
	if target and target.can_interact(interactor.player):
		text = "[E] " + target.prompt
		visible = true
	else:
		visible = false
