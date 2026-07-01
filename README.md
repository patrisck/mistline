# Mistline

Jogo de **produção de vinho artesanal** em primeira pessoa, num vale sombrio e
enevoado — inspirado no ofício tátil de *Mon Bazou* / *My Summer Car*. Feito na
**Godot Engine 4.7** com **GDScript**.

> Estágio atual: **mecânicas base + fundação do sistema de vinho**. Gráficos são
> placeholders (primitivas); o foco é a fundação técnica e a atmosfera (luz/névoa).

## O que já funciona

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
- **Menu de debug (`F1`)** — edita parâmetros em tempo real por sliders/toggles
  (velocidades, sensibilidade, névoa, glow, luzes, hora do dia, vinho...) e imprime
  os valores no console pra você cravar depois. Sistema genérico e reutilizável.
- **🍷 Sistema de vinho (MVP)** — o ciclo completo, todo manual (tier 0):
  1. **Depósito de uvas** — compre uma caixa ($).
  2. **Esmagador** — despeje as uvas, pise (clique esq) e envie o mosto (clique dir).
     A qualidade da extração tem um ponto ideal (~85%): nem cru, nem amargo.
  3. **Fermentador** — adicione levedura e mantenha a temperatura na faixa (clique
     pra atiçar o calor); no fim, engarrafe.
  4. **Balcão** — leve as garrafas e venda. Preço = qualidade.
  - **Progressão simples → automático:** cada estação sobe de tier pagando (`U`).
    Esmagador vira automático; fermentador ganha temperatura automática e depois
    engarrafamento automático.
- **Mapa de teste** — garagem que virou vinícola, com as 4 estações.

## Controles

| Ação | Tecla / Botão |
|------|---------------|
| Mover | `W` `A` `S` `D` |
| Correr | `Shift` |
| Pular | `Espaço` |
| Olhar | Mouse |
| Interagir / Pegar / Soltar | **Botão esquerdo** do mouse |
| Girar item segurado | **Scroll** do mouse |
| Arremessar item / ação secundária da estação (enviar mosto) | **Botão direito** do mouse |
| Melhorar (upgrade) a estação sob a mira | `U` |
| Liberar/recapturar mouse | `Esc` |
| Abrir/fechar menu de debug | `F1` |

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
│   ├── wine/                     # Estações e itens da vinícola
│   │   ├── grape_bin.tscn · crusher.tscn · fermenter.tscn · sales_counter.tscn
│   │   └── grape_crate.tscn · wine_bottle.tscn
│   └── ui/hud.tscn               # Mira + prompt + dinheiro
├── scripts/
│   ├── interaction_manager.gd    # Autoload: barramento de sinais Player↔UI
│   ├── player.gd                 # Controlador + carregar/girar item
│   ├── hud.gd                    # HUD
│   ├── crosshair.gd              # Mira desenhada por código (feedback de alvo)
│   ├── day_night_cycle.gd        # Ciclo de dia/noite (sol, ambiente, névoa)
│   ├── debug_menu.gd             # Autoload: menu de debug genérico (F1)
│   ├── debug_bindings.gd         # Registra os parâmetros do mapa no menu
│   ├── interactables/
│   │   ├── door.gd
│   │   └── pickable.gd
│   └── wine/                     # Sistema de vinho
│       ├── game_state.gd         # Autoload: economia (dinheiro)
│       ├── wine_batch.gd         # O "lote" (dados que fluem entre estações)
│       ├── station.gd            # Base: tiers + upgrade (manual → automático)
│       ├── grape_bin.gd · crusher.gd · fermenter.gd · sales_counter.gd
│       └── grape_crate.gd · wine_bottle.gd
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
