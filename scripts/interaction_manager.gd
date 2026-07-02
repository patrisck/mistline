extends Node
## Global singleton (autoload "Interaction").
## Works as a signal bus between the Player and the UI, so the Player
## doesn't need to know the UI nodes directly.

## Emitted whenever the context text (what the player can do) changes.
signal prompt_changed(text: String)

## Emitted when the player picks up or drops an item.
signal hold_state_changed(is_holding: bool)

## Physics layer bit used by interactive objects (see project.godot).
const INTERACTABLE_LAYER := 3

var _current_prompt: String = ""


## Sets the context text. Only emits the signal when it actually changes,
## avoiding unnecessary UI work every frame.
func set_prompt(text: String) -> void:
	if text == _current_prompt:
		return
	_current_prompt = text
	prompt_changed.emit(text)


func notify_hold_state(is_holding: bool) -> void:
	hold_state_changed.emit(is_holding)
