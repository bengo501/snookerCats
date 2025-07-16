extends Node

signal card_used(card_name: String, player_id: int)
signal card_drawn(card_name: String, player_id: int)
signal deck_shuffled
signal hand_updated(player_id: int, cards: Array)

class_name CardData
extends Resource

@export var card_name: String
@export var description: String
@export var mana_cost: int = 1
@export var rarity: String = "common" # common, rare, epic, legendary
@export var effect_type: String = "instant" # instant, passive, toggle
@export var icon: Texture2D
@export var sound_effect: AudioStream
@export var cooldown: float = 0.0

var available_cards: Dictionary = {}
var player_decks: Dictionary = {}
var player_hands: Dictionary = {}
var discard_piles: Dictionary = {}
var card_cooldowns: Dictionary = {}

func _ready():
	print("CardManager initialized")
	_load_card_data()
	_initialize_decks()

func _load_card_data():
	# Definir cartas disponíveis no jogo
	var cards_data = {
		"double_shot": {
			"name": "Tiro Duplo",
			"description": "Permite dar duas tacadas consecutivas",
			"mana_cost": 2,
			"rarity": "common",
			"effect_type": "instant",
			"cooldown": 0.0
		},
		"explosive_ball": {
			"name": "Bola Explosiva",
			"description": "A próxima bola que você acertar explode, empurrando outras bolas",
			"mana_cost": 3,
			"rarity": "rare",
			"effect_type": "instant",
			"cooldown": 5.0
		},
		"ghost_ball": {
			"name": "Bola Fantasma",
			"description": "A bola branca atravessa uma parede na próxima tacada",
			"mana_cost": 2,
			"rarity": "rare",
			"effect_type": "instant",
			"cooldown": 3.0
		},
		"precision_aim": {
			"name": "Mira Precisa",
			"description": "Mostra a trajetória exata da bola por 10 segundos",
			"mana_cost": 1,
			"rarity": "common",
			"effect_type": "toggle",
			"cooldown": 0.0
		},
		"teleport_ball": {
			"name": "Teletransporte",
			"description": "Teleporta a bola branca para qualquer posição na mesa",
			"mana_cost": 4,
			"rarity": "epic",
			"effect_type": "instant",
			"cooldown": 8.0
		},
		"freeze_time": {
			"name": "Congelar Tempo",
			"description": "Congela todas as bolas por 5 segundos",
			"mana_cost": 5,
			"rarity": "legendary",
			"effect_type": "instant",
			"cooldown": 15.0
		},
		"magnetic_ball": {
			"name": "Bola Magnética",
			"description": "Atrai bolas próximas por 3 tacadas",
			"mana_cost": 3,
			"rarity": "rare",
			"effect_type": "passive",
			"cooldown": 6.0
		},
		"speed_boost": {
			"name": "Velocidade Extra",
			"description": "Aumenta a velocidade da bola em 50% por 3 tacadas",
			"mana_cost": 2,
			"rarity": "common",
			"effect_type": "passive",
			"cooldown": 4.0
		}
	}
	
	for card_id in cards_data.keys():
		var card_info = cards_data[card_id]
		available_cards[card_id] = card_info
		print("Loaded card: ", card_info.name)

func _initialize_decks():
	# Inicializar decks para jogadores
	for player_id in range(1, 5):  # Suporte para até 4 jogadores
		player_decks[player_id] = _create_default_deck()
		player_hands[player_id] = []
		discard_piles[player_id] = []
		card_cooldowns[player_id] = {}

func _create_default_deck() -> Array:
	var deck = []
	
	# Adicionar cartas comuns (maior quantidade)
	for i in range(3):
		deck.append("double_shot")
		deck.append("precision_aim")
		deck.append("speed_boost")
	
	# Adicionar cartas raras
	for i in range(2):
		deck.append("explosive_ball")
		deck.append("ghost_ball")
		deck.append("magnetic_ball")
	
	# Adicionar cartas épicas
	deck.append("teleport_ball")
	
	# Adicionar cartas lendárias
	deck.append("freeze_time")
	
	deck.shuffle()
	return deck

func shuffle_deck(player_id: int):
	if player_decks.has(player_id):
		player_decks[player_id].shuffle()
		deck_shuffled.emit()
		print("Deck shuffled for player: ", player_id)

func draw_card(player_id: int) -> String:
	if not player_decks.has(player_id) or player_decks[player_id].is_empty():
		_reshuffle_discard_pile(player_id)
	
	if not player_decks[player_id].is_empty():
		var card = player_decks[player_id].pop_front()
		player_hands[player_id].append(card)
		card_drawn.emit(card, player_id)
		hand_updated.emit(player_id, player_hands[player_id])
		print("Player ", player_id, " drew card: ", available_cards[card].name)
		return card
	
	return ""

