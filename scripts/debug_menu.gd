extends CanvasLayer
## Menu de debug in-game (tecla F1). Edita parâmetros do jogo em TEMPO REAL.
##
## Genérico e reutilizável: qualquer script registra parâmetros com
## add_float / add_bool / add_action (agrupados por seção). Autoload "DebugMenu".
##
## O botão "Imprimir valores" joga os valores atuais no console, pra você
## capturar o que calibrou e cravar no código/cena depois.

const ACCENT := Color(0.86, 0.45, 0.28)
const TOGGLE_KEY := KEY_F1

var is_open: bool = false

var _entries: Array = []            # cada item: Dictionary com type/section/label/...
var _rows: Array = []               # controles vivos, pra refresh por frame
var _dragging: Dictionary = {}      # slider -> bool (usuário arrastando?)
var _root: Control
var _list: VBoxContainer


func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_frame()
	_root.visible = false
	set_process(false)


# --------------------------------------------------------------------------
# API pública (chamada pelos scripts que querem expor parâmetros)
# --------------------------------------------------------------------------

func clear_params() -> void:
	_entries.clear()
	if is_open:
		_rebuild()


func add_float(section: String, label: String, object: Object, property: String, min_value: float, max_value: float, step: float = 0.01) -> void:
	_entries.append({
		"type": "float", "section": section, "label": label,
		"object": object, "property": property,
		"min": min_value, "max": max_value, "step": step,
	})


func add_bool(section: String, label: String, object: Object, property: String) -> void:
	_entries.append({
		"type": "bool", "section": section, "label": label,
		"object": object, "property": property,
	})


func add_action(section: String, label: String, callable: Callable) -> void:
	_entries.append({
		"type": "action", "section": section, "label": label, "callable": callable,
	})


func get_param_count() -> int:
	return _entries.size()


# --------------------------------------------------------------------------
# Abertura / entrada
# --------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == TOGGLE_KEY:
		toggle()
		get_viewport().set_input_as_handled()
	elif is_open and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func open() -> void:
	is_open = true
	_rebuild()
	_root.visible = true
	set_process(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	is_open = false
	_root.visible = false
	set_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(_delta: float) -> void:
	# Mantém os controles em sincronia com valores que mudam sozinhos
	# (ex.: hora do dia avançando com o ciclo).
	for row in _rows:
		if row.type == "float":
			if _dragging.get(row.slider, false):
				continue
			var cur: float = row.entry.object.get(row.entry.property)
			row.slider.set_value_no_signal(cur)
			row.val.text = _fmt(cur, row.entry.step)
		elif row.type == "bool":
			row.check.set_pressed_no_signal(bool(row.entry.object.get(row.entry.property)))


# --------------------------------------------------------------------------
# Construção da UI
# --------------------------------------------------------------------------

func _build_frame() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	panel.offset_left = 16
	panel.offset_top = 16
	panel.offset_right = 380
	panel.offset_bottom = -16
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.05, 0.07, 0.93)
	sb.set_border_width_all(1)
	sb.border_color = Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.5)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", sb)
	_root.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	panel.add_child(vb)

	var title := Label.new()
	title.text = "DEBUG  ·  F1 abre/fecha"
	title.add_theme_color_override("font_color", ACCENT)
	title.add_theme_font_size_override("font_size", 16)
	vb.add_child(title)

	var print_btn := Button.new()
	print_btn.text = "Imprimir valores no console"
	print_btn.pressed.connect(_print_values)
	vb.add_child(print_btn)

	vb.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_list)


func _rebuild() -> void:
	_rows.clear()
	_dragging.clear()
	for c in _list.get_children():
		c.queue_free()

	var current_section := ""
	for e in _entries:
		if e.section != current_section:
			current_section = e.section
			_add_section_header(current_section)
		match e.type:
			"float": _make_float_row(e)
			"bool": _make_bool_row(e)
			"action": _make_action_row(e)


func _add_section_header(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text.to_upper()
	lbl.add_theme_color_override("font_color", Color(0.58, 0.64, 0.72))
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.custom_minimum_size.y = 22
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_list.add_child(lbl)


func _make_float_row(e: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	var name_lbl := Label.new()
	name_lbl.text = e.label
	name_lbl.custom_minimum_size.x = 118
	name_lbl.add_theme_font_size_override("font_size", 13)

	var slider := HSlider.new()
	slider.min_value = e.min
	slider.max_value = e.max
	slider.step = e.step
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.custom_minimum_size.x = 90
	slider.value = e.object.get(e.property)

	var val_lbl := Label.new()
	val_lbl.custom_minimum_size.x = 54
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.add_theme_font_size_override("font_size", 12)
	val_lbl.text = _fmt(e.object.get(e.property), e.step)

	slider.value_changed.connect(_on_slider_changed.bind(e, val_lbl))
	slider.drag_started.connect(_on_drag_started.bind(slider))
	slider.drag_ended.connect(_on_drag_ended.bind(slider))

	row.add_child(name_lbl)
	row.add_child(slider)
	row.add_child(val_lbl)
	_list.add_child(row)
	_rows.append({"type": "float", "entry": e, "slider": slider, "val": val_lbl})


func _make_bool_row(e: Dictionary) -> void:
	var row := HBoxContainer.new()
	var name_lbl := Label.new()
	name_lbl.text = e.label
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 13)
	var cb := CheckButton.new()
	cb.button_pressed = bool(e.object.get(e.property))
	cb.toggled.connect(_on_bool_toggled.bind(e))
	row.add_child(name_lbl)
	row.add_child(cb)
	_list.add_child(row)
	_rows.append({"type": "bool", "entry": e, "check": cb})


func _make_action_row(e: Dictionary) -> void:
	var btn := Button.new()
	btn.text = e.label
	btn.pressed.connect(e.callable)
	_list.add_child(btn)


# --------------------------------------------------------------------------
# Callbacks (sem closures — usam bind pra passar o contexto)
# --------------------------------------------------------------------------

func _on_slider_changed(value: float, e: Dictionary, val_lbl: Label) -> void:
	e.object.set(e.property, value)
	val_lbl.text = _fmt(value, e.step)


func _on_drag_started(slider: HSlider) -> void:
	_dragging[slider] = true


func _on_drag_ended(_value_changed: bool, slider: HSlider) -> void:
	_dragging[slider] = false


func _on_bool_toggled(pressed: bool, e: Dictionary) -> void:
	e.object.set(e.property, pressed)


func _print_values() -> void:
	print("--- DEBUG: valores atuais ---")
	for e in _entries:
		if e.type == "action":
			continue
		print("[%s] %s = %s" % [e.section, e.label, str(e.object.get(e.property))])


func _fmt(v: float, step: float) -> String:
	if step >= 1.0:
		return str(int(round(v)))
	elif step >= 0.01:
		return "%.2f" % v
	return "%.4f" % v
