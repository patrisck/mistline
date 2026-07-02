extends Station
class_name SalesCounter
## Sales counter. Hold a bottle and click to sell. Price = quality.

## Money per point of bottle quality.
@export var price_per_quality: float = 0.9


func interact(player: Node) -> void:
	var held: Node = player.get_held() if player.has_method("get_held") else null
	if held is WineBottle:
		var price := int(round(held.quality * price_per_quality))
		GameState.add_money(price)
		player.take_held().queue_free()


func get_prompt() -> String:
	return "Counter — hold a bottle and [LMB] to sell"
