extends CharacterBody3D
## Controlador de personagem em primeira pessoa.
## - Movimento WASD + corrida + pulo com gravidade (move_and_slide)
## - Câmera mouse-look (corpo gira no eixo Y, cabeça no eixo X)
## - Interação por raycast: abrir portas e pegar UM item por vez (física)
##
## O item é carregado por VELOCIDADE (não por reparent/posição direta) para
## manter o comportamento físico correto e a colisão com paredes, no estilo
## My Summer Car / Mon Bazou.

# --- Movimento ---
@export_group("Movimento")
@export var walk_speed: float = 4.0
@export var sprint_speed: float = 7.0
@export var acceleration: float = 12.0
@export var jump_velocity: float = 6.0
@export var mouse_sensitivity: float = 0.0025
@export var pitch_limit_deg: float = 89.0

# --- Interação / carregar ---
@export_group("Interação")
## Alcance do raycast de interação (metros).
@export var interact_distance: float = 3.0
## Rigidez do "elástico" que puxa o item até o ponto de segurar.
@export var carry_stiffness: float = 12.0
## Velocidade máxima com que o item persegue o ponto de segurar.
@export var carry_max_speed: float = 20.0
## Se o item ficar mais longe que isto do ponto (preso atrás de algo), solta.
@export var carry_break_distance: float = 2.5
## Força do arremesso (botão direito).
@export var throw_impulse: float = 8.0
## Quanto o item gira por "notch" do scroll (radianos). ~12 graus.
@export var carry_rotate_step: float = 0.209
## Rigidez do controle de orientação (segura e gira o item de forma estável).
@export var carry_orient_stiffness: float = 10.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var interact_ray: RayCast3D = $Head/Camera3D/InteractRay
@onready var hold_point: Marker3D = $Head/Camera3D/HoldPoint

var _held_body: RigidBody3D = null
var _held_original_gravity: float = 1.0
## Orientação-alvo do item carregado. O scroll gira este alvo; a física persegue.
var _carry_basis: Basis = Basis.IDENTITY


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	interact_ray.target_position = Vector3(0, 0, -interact_distance)
	camera.current = true  # garante a visão do player (não a do carro) ao nascer


func _unhandled_input(event: InputEvent) -> void:
	# Mouse-look só quando o mouse está capturado.
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		var limit := deg_to_rad(pitch_limit_deg)
		head.rotation.x = clamp(head.rotation.x, -limit, limit)

	# Esc alterna captura do mouse (útil pra sair da janela).
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Recaptura ao clicar de volta na janela.
	if event.is_action_pressed("interact") and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	if event.is_action_pressed("interact"):
		_on_interact()
	elif event.is_action_pressed("throw"):
		_on_throw()

	# Scroll do mouse gira o item segurado no próprio eixo (vertical).
	if _held_body != null and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_rotate_held(1.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_rotate_held(-1.0)

	# Tecla U: melhorar (upgrade) a estação sob a mira.
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
# Interação
# --------------------------------------------------------------------------

func _on_interact() -> void:
	var target := _get_interactable()

	# Com item na mão: se o alvo é interativo mas NÃO é um item (ex.: uma
	# estação), deixa ele usar o que você segura (despejar uvas, vender...).
	# Caso contrário, solta o item.
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
	# Sem item na mão: clique-direito é a "ação secundária" da estação sob a
	# mira (ex.: enviar o mosto pro fermentador).
	if _held_body == null:
		var target := _get_interactable()
		if target != null and target.has_method("secondary_interact"):
			target.secondary_interact(self)
		return
	var body := _held_body
	var dir := -camera.global_transform.basis.z
	_drop()
	body.apply_central_impulse(dir * throw_impulse)


## Retorna o nó interativo sob a mira, ou null.
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
	# Começa a segurar mantendo a orientação atual do item.
	_carry_basis = body.global_transform.basis.orthonormalized()
	# Não colidir com o próprio jogador enquanto carrega (evita empurrão/jitter).
	body.add_collision_exception_with(self)
	# O item na mão não deve bloquear o raycast de interação.
	interact_ray.add_exception(body)
	Interaction.notify_hold_state(true)


## Gira o alvo de orientação do item "por cima" (tombando pra frente/trás),
## em torno do eixo horizontal à direita da câmera — não mais no eixo vertical.
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


## Item atualmente na mão (ou null). Usado pelas estações.
func get_held() -> RigidBody3D:
	return _held_body


## Remove o item da mão (pra uma estação consumir) sem soltá-lo no chão e o
## retorna, restaurando a física do corpo.
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


## Desativa o jogador enquanto ele dirige (o carro assume câmera e input).
func enter_vehicle() -> void:
	if _held_body != null:
		_drop()
	Interaction.set_prompt("")
	visible = false
	$CollisionShape3D.set_deferred("disabled", true)
	set_physics_process(false)
	set_process_unhandled_input(false)


## Reativa o jogador ao sair do carro, posicionando-o em `at`.
func exit_vehicle(at: Transform3D) -> void:
	global_transform = at
	velocity = Vector3.ZERO
	visible = true
	$CollisionShape3D.set_deferred("disabled", false)
	set_physics_process(true)
	set_process_unhandled_input(true)
	camera.current = true


## Move o item carregado em direção ao ponto de segurar usando velocidade.
## Roda no passo de física para o controle de velocidade ficar estável.
func _update_carry() -> void:
	if _held_body == null:
		return

	var to_target := hold_point.global_position - _held_body.global_position

	# Se o item ficou preso atrás de algo (muito longe), solta.
	if to_target.length() > carry_break_distance:
		_drop()
		return

	# Elástico: velocidade proporcional à distância, com teto.
	var desired_velocity := to_target * carry_stiffness
	if desired_velocity.length() > carry_max_speed:
		desired_velocity = desired_velocity.normalized() * carry_max_speed

	_held_body.linear_velocity = desired_velocity

	# Controle de orientação: gira o item até a orientação-alvo (_carry_basis),
	# convertendo a diferença de rotação em velocidade angular. Assim o item
	# fica estável na mão e responde ao scroll sem "cair" pra qualquer lado.
	var current_q := _held_body.global_transform.basis.get_rotation_quaternion()
	var target_q := _carry_basis.get_rotation_quaternion()
	var delta_q := target_q * current_q.inverse()
	if delta_q.w < 0.0:
		delta_q = -delta_q  # caminho mais curto
	var angle := 2.0 * acos(clampf(delta_q.w, -1.0, 1.0))
	var axis := Vector3(delta_q.x, delta_q.y, delta_q.z)
	if angle > 0.0001 and axis.length() > 0.0001:
		_held_body.angular_velocity = axis.normalized() * angle * carry_orient_stiffness
	else:
		_held_body.angular_velocity = Vector3.ZERO


func _update_prompt() -> void:
	if _held_body != null:
		Interaction.set_prompt("[Esq] Soltar     [Scroll] Girar     [Dir] Arremessar")
		return

	var target := _get_interactable()
	if target == null:
		Interaction.set_prompt("")
		return

	if target.has_method("get_prompt"):
		Interaction.set_prompt("[Esq] " + target.get_prompt())
	elif target.is_in_group("pickable"):
		Interaction.set_prompt("[Esq] Pegar")
	else:
		Interaction.set_prompt("[Esq] Interagir")
