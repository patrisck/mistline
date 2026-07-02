extends Pickable
class_name GrapeCrate
## Crate of grapes — carryable input. Take it to the crusher and pour it (click).

## Average grape quality (0..100). Seeds the batch's quality.
@export var grape_quality: float = 60.0
## Liters of must this crate yields.
@export var liters: float = 1.5


func get_prompt() -> String:
	return "Pick up grapes (quality %d)" % int(grape_quality)
