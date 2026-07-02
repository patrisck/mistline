extends Station
class_name Crusher
## Crusher. Flow:
##   [holding crate] LMB = pour grapes
##   [has must]      LMB = stomp/crush (raises extraction)
##                   RMB = send must to the fermenter (you decide WHEN)
## Decision: extraction quality peaks around 0.85 — neither raw nor bitter.
## AUTO tier (>=1): crushes on its own and sends when the fermenter is free.

const CRUSH_PER_CLICK := 0.14
const AUTO_CRUSH_PER_SEC := 0.3

var _batch: WineBatch = null


func _process(delta: float) -> void:
	if not is_automated() or _batch == null:
		return
	if _batch.extraction < 1.0:
		_batch.extraction = minf(_batch.extraction + AUTO_CRUSH_PER_SEC * delta, 1.0)
	else:
		_transfer()


func interact(player: Node) -> void:
	var held: Node = player.get_held() if player.has_method("get_held") else null
	if held is GrapeCrate:
		_load_grapes(held)
		player.take_held().queue_free()
		return
	# Crush manually
	if _batch != null and _batch.extraction < 1.0 and not is_automated():
		_batch.extraction = minf(_batch.extraction + CRUSH_PER_CLICK, 1.0)


func secondary_interact(_player: Node) -> void:
	# Send the must at the current extraction point (the decision to stop).
	if _batch != null and _batch.extraction > 0.05:
		_transfer()


func _load_grapes(crate: GrapeCrate) -> void:
	if _batch == null:
		_batch = WineBatch.new()
		_batch.state = WineBatch.State.MUST
		_batch.volume = 0.0
		_batch.extraction = 0.0
	_batch.volume += crate.liters
	_batch.quality = crate.grape_quality
	_batch.sugar = 0.9


func _transfer() -> void:
	if _batch == null:
		return
	var ferm := get_tree().get_first_node_in_group("fermenter")
	if ferm == null or not ferm.has_method("can_receive") or not ferm.can_receive():
		return
	# Extraction quality: peaks around 0.85.
	var ex_q := clampf(1.0 - absf(_batch.extraction - 0.85) * 1.4, 0.0, 1.0)
	_batch.quality = clampf(_batch.quality * (0.55 + 0.45 * ex_q), 0.0, 100.0)
	ferm.receive_must(_batch)
	_batch = null


func get_prompt() -> String:
	var base := "Crusher %s" % tier_label()
	if _batch == null:
		return "%s — bring grapes (hold the crate)%s" % [base, upgrade_hint()]
	var pct := int(_batch.extraction * 100.0)
	if is_automated():
		return "%s — crushing on its own (%d%%)" % [base, pct]
	return "%s — [LMB] stomp  •  extraction %d%%  •  [RMB] send must%s" % [base, pct, upgrade_hint()]
