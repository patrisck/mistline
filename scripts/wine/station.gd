extends StaticBody3D
class_name Station
## Base de todas as estações da vinícola.
##
## Implementa o EIXO DE PROGRESSÃO do jogo: cada estação começa no tier 0
## (100% manual — o jogador opera na mão) e sobe de tier pagando dinheiro,
## até o tier máximo, onde passa a operar SOZINHA (automação).
##
## Contrato de interação (igual portas/itens): grupo "interactable" +
## métodos interact(player) / get_prompt(). Upgrade via try_upgrade() (tecla U).

@export var display_name: String = "Estação"
## Tier atual: 0 = manual. Subir aumenta velocidade/qualidade; no máximo, automatiza.
@export var tier: int = 0
## Tier máximo desta estação (definido por subclasse/cena).
@export var max_tier: int = 1
## Custo pra subir de cada tier (índice = tier atual). Ex.: [150, 400] = 150 do
## tier 0->1, 400 do 1->2.
@export var upgrade_costs: PackedInt32Array = PackedInt32Array([150])


func _ready() -> void:
	add_to_group("interactable")
	_on_ready()


# --- Contrato de interação (subclasses sobrescrevem) ---

func interact(_player: Node) -> void:
	pass


func get_prompt() -> String:
	return display_name


# --- Progressão / upgrade ---

## Já opera sozinha?
func is_automated() -> bool:
	return tier >= max_tier and max_tier > 0


## Custo pra subir pro próximo tier, ou -1 se já no máximo.
func next_upgrade_cost() -> int:
	if tier >= max_tier or tier >= upgrade_costs.size():
		return -1
	return upgrade_costs[tier]


## Tenta comprar o próximo tier (tecla U do jogador). Debita do GameState.
func try_upgrade() -> bool:
	var cost := next_upgrade_cost()
	if cost < 0:
		return false
	if not GameState.spend(cost):
		return false
	tier += 1
	_on_upgraded()
	return true


## Texto curto do estado do tier, pra compor o prompt.
func tier_label() -> String:
	if is_automated():
		return "[AUTO]"
	return "[tier %d]" % tier


## Sufixo de prompt com o hint de upgrade, se houver.
func upgrade_hint() -> String:
	var cost := next_upgrade_cost()
	if cost < 0:
		return ""
	return "   [U] Melhorar $%d" % cost


# --- Hooks pras subclasses ---

func _on_ready() -> void:
	pass


func _on_upgraded() -> void:
	pass
