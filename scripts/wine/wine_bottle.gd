extends Pickable
class_name WineBottle
## Bottle of wine — carryable final product. Take it to the counter to sell.

## Wine quality (0..100). Determines the sale price.
@export var quality: float = 50.0
## Name/vintage (future: the player names it).
@export var wine_name: String = "House wine"


func get_prompt() -> String:
	return "Pick up %s (quality %d)" % [wine_name, int(quality)]
