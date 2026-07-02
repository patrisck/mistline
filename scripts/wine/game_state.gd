extends Node
## Global game state (autoload "GameState").
## For now just holds the player's money; becomes the economy hub
## (prices, reputation, unlocks) as the game grows.

signal money_changed(new_amount: int)

@export var money: int = 200


func add_money(amount: int) -> void:
	money += amount
	money_changed.emit(money)


## Tries to spend; returns true if there was enough balance.
func spend(amount: int) -> bool:
	if money < amount:
		return false
	money -= amount
	money_changed.emit(money)
	return true
