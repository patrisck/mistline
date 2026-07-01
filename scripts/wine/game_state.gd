extends Node
## Estado global do jogo (autoload "GameState").
## Por enquanto guarda o dinheiro do jogador; vira o hub da economia
## (preços, reputação, desbloqueios) conforme o jogo cresce.

signal money_changed(new_amount: int)

@export var money: int = 200


func add_money(amount: int) -> void:
	money += amount
	money_changed.emit(money)


## Tenta gastar; retorna true se tinha saldo.
func spend(amount: int) -> bool:
	if money < amount:
		return false
	money -= amount
	money_changed.emit(money)
	return true
