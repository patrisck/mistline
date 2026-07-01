extends Node
## Registra no DebugMenu (autoload) os parâmetros ajustáveis DESTE mapa.
## Mantém o menu genérico: aqui é o único lugar que conhece os nós da cena.
## Para expor algo novo, basta uma linha add_float/add_bool/add_action.

@export var player: Node
@export var day_night: Node
@export var world_environment: WorldEnvironment
@export var garage_light: Light3D
@export var workbench_lamp: Light3D


func _ready() -> void:
	# Segurança: só registra se o autoload existir.
	if not Engine.has_singleton("DebugMenu") and get_node_or_null("/root/DebugMenu") == null:
		push_warning("DebugMenu autoload não encontrado; menu de debug indisponível.")
		return

	DebugMenu.clear_params()

	if player != null:
		DebugMenu.add_float("Jogador", "Vel. andar", player, "walk_speed", 1.0, 10.0, 0.1)
		DebugMenu.add_float("Jogador", "Vel. correr", player, "sprint_speed", 1.0, 14.0, 0.1)
		DebugMenu.add_float("Jogador", "Pulo", player, "jump_velocity", 2.0, 12.0, 0.1)
		DebugMenu.add_float("Jogador", "Sensib. mouse", player, "mouse_sensitivity", 0.0005, 0.006, 0.0001)
		DebugMenu.add_float("Jogador", "Força segurar", player, "carry_stiffness", 4.0, 30.0, 0.5)
		DebugMenu.add_float("Jogador", "Passo girar", player, "carry_rotate_step", 0.05, 0.6, 0.01)
		DebugMenu.add_float("Jogador", "Força arremesso", player, "throw_impulse", 2.0, 20.0, 0.5)

	if day_night != null:
		DebugMenu.add_float("Dia / Noite", "Hora do dia", day_night, "time_of_day", 0.0, 1.0, 0.001)
		DebugMenu.add_bool("Dia / Noite", "Pausar ciclo", day_night, "paused")
		DebugMenu.add_float("Dia / Noite", "Duração (s)", day_night, "day_length_seconds", 5.0, 600.0, 1.0)
		DebugMenu.add_float("Dia / Noite", "Ambiente dia", day_night, "day_ambient_energy", 0.0, 2.0, 0.05)
		DebugMenu.add_float("Dia / Noite", "Ambiente noite", day_night, "night_ambient_energy", 0.0, 1.0, 0.01)
		DebugMenu.add_float("Dia / Noite", "Energia sol", day_night, "day_sun_energy", 0.0, 3.0, 0.05)
		DebugMenu.add_action("Dia / Noite", "→ Meio-dia", func() -> void: day_night.time_of_day = 0.5)
		DebugMenu.add_action("Dia / Noite", "→ Entardecer", func() -> void: day_night.time_of_day = 0.72)
		DebugMenu.add_action("Dia / Noite", "→ Meia-noite", func() -> void: day_night.time_of_day = 0.0)

	if world_environment != null and world_environment.environment != null:
		var env := world_environment.environment
		DebugMenu.add_float("Névoa / Pós", "Fog densidade", env, "fog_density", 0.0, 0.1, 0.001)
		DebugMenu.add_float("Névoa / Pós", "Fog volumétrico", env, "volumetric_fog_density", 0.0, 0.1, 0.001)
		DebugMenu.add_float("Névoa / Pós", "Glow", env, "glow_intensity", 0.0, 2.0, 0.05)
		DebugMenu.add_float("Névoa / Pós", "Contraste", env, "adjustment_contrast", 0.5, 2.0, 0.01)
		DebugMenu.add_float("Névoa / Pós", "Saturação", env, "adjustment_saturation", 0.0, 2.0, 0.01)
		DebugMenu.add_float("Névoa / Pós", "Exposição", env, "tonemap_exposure", 0.2, 2.0, 0.05)

	if garage_light != null:
		DebugMenu.add_float("Luzes", "Lâmpada garagem", garage_light, "light_energy", 0.0, 10.0, 0.1)
	if workbench_lamp != null:
		DebugMenu.add_float("Luzes", "Holofote bancada", workbench_lamp, "light_energy", 0.0, 12.0, 0.1)
