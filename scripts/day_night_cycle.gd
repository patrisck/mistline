extends Node
## Ciclo de dia e noite.
## Arca o sol (DirectionalLight3D) ao longo do tempo e cruza cor/energia da luz,
## da luz ambiente e da névoa entre estados de dia e noite. A neblina é mantida
## VISÍVEL de dia (densidade constante, cor mais clara), conforme pedido.
##
## O céu procedural desenha o disco do sol na direção da luz automaticamente,
## então o pôr/nascer do sol e o brilho no horizonte saem "de graça".

## Duração de um dia completo (segundos). Ajuste no inspetor para testar.
@export var day_length_seconds: float = 120.0
## Hora inicial no ciclo: 0=meia-noite, 0.25=amanhecer, 0.5=meio-dia, 0.75=entardecer.
@export_range(0.0, 1.0) var start_time: float = 0.32
## Pausa o ciclo (deixa a hora fixa em start_time).
@export var paused: bool = false
## Azimute do sol (direção no plano horizontal), em graus.
@export var sun_azimuth_deg: float = -35.0

@export_group("Sol")
@export var day_sun_color: Color = Color(0.92, 0.94, 1.0)
@export var dusk_sun_color: Color = Color(1.0, 0.55, 0.3)
@export var day_sun_energy: float = 1.3

@export_group("Ambiente / Névoa")
@export var day_ambient_energy: float = 0.85
@export var night_ambient_energy: float = 0.12
@export var day_fog_color: Color = Color(0.66, 0.7, 0.76)
@export var night_fog_color: Color = Color(0.1, 0.13, 0.2)

@export_group("Referências")
@export var sun: DirectionalLight3D
@export var world_environment: WorldEnvironment

var time_of_day: float = 0.0
var _env: Environment


func _ready() -> void:
	time_of_day = start_time
	if world_environment != null:
		_env = world_environment.environment
	_apply()


func _process(delta: float) -> void:
	if paused or day_length_seconds <= 0.0:
		return
	time_of_day = fposmod(time_of_day + delta / day_length_seconds, 1.0)
	_apply()


func _apply() -> void:
	# sun_up: 1 ao meio-dia, 0 no horizonte (amanhecer/entardecer), -1 à meia-noite.
	var sun_up := sin((time_of_day - 0.25) * TAU)
	# Quanto é "dia" (0 de noite, 1 de dia), com transição suave no horizonte.
	var day_amount := clampf(smoothstep(-0.05, 0.25, sun_up), 0.0, 1.0)

	if sun != null:
		# Elevação: pitch -90° ao meio-dia (aponta pra baixo), +90° à meia-noite.
		var pitch := -sun_up * deg_to_rad(90.0)
		sun.rotation = Vector3(pitch, deg_to_rad(sun_azimuth_deg), 0.0)

		# Cor quente perto do horizonte, neutra/fria com o sol alto.
		var horizon := clampf(1.0 - absf(sun_up) * 2.5, 0.0, 1.0)
		sun.light_color = day_sun_color.lerp(dusk_sun_color, horizon)
		sun.light_energy = lerpf(0.0, day_sun_energy, day_amount)
		# Apaga o sol de noite (evita luz vindo de baixo do chão).
		sun.visible = day_amount > 0.001

	if _env != null:
		_env.ambient_light_energy = lerpf(night_ambient_energy, day_ambient_energy, day_amount)
		# Névoa continua presente; só muda de cor (clara de dia, azul escura de noite).
		_env.fog_light_color = night_fog_color.lerp(day_fog_color, day_amount)
