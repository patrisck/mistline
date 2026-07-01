extends AnimatableBody3D
class_name Door
## Porta que abre/fecha com o clique esquerdo.
## A origem do nó fica na dobradiça; a malha e o colisor ficam deslocados em +X.
## Usa AnimatableBody3D + Tween no passo de física para empurrar corpos
## corretamente (o jogador não atravessa a porta).

## Ângulo de abertura em graus.
@export var open_angle_deg: float = 110.0
## Duração da animação de abrir/fechar (segundos).
@export var swing_time: float = 0.5

var _is_open: bool = false
var _closed_rot_y: float = 0.0
var _tween: Tween


func _ready() -> void:
	_closed_rot_y = rotation.y
	# Movida via tween no passo de física -> empurra corpos físicos.
	sync_to_physics = true
	add_to_group("interactable")


func interact(_player: Node) -> void:
	_is_open = not _is_open
	var target_y := _closed_rot_y
	if _is_open:
		target_y += deg_to_rad(open_angle_deg)

	if _tween != null and _tween.is_running():
		_tween.kill()

	_tween = create_tween()
	_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "rotation:y", target_y, swing_time)


func get_prompt() -> String:
	return "Fechar porta" if _is_open else "Abrir porta"
