extends CanvasLayer
## HUD simples: mira central e texto de contexto ("Abrir porta", "Pegar Caixa"...).
## Escuta os sinais do singleton Interaction, sem acoplar ao Player.

@onready var prompt_label: Label = $PromptLabel


func _ready() -> void:
	Interaction.prompt_changed.connect(_on_prompt_changed)
	prompt_label.text = ""


func _on_prompt_changed(text: String) -> void:
	prompt_label.text = text
