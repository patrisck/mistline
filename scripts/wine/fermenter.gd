extends Station
class_name Fermenter
## Fermenter — the heart of the game. Flow:
##   [has must, no yeast] LMB = add yeast (starts fermenting)
##   [fermenting]         LMB = stoke the heat (keep temp in range!)
##   [ready]               LMB = bottle (produces the bottles)
## Temperature drifts down on its own; outside the ideal range fermentation
## stalls and quality drops. Tier 1 = automatic temperature; tier 2 = auto-bottling.

const WINE_BOTTLE_SCENE := preload("res://scenes/wine/wine_bottle.tscn")

const IDEAL_TEMP := 0.62
const BAND_LOW := 0.42
const BAND_HIGH := 0.85
const TEMP_DRIFT := 0.03      # drop per second (tier 0)
const STOKE := 0.22           # heat per click
const OUT_PENALTY := 3.0      # quality lost/sec out of range

## Base fermentation time in seconds (tier 0).
@export var ferment_seconds: float = 45.0

var _batch: WineBatch = null
var _has_yeast: bool = false
var _temp: float = IDEAL_TEMP
var _output: Marker3D


func _on_ready() -> void:
	_output = get_node_or_null("Output")
	add_to_group("fermenter")  # the crusher finds the fermenter via this group


# --- API called by the crusher ---

func can_receive() -> bool:
	return _batch == null


func receive_must(batch: WineBatch) -> void:
	_batch = batch
	_batch.state = WineBatch.State.MUST
	_has_yeast = false
	_temp = IDEAL_TEMP


# --- Interaction ---

func interact(_player: Node) -> void:
	if _batch == null:
		return
	if not _has_yeast:
		_has_yeast = true
		_batch.state = WineBatch.State.FERMENTING
		_temp = IDEAL_TEMP
		return
	if _batch.state == WineBatch.State.FERMENTING:
		_temp = minf(_temp + STOKE, 1.0)  # stoke the heat
		return
	if _batch.state == WineBatch.State.WINE:
		_bottle()


func _process(delta: float) -> void:
	if _batch == null or _batch.state != WineBatch.State.FERMENTING:
		return

	if tier >= 1:
		_temp = IDEAL_TEMP  # automatic temperature
	else:
		_temp = maxf(_temp - TEMP_DRIFT * delta, 0.0)

	var in_band := _temp >= BAND_LOW and _temp <= BAND_HIGH
	var rate := (1.0 / maxf(ferment_seconds, 1.0)) * (1.0 if in_band else 0.35)
	_batch.ferment_progress = minf(_batch.ferment_progress + rate * delta, 1.0)

	# sugar turns into alcohol as it ferments
	_batch.alcohol = _batch.ferment_progress * 13.0
	_batch.sugar = 0.9 * (1.0 - _batch.ferment_progress)

	if not in_band:
		_batch.quality = maxf(_batch.quality - OUT_PENALTY * delta, 0.0)

	if _batch.ferment_progress >= 1.0:
		_batch.state = WineBatch.State.WINE
		if tier >= 2:
			_bottle()  # automatic bottling


func _bottle() -> void:
	if _batch == null:
		return
	var n := _batch.bottle_count()
	var host := get_tree().current_scene
	for i in n:
		var bottle: WineBottle = WINE_BOTTLE_SCENE.instantiate()
		bottle.quality = _batch.quality
		host.add_child(bottle)
		var off := Vector3(randf_range(-0.15, 0.15), 0.1 + i * 0.05, randf_range(-0.15, 0.15))
		bottle.global_position = _output.global_position + off
	_batch = null
	_has_yeast = false


func get_prompt() -> String:
	var base := "Fermenter %s" % tier_label()
	if _batch == null:
		return "%s — empty (send must from the crusher)%s" % [base, upgrade_hint()]
	if not _has_yeast:
		return "%s — [LMB] add yeast%s" % [base, upgrade_hint()]
	if _batch.state == WineBatch.State.FERMENTING:
		var prog := int(_batch.ferment_progress * 100.0)
		if tier >= 1:
			return "%s — fermenting %d%% (auto temp)%s" % [base, prog, upgrade_hint()]
		var temp := int(_temp * 100.0)
		var warn := "OK" if (_temp >= BAND_LOW and _temp <= BAND_HIGH) else "COLD! stoke it"
		return "%s — fermenting %d%%  •  temp %d%% [%s]  •  [LMB] stoke" % [base, prog, temp, warn]
	if _batch.state == WineBatch.State.WINE:
		return "%s — ready! [LMB] bottle (%d bottles)" % [base, _batch.bottle_count()]
	return base
