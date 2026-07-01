extends Resource
class_name WineBatch
## O "lote" — objeto de dados que carrega o estado do vinho ao longo de todo o
## processo. Cada estação lê e modifica esses atributos. Passado por referência
## entre as estações (crusher -> fermenter -> garrafas).

enum State { MUST, FERMENTING, WINE }

## Fase atual do lote.
@export var state: State = State.MUST
## Litros de líquido no lote.
@export var volume: float = 0.0
## Açúcar restante (0..1) — vira álcool na fermentação.
@export var sugar: float = 0.9
## Teor alcoólico aproximado (%).
@export var alcohol: float = 0.0
## Qualidade final acumulada (0..100). Cada estação empurra pra cima/baixo.
@export var quality: float = 50.0
## Quão bem foi esmagado (0..1) — afeta extração/qualidade.
@export var extraction: float = 0.0
## Progresso da fermentação (0..1).
@export var ferment_progress: float = 0.0
## Limpeza/sanitização (0..1) — baixa demais estraga o lote (futuro).
@export var cleanliness: float = 1.0


## Número de garrafas de 0,75 L que este lote rende.
func bottle_count() -> int:
	return int(floor(volume / 0.75))
