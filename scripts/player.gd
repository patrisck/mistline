extends CharacterBody3D
## First-person character controller.
## - WASD movement + sprint + jump with gravity (move_and_slide)
## - Mouse-look camera (body yaws on Y, head pitches on X)
## - Raycast interaction: open doors and pick up ONE item at a time (physics)
##
## The item is carried via VELOCITY (not reparenting/direct position) to
## keep correct physics behavior and collision with walls, My Summer Car /
## Mon Bazou style.

# --- Movement ---
@export_group("Movement")
@export var walk_speed: float = 4.0
@export var sprint_speed: float = 7.0
@export var acceleration: float = 12.0
@export var jump_velocity: float = 6.0
@export var mouse_sensitivity: float = 0.0025
@export var pitch_limit_deg: float = 89.0

# --- Interaction / carry ---
@export_group("Interaction")
## Interaction raycast range (meters).
@export var interact_distance: float = 3.0
## Stiffness of the "elastic" that pulls the item to the hold point.
@export var carry_stiffness: float = 12.0
## Max speed the item chases the hold point at.
@export var carry_max_speed: float = 20.0
## If the item ends up farther than this from the hold point (stuck behind
## something), it's dropped.
@export var carry_break_distance: float = 2.5
## Throw force (right click).
@export var throw_impulse: float = 8.0
## How much the item rotates per scroll "notch" (radians). ~12 degrees.
@export var carry_rotate_step: float = 0.209
## Stiffness of the orientation control (holds/rotates the item stably).
@export var carry_orient_stiffness: float = 10.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var interact_ray: RayCast3D = $Head/Camera3D/InteractRay
@onready var hold_point: Marker3D = $Head/Camera3D/HoldPoint

var _held_body: RigidBody3D = null
var _held_original_gravity: float = 1.0
## Target orientation of the carried item. Scroll rotates this target; physics chases it.
var _carry_basis: Basis = Basis.IDENTITY


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	interact_ray.target_position = Vector3(0, 0, -interact_distance)
	camera.current = true  # ensures the player's view (not the car's) on spawn


