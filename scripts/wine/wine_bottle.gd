extends Pickable
class_name WineBottle
## Garrafa de vinho — produto final carregável. Leve até o balcão pra vender.

## Qualidade do vinho (0..100). Define o preço de venda.
@export var quality: float = 50.0
## Nome/safra (futuro: o jogador batiza).
@export var wine_name: String = "Vinho da casa"


func get_prompt() -> String:
	return "Pegar %s (qualidade %d)" % [wine_name, int(quality)]