func draw_cards(player_id: int, amount: int):
	for i in range(amount):
		draw_card(player_id)

func use_card(card_name: String, player_id: int) -> bool:
	if not can_use_card(card_name, player_id):
		return false
	
	var card_index = player_hands[player_id].find(card_name)
	if card_index == -1:
		print("Card not found in hand: ", card_name)
		return false
	
	# Remover carta da mão
	player_hands[player_id].remove_at(card_index)
	discard_piles[player_id].append(card_name)
	
	# Aplicar efeito da carta
	_apply_card_effect(card_name, player_id)
	
	# Iniciar cooldown se necessário
	var card_data = available_cards[card_name]
	if card_data.cooldown > 0:
		card_cooldowns[player_id][card_name] = card_data.cooldown
	
	card_used.emit(card_name, player_id)
	hand_updated.emit(player_id, player_hands[player_id])
	
	print("Player ", player_id, " used card: ", card_data.name)
	return true

func can_use_card(card_name: String, player_id: int) -> bool:
	# Verificar se a carta está na mão
	if not player_hands[player_id].has(card_name):
		return false
	
	# Verificar cooldown
	if card_cooldowns[player_id].has(card_name):
		if card_cooldowns[player_id][card_name] > 0:
			return false
	
	# Verificar se é o turno do jogador
	if not GameStateManager.is_game_active():
		return false
	
	return true

func _apply_card_effect(card_name: String, player_id: int):
	match card_name:
		"double_shot":
			CueManager.enable_double_shot(player_id)
		"explosive_ball":
			CueManager.enable_explosive_ball(player_id)
		"ghost_ball":
			CueManager.enable_ghost_ball(player_id)
		"precision_aim":
			CueManager.enable_precision_aim(player_id, 10.0)
		"teleport_ball":
			CueManager.enable_teleport_mode(player_id)
		"freeze_time":
			_freeze_all_balls(5.0)
		"magnetic_ball":
			CueManager.enable_magnetic_ball(player_id, 3)
		"speed_boost":
			CueManager.enable_speed_boost(player_id, 1.5, 3)
	
	# Reproduzir efeito visual
	EffectsManager.play_card_effect(card_name, player_id)
	
	# Reproduzir som
	AudioManager.play_card_sound(card_name)

func _freeze_all_balls(duration: float):
	var balls = get_tree().get_nodes_in_group("balls")
	for ball in balls:
		ball.freeze(duration)

func _reshuffle_discard_pile(player_id: int):
	if discard_piles[player_id].size() > 0:
		player_decks[player_id] = discard_piles[player_id].duplicate()
		discard_piles[player_id].clear()
		shuffle_deck(player_id)
		print("Reshuffled discard pile for player: ", player_id)

func get_hand(player_id: int) -> Array:
	return player_hands.get(player_id, [])

func get_hand_size(player_id: int) -> int:
	return player_hands.get(player_id, []).size()

func get_deck_size(player_id: int) -> int:
	return player_decks.get(player_id, []).size()

func get_card_info(card_name: String) -> Dictionary:
	return available_cards.get(card_name, {})

func add_card_to_hand(card_name: String, player_id: int):
	if available_cards.has(card_name):
		player_hands[player_id].append(card_name)
		hand_updated.emit(player_id, player_hands[player_id])
		print("Added card to hand: ", card_name)

func remove_card_from_hand(card_name: String, player_id: int):
	var index = player_hands[player_id].find(card_name)
	if index != -1:
		player_hands[player_id].remove_at(index)
		hand_updated.emit(player_id, player_hands[player_id])
		print("Removed card from hand: ", card_name)

func get_available_cards() -> Dictionary:
	return available_cards

func show_available_cards():
	UIManager.show_cards_ui(available_cards)

func _process(delta):
	# Atualizar cooldowns
	for player_id in card_cooldowns.keys():
		for card_name in card_cooldowns[player_id].keys():
			if card_cooldowns[player_id][card_name] > 0:
				card_cooldowns[player_id][card_name] -= delta
				if card_cooldowns[player_id][card_name] <= 0:
					card_cooldowns[player_id].erase(card_name)
					print("Card cooldown finished: ", card_name)

func get_card_cooldown(card_name: String, player_id: int) -> float:
	if card_cooldowns[player_id].has(card_name):
		return card_cooldowns[player_id][card_name]
	return 0.0

func is_card_on_cooldown(card_name: String, player_id: int) -> bool:
	return get_card_cooldown(card_name, player_id) > 0

func reset_player_data(player_id: int):
	player_decks[player_id] = _create_default_deck()
	player_hands[player_id].clear()
	discard_piles[player_id].clear()
	card_cooldowns[player_id].clear()
	print("Reset card data for player: ", player_id) 