extends Node
## Singleton global (autoload "Interaction").
## Funciona como barramento de sinais entre o Player e a UI, evitando
## que o Player conheça diretamente os nós de interface.

## Emitido sempre que o texto de contexto (o que o jogador pode fazer) muda.
signal prompt_changed(text: String)

## Emitido quando o jogador pega ou solta um item.
signal hold_state_changed(is_holding: bool)

## Bit da camada de física usada por objetos interativos (ver project.godot).
const INTERACTABLE_LAYER := 3

var _current_prompt: String = ""


## Define o texto de contexto. Só emite o sinal quando realmente muda,
## evitando trabalho desnecessário na UI a cada frame.
func set_prompt(text: String) -> void:
	if text == _current_prompt:
		return
	_current_prompt = text
	prompt_changed.emit(text)


func notify_hold_state(is_holding: bool) -> void:
	hold_state_changed.emit(is_holding)
