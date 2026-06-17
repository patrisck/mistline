# Mistline

Simulação de garagem / sandbox de sobrevivência veicular em ambiente rural
(Serra Gaúcha, anos 1990). Referências de gênero: Mon Bazou, My Summer Car.
Mecânicas centrais: dirigir, manutenção de veículo, economia simples,
exploração em primeira pessoa, interação com objetos.

## Stack

- Engine: Godot 4.6 (estável), renderer Forward+.
- Linguagem: GDScript (não C#).
- Física 3D: Jolt Physics (motor padrão do Godot 4.6 para 3D).
- Physics Ticks per Second: 120 (estabilidade de física veicular futura).
- Sem addons de terceiros nesta fase. Avaliação de addon de veículo
  (Godot Easy Vehicle Physics) fica para fase posterior.

## Estrutura de pastas

- scenes/    — cenas .tscn (ex.: Main.tscn).
- scripts/   — scripts .gd.
- assets/    — assets brutos: modelos, texturas, áudio, fontes.
- resources/ — recursos do Godot (.tres/.res): dados/materiais customizados.
- addons/    — plugins de terceiros (vazia nesta fase).

## Convenções de nomenclatura

- Variáveis e funções: snake_case.
- Classes (class_name): PascalCase.
- Nomes de cena/arquivo .tscn e nós na árvore: PascalCase.
- Constantes: UPPER_SNAKE_CASE.
- Arquivos de script: snake_case.gd (um script por arquivo).
- Sinais (signals): snake_case.

## Decisões técnicas (não reconsiderar sem pedido)

- Godot 4.6 / Forward+ / GDScript / Jolt Physics / 120 ticks/s — fixos.
- Interação com objetos seguirá um contrato tipo IInteractable, a ser
  definido em fase posterior. Não implementar ainda.

## Não fazer

- Não reinicializar project.godot nem trocar renderer/física/linguagem sem pedido.
- Não alterar Physics Ticks per Second (120).
- Não criar scripts, sistemas ou pastas fora do escopo pedido.
- Não adicionar addons sem pedido.
- Não abrir/rodar o editor Godot automaticamente.
- (Seção a ser expandida pelo dono do projeto conforme o jogo evolui.)
