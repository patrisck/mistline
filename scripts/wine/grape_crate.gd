extends Pickable
class_name GrapeCrate
## Caixa de uvas — insumo carregável. Leve até o esmagador e despeje (clique).

## Qualidade média das uvas (0..100). Semeia a qualidade do lote.
@export var grape_quality: float = 60.0
## Litros de mosto que esta caixa rende.
@export var liters: float = 1.5


func get_prompt() -> String:
	return "Pegar uvas (qualidade %d)" % int(grape_quality)
