extends CanvasLayer
## HUD: vinheta atmosférica, mira com feedback de alvo e painel de contexto.
## Escuta os sinais do singleton Interaction, sem acoplar ao Player.

@onready var crosshair: Control = $Crosshair
@onready var prompt_panel: PanelContainer = $PromptPanel
@onready var prompt_label: Label = $PromptPanel/PromptLabel


func _ready() -> void:
	Interaction.prompt_changed.connect(_on_prompt_changed)
	prompt_panel.visible = false


func _on_prompt_changed(text: String) -> void:
	var has_prompt := text != ""
	prompt_label.text = text
	prompt_panel.visible = has_prompt
	crosshair.set_active(has_prompt)
