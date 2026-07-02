extends Node
## Day/night cycle.
## Arcs the sun (DirectionalLight3D) over time and crossfades sun/ambient/fog
## light color and energy between day and night states. Fog stays VISIBLE
## during the day (constant density, lighter color), as requested.
##
## The procedural sky draws the sun disc in the light's direction automatically,
## so sunrise/sunset and horizon glow come "for free".

## Length of a full day (seconds). Adjust in the inspector for testing.
@export var day_length_seconds: float = 120.0
## Starting time in the cycle: 0=midnight, 0.25=sunrise, 0.5=noon, 0.75=sunset.
@export_range(0.0, 1.0) var start_time: float = 0.32
## Pauses the cycle (keeps time fixed at start_time).
@export var paused: bool = false
## Sun azimuth (direction on the horizontal plane), in degrees.
@export var sun_azimuth_deg: float = -35.0

@export_group("Sun")
@export var day_sun_color: Color = Color(0.92, 0.94, 1.0)
@export var dusk_sun_color: Color = Color(1.0, 0.55, 0.3)
@export var day_sun_energy: float = 1.7

@export_group("Ambient / Fog")
@export var day_ambient_energy: float = 1.0
@export var night_ambient_energy: float = 0.12
@export var day_fog_color: Color = Color(0.66, 0.7, 0.76)
@export var night_fog_color: Color = Color(0.1, 0.13, 0.2)

@export_group("References")
@export var sun: DirectionalLight3D
@export var world_environment: WorldEnvironment

var time_of_day: float = 0.0
var _env: Environment


func _ready() -> void:
	time_of_day = start_time
	# Resolve nodes by name from the parent as a fallback: an exported
	# NodePath hand-written in the .tscn doesn't always resolve (came back
	# null, breaking the cycle).
	var root := get_parent()
	if root != null:
		if sun == null:
			sun = root.get_node_or_null("Sun")
		if world_environment == null:
			world_environment = root.get_node_or_null("WorldEnvironment")
	if world_environment != null:
		_env = world_environment.environment
	if sun == null:
		push_warning("DayNightCycle: 'Sun' node (DirectionalLight3D) not found.")
	_apply()


func _process(delta: float) -> void:
	# Advance time only when not paused; but ALWAYS reapply, so external
	# changes (e.g. time scrub from the debug menu) take effect even while
	# the cycle is paused.
	if not paused and day_length_seconds > 0.0:
		time_of_day = fposmod(time_of_day + delta / day_length_seconds, 1.0)
	_apply()


func _apply() -> void:
	# sun_up: 1 at noon, 0 at the horizon (sunrise/sunset), -1 at midnight.
	var sun_up := sin((time_of_day - 0.25) * TAU)
	# How much it's "day" (0 at night, 1 at day), with a smooth horizon transition.
	var day_amount := clampf(smoothstep(-0.05, 0.25, sun_up), 0.0, 1.0)

	if sun != null:
		# Elevation: pitch -90° at noon (points down), +90° at midnight.
		var pitch := -sun_up * deg_to_rad(90.0)
		sun.rotation = Vector3(pitch, deg_to_rad(sun_azimuth_deg), 0.0)

		# Warm color near the horizon, neutral/cool with the sun high.
		var horizon := clampf(1.0 - absf(sun_up) * 2.5, 0.0, 1.0)
		sun.light_color = day_sun_color.lerp(dusk_sun_color, horizon)
		sun.light_energy = lerpf(0.0, day_sun_energy, day_amount)
		# Turns the sun off at night (avoids light coming from below the ground).
		sun.visible = day_amount > 0.001

	if _env != null:
		_env.ambient_light_energy = lerpf(night_ambient_energy, day_ambient_energy, day_amount)
		# Fog stays present; only its color changes (light by day, dark blue by night).
		_env.fog_light_color = night_fog_color.lerp(day_fog_color, day_amount)
