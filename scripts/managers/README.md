# 🎮 Sistema de Managers - Snooker Cats

Este documento explica como funciona o sistema de managers no jogo **Snooker Cats** e como utilizá-los para orquestrar o funcionamento do jogo.

## 📋 Visão Geral

O sistema de managers é baseado no padrão **Singleton** e **Observer**, onde cada manager é responsável por uma área específica do jogo e se comunica com outros managers através de sinais.

## 🔧 Managers Disponíveis

### 1. 🎬 GameStateManager
**Responsabilidade**: Gerencia os estados globais do jogo (Menu, Jogo, Pausa, etc.)

```gdscript
# Mudar estado do jogo
GameStateManager.set_current_state(GameStateManager.GameState.PLAYING)

# Verificar estado atual
if GameStateManager.is_in_state(GameStateManager.GameState.PLAYING):
    print("Jogo está rodando")

# Usar pilha de estados
GameStateManager.push_state(GameStateManager.GameState.PAUSED)
GameStateManager.pop_state()  # Volta ao estado anterior
```

### 2. 🎬 SceneManager
**Responsabilidade**: Gerencia troca de cenas com transições

```gdscript
# Trocar cena com transição
SceneManager.change_scene("res://scenes/main/Main.tscn")

# Métodos de conveniência
SceneManager.go_to_main_menu()
SceneManager.go_to_game()
SceneManager.reload_current_scene()
```

### 3. 🐾 CatManager
**Responsabilidade**: Gerencia jogadores (gatos) e suas propriedades

```gdscript
# Criar um gato
var cat = CatManager.create_cat(1, Vector2(100, 100), true)

# Dar dano a um gato
CatManager.damage_cat(1, 25)

# Dar carta a um gato
CatManager.give_card_to_cat(1, "explosive_ball")

# Obter gatos vivos
var alive_cats = CatManager.get_alive_cats()
```

### 4. 🃏 CardManager
**Responsabilidade**: Sistema de cartas com poderes especiais

```gdscript
# Comprar carta
CardManager.draw_card(1)

# Usar carta
CardManager.use_card("explosive_ball", 1)

# Verificar se pode usar carta
if CardManager.can_use_card("teleport_ball", 1):
    CardManager.use_card("teleport_ball", 1)

# Obter cartas na mão
var hand = CardManager.get_hand(1)
```

### 5. 🎱 CueManager
**Responsabilidade**: Mecânica de tacada e efeitos especiais

```gdscript
# Iniciar mira
CueManager.start_aiming(1, ball_position)

# Atualizar direção da mira
CueManager.update_aim(target_position)

# Carregar força
CueManager.start_charging()

# Disparar
CueManager.fire_shot()

# Verificar efeitos ativos
var effects = CueManager.get_active_effects(1)
```

### 6. 🖥️ UIManager
**Responsabilidade**: Interface do usuário e elementos visuais

```gdscript
# Mostrar diferentes UIs
UIManager.show_main_menu()
UIManager.show_game_ui()
UIManager.show_pause_menu()

# Atualizar elementos específicos
UIManager.update_health_bar(1, 75, 100)
UIManager.update_power_bar(500, 1000)
UIManager.show_notification("Carta usada!")

# Mostrar indicadores
UIManager.show_damage_indicator(Vector2(100, 100), 25, Color.RED)
```

### 7. 🔊 AudioManager
**Responsabilidade**: Sons e música do jogo

```gdscript
# Tocar música
AudioManager.play_game_music()
AudioManager.play_menu_music()

# Tocar efeitos sonoros
AudioManager.play_ball_hit_sound()
AudioManager.play_explosion_sound()
AudioManager.play_cat_sound("meow")

# Controlar volume
AudioManager.set_music_volume(0.8)
AudioManager.set_sfx_volume(0.6)
```

### 8. ✨ EffectsManager
**Responsabilidade**: Efeitos visuais, partículas e animações

