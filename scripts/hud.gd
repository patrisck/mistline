extends CanvasLayer
## HUD: atmospheric vignette, crosshair with target feedback, and context panel.
## Listens to the Interaction singleton's signals, without coupling to Player.

@onready var crosshair: Control = $Crosshair
@onready var prompt_panel: PanelContainer = $PromptPanel
@onready var prompt_label: Label = $PromptPanel/PromptLabel
@onready var money_label: Label = $MoneyLabel


func _ready() -> void:
	Interaction.prompt_changed.connect(_on_prompt_changed)
	prompt_panel.visible = false
	GameState.money_changed.connect(_on_money_changed)
	_on_money_changed(GameState.money)


func _on_money_changed(amount: int) -> void:
	money_label.text = "$ %d" % amount


func _on_prompt_changed(text: String) -> void:
	var has_prompt := text != ""
	prompt_label.text = text
	prompt_panel.visible = has_prompt
	crosshair.set_active(has_prompt)