func _unhandled_input(event: InputEvent) -> void:
	# Mouse-look only while the mouse is captured.
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		var limit := deg_to_rad(pitch_limit_deg)
		head.rotation.x = clamp(head.rotation.x, -limit, limit)

	# Esc toggles mouse capture (useful to leave the window).
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Recapture on click back into the window.
	if event.is_action_pressed("interact") and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	if event.is_action_pressed("interact"):
		_on_interact()
	elif event.is_action_pressed("throw"):
		_on_throw()

	# Mouse scroll rotates the held item on its own axis (vertical).
	if _held_body != null and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_rotate_held(1.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_rotate_held(-1.0)

	# U key: upgrade the station under the crosshair.
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_U:
		var t := _get_interactable()
		if t != null and t.has_method("try_upgrade"):
			t.try_upgrade()


func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_update_carry()
	_update_prompt()


func _handle_movement(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var target_speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	var target_vel := direction * target_speed

	velocity.x = move_toward(velocity.x, target_vel.x, acceleration * delta * target_speed)
	velocity.z = move_toward(velocity.z, target_vel.z, acceleration * delta * target_speed)

	move_and_slide()


# --------------------------------------------------------------------------
# Interaction
# --------------------------------------------------------------------------

func _on_interact() -> void:
	var target := _get_interactable()

	# With an item in hand: if the target is interactive but NOT an item
	# (e.g. a station), let it use whatever you're holding (pour grapes,
	# sell...). Otherwise, drop the item.
	if _held_body != null:
		if target != null and target != _held_body and target.has_method("interact") \
				and not target.is_in_group("pickable"):
			target.interact(self)
		else:
			_drop()
		return

	if target == null:
		return

	if target is RigidBody3D and target.is_in_group("pickable"):
		_pick_up(target)
	elif target.has_method("interact"):
		target.interact(self)


func _on_throw() -> void:
	# No item in hand: right-click is the "secondary action" of the station
	# under the crosshair (e.g. send the must to the fermenter).
	if _held_body == null:
		var target := _get_interactable()
		if target != null and target.has_method("secondary_interact"):
			target.secondary_interact(self)
		return
	var body := _held_body
	var dir := -camera.global_transform.basis.z
	_drop()
	body.apply_central_impulse(dir * throw_impulse)


## Returns the interactive node under the crosshair, or null.
func _get_interactable() -> Node:
	if not interact_ray.is_colliding():
		return null
	var collider := interact_ray.get_collider()
	if collider is Node and (collider.has_method("interact") or collider.is_in_group("pickable")):
		return collider
	return null


func _pick_up(body: RigidBody3D) -> void:
	_held_body = body
	_held_original_gravity = body.gravity_scale
	body.gravity_scale = 0.0
	body.sleeping = false
	# Start holding while keeping the item's current orientation.
	_carry_basis = body.global_transform.basis.orthonormalized()
	# Don't collide with the player while carrying (avoids push/jitter).
	body.add_collision_exception_with(self)
	# The held item shouldn't block the interaction raycast.
	interact_ray.add_exception(body)
	Interaction.notify_hold_state(true)


## Rotates the item's orientation target "over the top" (tipping forward/back),
## around the camera's horizontal right axis — no longer the vertical axis.
func _rotate_held(direction: float) -> void:
	var axis := camera.global_transform.basis.x.normalized()
	_carry_basis = Basis(axis, direction * carry_rotate_step) * _carry_basis
	_carry_basis = _carry_basis.orthonormalized()


func _drop() -> void:
	if _held_body == null:
		return
	_held_body.gravity_scale = _held_original_gravity
	_held_body.remove_collision_exception_with(self)
	interact_ray.remove_exception(_held_body)
	_held_body = null
	Interaction.notify_hold_state(false)


## Item currently in hand (or null). Used by stations.
func get_held() -> RigidBody3D:
	return _held_body


## Removes the item from the hand (for a station to consume) without dropping
## it on the ground, and returns it, restoring the body's physics.
func take_held() -> RigidBody3D:
	if _held_body == null:
		return null
	var b := _held_body
	b.gravity_scale = _held_original_gravity
	b.remove_collision_exception_with(self)
	interact_ray.remove_exception(b)
	_held_body = null
	Interaction.notify_hold_state(false)
	return b


## Disables the player while driving (the car takes over camera and input).
func enter_vehicle() -> void:
	if _held_body != null:
		_drop()
	Interaction.set_prompt("")
	visible = false
	$CollisionShape3D.set_deferred("disabled", true)
	set_physics_process(false)
	set_process_unhandled_input(false)


## Re-enables the player when exiting the car, positioning them at `at`.
func exit_vehicle(at: Transform3D) -> void:
	global_transform = at
	velocity = Vector3.ZERO
	visible = true
	$CollisionShape3D.set_deferred("disabled", false)
	set_physics_process(true)
	set_process_unhandled_input(true)
	camera.current = true


## Moves the carried item toward the hold point using velocity.
## Runs in the physics step for stable velocity control.
func _update_carry() -> void:
	if _held_body == null:
		return

	var to_target := hold_point.global_position - _held_body.global_position

	# If the item got stuck behind something (too far), drop it.
	if to_target.length() > carry_break_distance:
		_drop()
		return

	# Elastic: velocity proportional to distance, with a cap.
	var desired_velocity := to_target * carry_stiffness
	if desired_velocity.length() > carry_max_speed:
		desired_velocity = desired_velocity.normalized() * carry_max_speed

	_held_body.linear_velocity = desired_velocity

	# Orientation control: rotates the item toward the target orientation
	# (_carry_basis), converting the rotation delta into angular velocity.
	# This keeps the item stable in hand and responsive to scroll without
	# flopping around.
	var current_q := _held_body.global_transform.basis.get_rotation_quaternion()
	var target_q := _carry_basis.get_rotation_quaternion()
	var delta_q := target_q * current_q.inverse()
	if delta_q.w < 0.0:
		delta_q = -delta_q  # shortest path
	var angle := 2.0 * acos(clampf(delta_q.w, -1.0, 1.0))
	var axis := Vector3(delta_q.x, delta_q.y, delta_q.z)
	if angle > 0.0001 and axis.length() > 0.0001:
		_held_body.angular_velocity = axis.normalized() * angle * carry_orient_stiffness
	else:
		_held_body.angular_velocity = Vector3.ZERO


func _update_prompt() -> void:
	if _held_body != null:
		Interaction.set_prompt("[LMB] Drop     [Scroll] Rotate     [RMB] Throw")
		return

	var target := _get_interactable()
	if target == null:
		Interaction.set_prompt("")
		return

	if target.has_method("get_prompt"):
		Interaction.set_prompt("[LMB] " + target.get_prompt())
	elif target.is_in_group("pickable"):
		Interaction.set_prompt("[LMB] Pick up")
	else:
		Interaction.set_prompt("[LMB] Interact")
