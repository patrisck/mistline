extends AnimatableBody3D
class_name Door
## Door that opens/closes with the left click.
## The node's origin is at the hinge; the mesh and collider are offset on +X.
## Uses AnimatableBody3D + Tween in the physics step to push bodies
## correctly (the player doesn't clip through the door).

## Opening angle in degrees.
@export var open_angle_deg: float = 110.0
## Duration of the open/close animation (seconds).
@export var swing_time: float = 0.5

var _is_open: bool = false
var _closed_rot_y: float = 0.0
var _tween: Tween


func _ready() -> void:
	_closed_rot_y = rotation.y
	# Moved via tween in the physics step -> pushes physics bodies.
	sync_to_physics = true
	add_to_group("interactable")


func interact(_player: Node) -> void:
	_is_open = not _is_open
	var target_y := _closed_rot_y
	if _is_open:
		target_y += deg_to_rad(open_angle_deg)

	if _tween != null and _tween.is_running():
		_tween.kill()

	_tween = create_tween()
	_tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "rotation:y", target_y, swing_time)


func get_prompt() -> String:
	return "Close door" if _is_open else "Open door"
