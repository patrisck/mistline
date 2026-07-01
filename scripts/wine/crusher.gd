extends Station
class_name Crusher
## Esmagador. Fluxo:
##   [segurando caixa] Esq = despejar uvas
##   [tem mosto]       Esq = pisar/esmagar (sobe a extração)
##                     Dir = enviar mosto pro fermentador (você decide QUANDO)
## Decisão: a qualidade da extração tem pico ~0.85 — nem cru, nem amargo.
## Tier AUTO (>=1): esmaga sozinho e envia quando o fermentador estiver livre.

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
	# Esmagar manualmente
	if _batch != null and _batch.extraction < 1.0 and not is_automated():
		_batch.extraction = minf(_batch.extraction + CRUSH_PER_CLICK, 1.0)


func secondary_interact(_player: Node) -> void:
	# Enviar o mosto no ponto de extração atual (a decisão de parar).
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
	# Qualidade da extração: pico em ~0.85.
	var ex_q := clampf(1.0 - absf(_batch.extraction - 0.85) * 1.4, 0.0, 1.0)
	_batch.quality = clampf(_batch.quality * (0.55 + 0.45 * ex_q), 0.0, 100.0)
	ferm.receive_must(_batch)
	_batch = null


func get_prompt() -> String:
	var base := "Esmagador %s" % tier_label()
	if _batch == null:
		return "%s — traga uvas (segure a caixa)%s" % [base, upgrade_hint()]
	var pct := int(_batch.extraction * 100.0)
	if is_automated():
		return "%s — esmagando sozinho (%d%%)" % [base, pct]
	return "%s — [Esq] pisar  •  extração %d%%  •  [Dir] enviar mosto%s" % [base, pct, upgrade_hint()]
