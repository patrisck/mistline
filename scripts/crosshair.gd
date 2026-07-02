extends Control
## Crosshair drawn by code. When an interactive target is under it, it changes
## from a discreet dot to a ring + dot in the accent color (clear feedback).

@export var idle_color: Color = Color(0.9, 0.9, 0.92, 0.4)
@export var active_color: Color = Color(0.86, 0.42, 0.26, 0.95)
@export var dot_radius: float = 2.0
@export var ring_radius: float = 8.0
@export var ring_width: float = 1.5

var _active: bool = false


func set_active(value: bool) -> void:
	if value == _active:
		return
	_active = value
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	if _active:
		draw_arc(c, ring_radius, 0.0, TAU, 48, active_color, ring_width, true)
		draw_circle(c, dot_radius, active_color)
	else:
		draw_circle(c, dot_radius, idle_color)