```gdscript
# Criar efeitos de partículas
EffectsManager.create_explosion(Vector2(100, 100))
EffectsManager.create_magic_effect(Vector2(200, 200), Color.BLUE)

# Efeitos de animação
EffectsManager.create_bounce_effect(node, 0.3, 0.5)
EffectsManager.create_fade_effect(node, 1.0, 0.0, 1.0)

# Efeitos específicos de cartas
EffectsManager.play_card_effect("explosive_ball", 1)
EffectsManager.add_ball_effect(ball, "ghost_effect")
```

### 9. 🎮 GameManager
**Responsabilidade**: Lógica principal do jogo e fluxo de turnos

```gdscript
# Iniciar jogo
GameManager.start_game()

# Obter informações do jogo
var current_player = GameManager.get_current_player()
var score = GameManager.get_player_score(1)
var turn_time = GameManager.get_current_turn_time()

# Controlar jogo
GameManager.pause_game()
GameManager.resume_game()
GameManager.restart_game()
```

## 🔄 Fluxo de Comunicação

Os managers se comunicam através de **sinais** para manter baixo acoplamento:

```gdscript
# Exemplo de conexão de sinais
func _ready():
    CardManager.card_used.connect(_on_card_used)
    CueManager.shot_fired.connect(_on_shot_fired)
    GameStateManager.state_changed.connect(_on_state_changed)

func _on_card_used(card_name: String, player_id: int):
    # Reagir ao uso de carta
    EffectsManager.play_card_effect(card_name, player_id)
    AudioManager.play_card_sound(card_name)
```

## 🎯 Exemplos de Uso

### Implementar uma Nova Carta

```gdscript
# 1. Adicionar carta no CardManager
func _load_card_data():
    cards_data["nova_carta"] = {
        "name": "Nova Carta",
        "description": "Faz algo incrível",
        "mana_cost": 3,
        "rarity": "epic"
    }

# 2. Implementar efeito no CueManager
func _apply_card_effect(card_name: String, player_id: int):
    match card_name:
        "nova_carta":
            _aplicar_efeito_especial(player_id)

# 3. Adicionar efeito visual no EffectsManager
func play_card_effect(card_name: String, player_id: int):
    match card_name:
        "nova_carta":
            create_magic_effect(position, Color.PURPLE)
```

### Criar Nova Tela de UI

```gdscript
# 1. Adicionar no UIManager
func show_nova_tela():
    _show_ui_element("nova_tela")

# 2. Registrar caminho da cena
func _load_ui_element(element_name: String):
    var scene_paths = {
        "nova_tela": "res://scenes/ui/NovaTela.tscn"
    }
```

## 🚀 Boas Práticas

1. **Use sinais** para comunicação entre managers
2. **Não acesse managers diretamente** de scripts que não sejam managers
3. **Mantenha responsabilidades separadas** - cada manager tem sua função específica
4. **Teste isoladamente** cada manager antes de integrar
5. **Use os métodos de conveniência** quando disponíveis

## 🔍 Debugging

Para debugar o sistema de managers:

```gdscript
# Verificar estado atual
print("Game State: ", GameStateManager.get_current_state())
print("Current Player: ", GameManager.get_current_player())
print("Active Effects: ", EffectsManager.get_active_effects_count())

# Logs automáticos
# Todos os managers já incluem logs detalhados de suas operações
```

## 📚 Ordem de Inicialização

Os managers são inicializados na seguinte ordem (definida no AutoLoad):

1. **GameStateManager** - Estados globais
2. **SceneManager** - Gerenciamento de cenas
3. **AudioManager** - Sistema de áudio
4. **UIManager** - Interface do usuário
5. **EffectsManager** - Efeitos visuais
6. **CatManager** - Jogadores
7. **CardManager** - Sistema de cartas
8. **CueManager** - Mecânica de tacada
9. **GameManager** - Lógica principal

Esta ordem garante que as dependências sejam resolvidas corretamente.

---

## 🛠️ Expansão do Sistema

Para adicionar novos managers:

1. Crie o script em `scripts/managers/`
2. Adicione no AutoLoad do `project.godot`
3. Implemente sinais para comunicação
4. Documente a API no README
5. Teste a integração com managers existentes

O sistema foi projetado para ser **modular** e **extensível**, permitindo fácil adição de novas funcionalidades sem quebrar o código existente. 