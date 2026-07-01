# Mistline

Protótipo de um **simulador de reforma automotiva** em primeira pessoa, no estilo
*Mon Bazou* e *My Summer Car*. Feito na **Godot Engine 4.7** com **GDScript**.

> Estágio atual: **Etapa 1 — Mecânicas base**. Gráficos são placeholders (primitivas).
> O foco aqui é a fundação técnica, não a arte.

## O que já funciona (Etapa 1)

- **Personagem em 1ª pessoa** — `CharacterBody3D` com movimento WASD, corrida,
  pulo e gravidade.
- **Câmera mouse-look** — o corpo gira no eixo horizontal, a cabeça no vertical
  (com limite de inclinação). Mouse capturado, `Esc` libera/recaptura.
- **Interação por raycast (clique esquerdo)**:
  - **Abrir / fechar portas** (física, empurra o jogador corretamente).
  - **Pegar itens com física** — um por vez. O item é carregado por controle de
    velocidade, então ele colide com paredes e cai se ficar preso.
- **Girar item** no próprio eixo com o **scroll** do mouse enquanto segura.
- **Arremessar** o item segurado (clique direito).
- **HUD** com mira que reage a alvos interativos, painel de contexto e vinheta.
- **Atmosfera sombria** — neblina volumétrica, tonemapping AgX, iluminação de
  clima (sol frio + lâmpadas quentes de trabalho). Foco visual em luz, não em texturas.
- **Ciclo de dia e noite** — o sol arca pelo céu mudando cor/energia da luz, do
  ambiente e da névoa. Neblina fica **visível de dia** (cor mais clara). Duração e
  hora inicial ajustáveis no nó `DayNightCycle`.
- **Mapa de teste** — garagem com porta, bancada e itens espalhados.

## Controles

| Ação | Tecla / Botão |
|------|---------------|
| Mover | `W` `A` `S` `D` |
| Correr | `Shift` |
| Pular | `Espaço` |
| Olhar | Mouse |
| Interagir / Pegar / Soltar | **Botão esquerdo** do mouse |
| Girar item segurado | **Scroll** do mouse |
| Arremessar item | **Botão direito** do mouse |
| Liberar/recapturar mouse | `Esc` |

## Como rodar

1. Abra o projeto na **Godot 4.7** (`Import` → selecione a pasta / `project.godot`).
2. Pressione **F5** (ou o botão ▶ *Run Project*).

A cena inicial é `scenes/world/test_map.tscn`.

## Estrutura do projeto

```
mistline/
├── project.godot            # Config, input map, camadas de física, autoloads
├── icon.svg
├── scenes/
│   ├── player/player.tscn        # Personagem 1ª pessoa
│   ├── world/test_map.tscn       # Mapa de teste (cena principal)
│   ├── interactables/
│   │   ├── door.tscn             # Porta articulada
│   │   ├── pickable_crate.tscn   # Caixa pegável
│   │   └── pickable_wheel.tscn   # Pneu pegável
│   └── ui/hud.tscn               # Mira + prompt de contexto
├── scripts/
│   ├── interaction_manager.gd    # Autoload: barramento de sinais Player↔UI
│   ├── player.gd                 # Controlador + carregar/girar item
│   ├── hud.gd                    # HUD
│   ├── crosshair.gd              # Mira desenhada por código (feedback de alvo)
│   ├── day_night_cycle.gd        # Ciclo de dia/noite (sol, ambiente, névoa)
│   └── interactables/
│       ├── door.gd
│       └── pickable.gd
└── assets/
    └── shaders/vignette.gdshader # Vinheta atmosférica do HUD
```

### Convenção de interação

Qualquer objeto interativo:
- fica no grupo `interactable` (portas) ou `pickable` (itens);
- implementa `interact(player)` e/ou `get_prompt() -> String`.

O `Player` faz o raycast, identifica o alvo e chama esses métodos — então adicionar
um novo objeto interativo não exige mexer no player.

## Camadas de física

| Camada | Uso |
|--------|-----|
| 1 | `world` (chão, paredes, objetos sólidos) |
| 2 | `player` |
| 3 | `interactable` (portas e itens) |

## Próximas etapas (planejado)

- Sistema de veículo (chassi, rodas, motor) e montagem/desmontagem de peças.
- Inventário / ferramentas.
- Arte low-poly definitiva.

---
🤖 Base técnica criada com [Claude Code](https://claude.com/claude-code)
