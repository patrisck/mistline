extends RigidBody3D
class_name Pickable
## Item físico que pode ser pego (um por vez). A lógica de carregar fica no
## Player; aqui só marcamos o objeto como "pickable" e definimos o texto de
## contexto. Ajuste massa/atrito no inspetor da cena.

## Nome exibido no prompt (ex.: "Pegar Caixa").
@export var display_name: String = "Item"


func _ready() -> void:
	add_to_group("pickable")
	# Continua a colidir mesmo devagar; evita "dormir" e travar no ar.
	can_sleep = true
	contact_monitor = false


func get_prompt() -> String:
	return "Pegar " + display_name
