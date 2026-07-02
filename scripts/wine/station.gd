extends StaticBody3D
class_name Station
## Base for all winery stations.
##
## Implements the game's PROGRESSION AXIS: each station starts at tier 0
## (100% manual — the player operates it by hand) and levels up by paying
## money, up to the max tier, where it starts running ON ITS OWN (automation).
##
## Interaction contract (same as doors/items): "interactable" group +
## interact(player) / get_prompt() methods. Upgrade via try_upgrade() (U key).

@export var display_name: String = "Station"
## Current tier: 0 = manual. Leveling up increases speed/quality; at max, it automates.
@export var tier: int = 0
## Max tier for this station (set by subclass/scene).
@export var max_tier: int = 1
## Cost to level up from each tier (index = current tier). E.g.: [150, 400] = 150
## for tier 0->1, 400 for 1->2.
@export var upgrade_costs: PackedInt32Array = PackedInt32Array([150])


func _ready() -> void:
	add_to_group("interactable")
	_on_ready()


# --- Interaction contract (subclasses override) ---

func interact(_player: Node) -> void:
	pass


func get_prompt() -> String:
	return display_name


# --- Progression / upgrade ---

## Already running on its own?
func is_automated() -> bool:
	return tier >= max_tier and max_tier > 0


## Cost to reach the next tier, or -1 if already at max.
func next_upgrade_cost() -> int:
	if tier >= max_tier or tier >= upgrade_costs.size():
		return -1
	return upgrade_costs[tier]


## Tries to buy the next tier (player's U key). Debits from GameState.
func try_upgrade() -> bool:
	var cost := next_upgrade_cost()
	if cost < 0:
		return false
	if not GameState.spend(cost):
		return false
	tier += 1
	_on_upgraded()
	return true


## Short tier-status text, to compose the prompt.
func tier_label() -> String:
	if is_automated():
		return "[AUTO]"
	return "[tier %d]" % tier


## Prompt suffix with the upgrade hint, if any.
func upgrade_hint() -> String:
	var cost := next_upgrade_cost()
	if cost < 0:
		return ""
	return "   [U] Upgrade $%d" % cost


# --- Hooks for subclasses ---

func _on_ready() -> void:
	pass


func _on_upgraded() -> void:
	pass
