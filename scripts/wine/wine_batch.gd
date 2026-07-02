extends Resource
class_name WineBatch
## The "batch" — data object carrying the wine's state through the whole
## process. Each station reads and modifies these attributes. Passed by
## reference between stations (crusher -> fermenter -> bottles).

enum State { MUST, FERMENTING, WINE }

## Current phase of the batch.
@export var state: State = State.MUST
## Liters of liquid in the batch.
@export var volume: float = 0.0
## Remaining sugar (0..1) — turns into alcohol during fermentation.
@export var sugar: float = 0.9
## Approximate alcohol content (%).
@export var alcohol: float = 0.0
## Accumulated final quality (0..100). Each station pushes it up/down.
@export var quality: float = 50.0
## How well it was crushed (0..1) — affects extraction/quality.
@export var extraction: float = 0.0
## Fermentation progress (0..1).
@export var ferment_progress: float = 0.0
## Cleanliness/sanitation (0..1) — too low spoils the batch (future).
@export var cleanliness: float = 1.0


## Number of 0.75 L bottles this batch yields.
func bottle_count() -> int:
	return int(floor(volume / 0.75))
