extends Station
class_name GrapeBin
## Depósito de uvas — a fonte de insumo. [Esq] compra uma caixa; ela cai na saída.

const GRAPE_CRATE_SCENE := preload("res://scenes/wine/grape_crate.tscn")

@export var cost: int = 20
@export var min_quality: float = 50.0
@export var max_quality: float = 75.0

var _output: Marker3D


func _on_ready() -> void:
	_output = get_node_or_null("Output")


func interact(_player: Node) -> void:
	if not GameState.spend(cost):
		return
	var crate: GrapeCrate = GRAPE_CRATE_SCENE.instantiate()
	crate.grape_quality = randf_range(min_quality, max_quality)
	get_tree().current_scene.add_child(crate)
	crate.global_position = _output.global_position + Vector3(0, 0.2, 0)


func get_prompt() -> String:
	return "Depósito de uvas — [Esq] comprar caixa ($%d)" % cost
