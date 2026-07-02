# Mistline

A **first-person artisanal wine-making game** set in a moody, foggy valley —
inspired by the tactile craft of *Mon Bazou* / *My Summer Car*. Built in
**Godot Engine 4.7** with **GDScript**.

> Current stage: **base mechanics + wine system foundation**. Graphics are
> placeholders (primitives); the focus is the technical foundation and the
> atmosphere (light/fog).

## What already works

- **First-person character** — `CharacterBody3D` with WASD movement, sprint,
  jump, and gravity.
- **Mouse-look camera** — the body yaws horizontally, the head pitches vertically
  (with a tilt limit). Mouse captured, `Esc` releases/recaptures.
- **Raycast interaction (left click)**:
  - **Open / close doors** (physics-based, pushes the player correctly).
  - **Pick up physics items** — one at a time. The item is carried via velocity
    control, so it collides with walls and drops if it gets stuck.
- **Rotate the held item** on its own axis with the mouse **scroll**.
- **Throw** the held item (right click).
- **HUD** with a crosshair that reacts to interactive targets, a context panel, and a vignette.
- **Moody atmosphere** — volumetric fog, AgX tonemapping, mood lighting
  (cool sun + warm work lamps). Visual focus on light, not textures.
- **Day/night cycle** — the sun arcs across the sky, crossfading light, ambient,
  and fog color/energy. Fog stays **visible during the day** (lighter color).
  Duration and starting time adjustable on the `DayNightCycle` node.
- **Debug menu (`F1`)** — edits parameters in real time via sliders/toggles
  (speeds, sensitivity, fog, glow, lights, time of day, wine...) and prints
  the values to the console so you can lock them in later. Generic, reusable system.
- **🍷 Wine system (MVP)** — the full cycle, all manual (tier 0):
  1. **Grape bin** — buy a crate ($).
  2. **Crusher** — pour the grapes, stomp (LMB), and send the must (RMB).
     Extraction quality has a sweet spot (~85%): neither raw nor bitter.
  3. **Fermenter** — add yeast and keep the temperature in range (click to
     stoke the heat); bottle it when done.
  4. **Counter** — carry the bottles and sell. Price = quality.
  - **Simple → automated progression:** each station levels up by paying (`U`).
    The crusher becomes automatic; the fermenter gains automatic temperature and
    later automatic bottling.
- **🚗 Car (simcade RWD + drift)** — `VehicleBody3D` with raycast suspension,
  **rear-wheel drive** and a **third-person chase camera**. Drift is not an
  assist — it emerges from physics: in low gears the torque overwhelms rear
  grip and the back steps out; in high gears it stays planted (like real life).
  Enter/exit, steering, handbrake, and a **manual gearbox** (R/N/1–5).
  Low center of gravity; grip/engine tunable in the debug menu (`F1` → "Car").
- **Test map** — a garage turned winery (4 stations) + a car parked outside.

## Controls

| Action | Key / Button |
|--------|--------------|
| Move | `W` `A` `S` `D` |
| Sprint | `Shift` |
| Jump | `Space` |
| Look | Mouse |
| Interact / Pick up / Drop | **Left click** |
| Rotate held item | **Mouse scroll** |
| Throw item / station's secondary action (send must) | **Right click** |
| Upgrade the station under the crosshair | `U` |
| Release/recapture mouse | `Esc` |
| Open/close debug menu | `F1` |
| Enter car / exit | **Left click** / `F` |
| Drive (3rd person, RWD) | `W` throttle · `S` brake · `A`/`D` steer · `Space` handbrake |
| Clutch (hold) | `Shift` — revs climb; release at high RPM for a clutch-kick drift |
| Shift gear (up / down) | `E` / `Q` (no clutch needed to shift) |

> **Drifting:** in 1st/2nd gear the torque overwhelms rear grip (friction-circle
> approximation) so throttling hard breaks the rear loose — counter-steer to hold
> it. High gears grip. Or hold `Shift` (clutch), rev up, release for a kick.
> There's a cone **skidpad** by the garage for practice.

## How to run

1. Open the project in **Godot 4.7** (`Import` → select the folder / `project.godot`).
2. Press **F5** (or the ▶ *Run Project* button).

The starting scene is `scenes/world/test_map.tscn`.

## Project structure

```
mistline/
├── project.godot            # Config, input map, physics layers, autoloads
├── icon.svg
├── scenes/
│   ├── player/player.tscn        # First-person character
│   ├── world/test_map.tscn       # Test map (main scene)
│   ├── interactables/
│   │   ├── door.tscn             # Hinged door
│   │   ├── pickable_crate.tscn   # Pickable crate
│   │   └── pickable_wheel.tscn   # Pickable tire
│   ├── wine/                     # Winery stations and items
│   │   ├── grape_bin.tscn · crusher.tscn · fermenter.tscn · sales_counter.tscn
│   │   └── grape_crate.tscn · wine_bottle.tscn
│   ├── vehicle/car.tscn          # Simcade car
│   └── ui/hud.tscn               # Crosshair + prompt + money
├── scripts/
│   ├── interaction_manager.gd    # Autoload: Player↔UI signal bus
│   ├── player.gd                 # Controller + carry/rotate item + vehicle hooks
│   ├── hud.gd                    # HUD
│   ├── crosshair.gd              # Code-drawn crosshair (target feedback)
│   ├── day_night_cycle.gd        # Day/night cycle (sun, ambient, fog)
│   ├── debug_menu.gd             # Autoload: generic debug menu (F1)
│   ├── debug_bindings.gd         # Registers this map's parameters with the menu
│   ├── interactables/
│   │   ├── door.gd
│   │   └── pickable.gd
│   ├── vehicle/
│   │   └── car.gd                # VehicleBody3D controller
│   └── wine/                     # Wine system
│       ├── game_state.gd         # Autoload: economy (money)
│       ├── wine_batch.gd         # The "batch" (data flowing between stations)
│       ├── station.gd            # Base: tiers + upgrade (manual → automated)
│       ├── grape_bin.gd · crusher.gd · fermenter.gd · sales_counter.gd
│       └── grape_crate.gd · wine_bottle.gd
└── assets/
    └── shaders/vignette.gdshader # HUD's atmospheric vignette
```

### Interaction convention

Any interactive object:
- belongs to the `interactable` group (doors, stations) or `pickable` (items);
- implements `interact(player)` and/or `get_prompt() -> String`.

The `Player` does the raycast, finds the target, and calls these methods — so
adding a new interactive object doesn't require touching the player.

## Physics layers

| Layer | Use |
|-------|-----|
| 1 | `world` (floor, walls, solid objects) |
| 2 | `player` |
| 3 | `interactable` (doors, stations, items) |

## Next steps (planned)

- Barrel aging (carry physical barrels), grape styles/blends, own vineyard tied
  to the day/night cycle, more automation tiers.
- Inventory / tools.
- Final low-poly art.

---
🤖 Technical foundation built with [Claude Code](https://claude.com/claude-code)
