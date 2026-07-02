extends Node
## Registers the adjustable parameters of THIS map with the DebugMenu (autoload).
## Keeps the menu generic: this is the only place that knows the scene's nodes.
## To expose something new, just add one add_float/add_bool/add_action line.

@export var player: Node
@export var day_night: Node
@export var world_environment: WorldEnvironment
@export var garage_light: Light3D
@export var workbench_lamp: Light3D
@export var fermenter: Node
@export var grape_bin: Node
@export var sales_counter: Node
@export var car: Node


func _ready() -> void:
	# Safety: only register if the autoload exists.
	if get_node_or_null("/root/DebugMenu") == null:
		push_warning("DebugMenu autoload not found; debug menu unavailable.")
		return

	# Resolve nodes by name from the parent. Doesn't depend on resolving an
	# exported NodePath (hand-written in the .tscn, which doesn't always resolve).
	var root := get_parent()
	if root != null:
		if player == null:
			player = root.get_node_or_null("Player")
		if day_night == null:
			day_night = root.get_node_or_null("DayNightCycle")
		if world_environment == null:
			world_environment = root.get_node_or_null("WorldEnvironment")
		if garage_light == null:
			garage_light = root.get_node_or_null("GarageLight")
		if workbench_lamp == null:
			workbench_lamp = root.get_node_or_null("WorkbenchLamp")

		if fermenter == null:
			fermenter = root.get_node_or_null("Fermenter")
		if grape_bin == null:
			grape_bin = root.get_node_or_null("GrapeBin")
		if sales_counter == null:
			sales_counter = root.get_node_or_null("SalesCounter")
		if car == null:
			car = root.get_node_or_null("Car")

	DebugMenu.clear_params()

	if player != null:
		DebugMenu.add_float("Player", "Walk speed", player, "walk_speed", 1.0, 10.0, 0.1)
		DebugMenu.add_float("Player", "Sprint speed", player, "sprint_speed", 1.0, 14.0, 0.1)
		DebugMenu.add_float("Player", "Jump", player, "jump_velocity", 2.0, 12.0, 0.1)
		DebugMenu.add_float("Player", "Mouse sensitivity", player, "mouse_sensitivity", 0.0005, 0.006, 0.0001)
		DebugMenu.add_float("Player", "Carry strength", player, "carry_stiffness", 4.0, 30.0, 0.5)
		DebugMenu.add_float("Player", "Rotate step", player, "carry_rotate_step", 0.05, 0.6, 0.01)
		DebugMenu.add_float("Player", "Throw force", player, "throw_impulse", 2.0, 20.0, 0.5)

	if day_night != null:
		DebugMenu.add_float("Day / Night", "Time of day", day_night, "time_of_day", 0.0, 1.0, 0.001)
		DebugMenu.add_bool("Day / Night", "Pause cycle", day_night, "paused")
		DebugMenu.add_float("Day / Night", "Duration (s)", day_night, "day_length_seconds", 5.0, 600.0, 1.0)
		DebugMenu.add_float("Day / Night", "Day ambient", day_night, "day_ambient_energy", 0.0, 2.0, 0.05)
		DebugMenu.add_float("Day / Night", "Night ambient", day_night, "night_ambient_energy", 0.0, 1.0, 0.01)
		DebugMenu.add_float("Day / Night", "Sun energy", day_night, "day_sun_energy", 0.0, 3.0, 0.05)
		DebugMenu.add_action("Day / Night", "→ Noon", func() -> void: day_night.time_of_day = 0.5)
		DebugMenu.add_action("Day / Night", "→ Dusk", func() -> void: day_night.time_of_day = 0.72)
		DebugMenu.add_action("Day / Night", "→ Midnight", func() -> void: day_night.time_of_day = 0.0)

	if world_environment != null and world_environment.environment != null:
		var env := world_environment.environment
		DebugMenu.add_float("Fog / Post", "Fog density", env, "fog_density", 0.0, 0.1, 0.001)
		DebugMenu.add_float("Fog / Post", "Volumetric fog", env, "volumetric_fog_density", 0.0, 0.1, 0.001)
		DebugMenu.add_float("Fog / Post", "Glow", env, "glow_intensity", 0.0, 2.0, 0.05)
		DebugMenu.add_float("Fog / Post", "Contrast", env, "adjustment_contrast", 0.5, 2.0, 0.01)
		DebugMenu.add_float("Fog / Post", "Saturation", env, "adjustment_saturation", 0.0, 2.0, 0.01)
		DebugMenu.add_float("Fog / Post", "Exposure", env, "tonemap_exposure", 0.2, 2.0, 0.05)

	if garage_light != null:
		DebugMenu.add_float("Lights", "Garage lamp", garage_light, "light_energy", 0.0, 10.0, 0.1)
	if workbench_lamp != null:
		DebugMenu.add_float("Lights", "Workbench spotlight", workbench_lamp, "light_energy", 0.0, 12.0, 0.1)

	if fermenter != null:
		DebugMenu.add_float("Wine", "Fermentation (s)", fermenter, "ferment_seconds", 5.0, 120.0, 1.0)
	if grape_bin != null:
		DebugMenu.add_float("Wine", "Grape price", grape_bin, "cost", 0.0, 100.0, 1.0)
	if sales_counter != null:
		DebugMenu.add_float("Wine", "Price/quality", sales_counter, "price_per_quality", 0.0, 3.0, 0.1)
	DebugMenu.add_action("Wine", "+ $500 (free)", func() -> void: GameState.add_money(500))

	if car != null:
		# Drift threshold: raise engine force or lower rear grip to drift more
		# easily (in lower gears). Front grip = steering bite.
		DebugMenu.add_float("Car", "Engine force", car, "max_engine_force", 100.0, 3000.0, 25.0)
		DebugMenu.add_float("Car", "Front grip", car, "front_grip", 0.5, 8.0, 0.1)
		DebugMenu.add_float("Car", "Rear grip", car, "rear_grip", 0.5, 8.0, 0.1)
		DebugMenu.add_float("Car", "Handbrake rear grip", car, "handbrake_rear_grip", 0.1, 4.0, 0.1)
		DebugMenu.add_float("Car", "Roll influence (0=stable)", car, "roll_influence", 0.0, 1.0, 0.01)
		DebugMenu.add_float("Car", "Max steer", car, "max_steer", 0.2, 1.0, 0.02)
		DebugMenu.add_float("Car", "Cam distance", car, "cam_distance", 3.0, 12.0, 0.2)
		DebugMenu.add_float("Car", "Cam height", car, "cam_height", 1.0, 6.0, 0.1)
