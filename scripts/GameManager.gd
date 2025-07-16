extends Node

signal game_started
signal game_ended
signal turn_changed(player_id: int)
signal score_updated(player_id: int, score: int)
signal ball_pocketed(ball_id: int, player_id: int)

enum TurnState {
	WAITING_FOR_INPUT,
	AIMING,
	SHOOTING,
	BALLS_MOVING,
	TURN_ENDING
}

var current_turn_state: TurnState = TurnState.WAITING_FOR_INPUT
var current_player_id: int = 1
var player_scores: Dictionary = {}
var balls_in_play: Array = []
var turn_count: int = 0
var game_active: bool = false

# Configurações do jogo
var max_players: int = 2
var winning_score: int = 100
var turn_time_limit: float = 60.0
var current_turn_time: float = 0.0

func _ready():
	print("GameManager initialized")
	_setup_game()
	_connect_manager_signals()

func _setup_game():
	# Inicializar pontuações dos jogadores
	for i in range(1, max_players + 1):
		player_scores[i] = 0
	
	# Configurar estado inicial
	current_turn_state = TurnState.WAITING_FOR_INPUT
	current_player_id = 1
	game_active = false

func _connect_manager_signals():
	# Conectar sinais dos outros managers
	if GameStateManager:
		GameStateManager.state_changed.connect(_on_game_state_changed)
	
	if CueManager:
		CueManager.shot_fired.connect(_on_shot_fired)
	
	if CardManager:
		CardManager.card_used.connect(_on_card_used)
	
	if CatManager:
		CatManager.cat_died.connect(_on_cat_died)

func start_game():
	print("Starting new game")
	game_active = true
	turn_count = 0
	current_turn_time = turn_time_limit
	
	# Resetar pontuações
	for player_id in player_scores.keys():
		player_scores[player_id] = 0
	
	# Criar gatos jogadores
	_setup_players()
	
	# Configurar mesa e bolas
	_setup_game_board()
	
	# Iniciar primeiro turno
	start_turn(1)
	
	game_started.emit()
	GameStateManager.set_current_state(GameStateManager.GameState.PLAYING)

func _setup_players():
	# Limpar gatos existentes
	CatManager.clear_all_cats()
	
	# Criar gatos para cada jogador
	for player_id in range(1, max_players + 1):
		var cat_position = _get_player_start_position(player_id)
		var is_player = (player_id == 1)  # Apenas jogador 1 é humano
		
		var cat = CatManager.create_cat(player_id, cat_position, is_player)
		if cat:
			# Dar cartas iniciais
			CardManager.draw_cards(player_id, 5)

func _setup_game_board():
	# Configurar bolas na mesa
	_setup_balls()
	
	# Configurar caçapas
	_setup_pockets()

func _setup_balls():
	balls_in_play.clear()
	
	# Posições das bolas em formação triangular
	var ball_positions = [
		Vector2(1200, 540),  # Bola 1
		Vector2(1230, 525),  # Bola 2
		Vector2(1230, 555),  # Bola 3
		Vector2(1260, 510),  # Bola 4
		Vector2(1260, 540),  # Bola 5
		Vector2(1260, 570),  # Bola 6
		Vector2(1290, 495),  # Bola 7
		Vector2(1290, 525),  # Bola 8
		Vector2(1290, 555),  # Bola 9
		Vector2(1290, 585),  # Bola 10
	]
	
	# Criar bolas coloridas
	for i in range(ball_positions.size()):
		var ball_scene = preload("res://scenes/ball/Ball.tscn").instantiate()
		get_tree().current_scene.get_node("Balls").add_child(ball_scene)
		
		ball_scene.global_position = ball_positions[i]
		ball_scene.set_ball_properties(_get_ball_color(i + 1), i + 1)
		ball_scene.add_to_group("balls")
		
		# Conectar sinais
		ball_scene.ball_pocketed.connect(_on_ball_pocketed.bind(i + 1))
		ball_scene.ball_stopped.connect(_on_ball_stopped)
		
		balls_in_play.append(ball_scene)

func _setup_pockets():
	# Adicionar caçapas nos cantos da mesa
	var pocket_positions = [
		Vector2(340, 220),   # Canto superior esquerdo
		Vector2(960, 220),   # Meio superior
		Vector2(1580, 220),  # Canto superior direito
		Vector2(340, 860),   # Canto inferior esquerdo
		Vector2(960, 860),   # Meio inferior
		Vector2(1580, 860)   # Canto inferior direito
	]
	
	for pos in pocket_positions:
		var pocket = preload("res://scenes/Pocket.tscn").instantiate()
		get_tree().current_scene.add_child(pocket)
		pocket.global_position = pos
		pocket.add_to_group("pockets")

func start_turn(player_id: int):
	current_player_id = player_id
	current_turn_state = TurnState.WAITING_FOR_INPUT
	current_turn_time = turn_time_limit
	turn_count += 1
	
	print("Starting turn for player: ", player_id)
	
	# Atualizar UI
	UIManager.update_turn_indicator(player_id)
	UIManager.update_cards_display(player_id, CardManager.get_hand(player_id))
	
	# Tocar som de mudança de turno
	AudioManager.play_turn_change_sound()
	
	# Se for IA, iniciar comportamento automático
	if not _is_human_player(player_id):
		_start_ai_turn()
	
	turn_changed.emit(player_id)

func _start_ai_turn():
	GameStateManager.set_current_state(GameStateManager.GameState.ENEMY_TURN)
	
	# Aguardar um pouco antes da IA agir
	await get_tree().create_timer(1.0).timeout
	
	# IA escolhe uma ação
	_ai_make_decision()

func _ai_make_decision():
	# Lógica simples da IA
	var available_cards = CardManager.get_hand(current_player_id)
	
	# 30% de chance de usar uma carta
	if available_cards.size() > 0 and randf() < 0.3:
		var random_card = available_cards[randi() % available_cards.size()]
		CardManager.use_card(random_card, current_player_id)
	
	# Fazer uma tacada aleatória
	await get_tree().create_timer(0.5).timeout
	_ai_make_shot()

func _ai_make_shot():
	var cue_ball = _get_cue_ball()
	if not cue_ball:
		return
	
	# Escolher alvo aleatório
	var target_balls = _get_target_balls()
	if target_balls.size() > 0:
		var target = target_balls[randi() % target_balls.size()]
		var aim_direction = (target.global_position - cue_ball.global_position).normalized()
		var shot_power = randf_range(300, 800)
		
		# Executar tacada
		CueManager.start_aiming(current_player_id, cue_ball.global_position)
		CueManager.update_aim(target.global_position)
		CueManager.start_charging()
		
		# Simular carregamento de força
		await get_tree().create_timer(randf_range(0.5, 1.5)).timeout
		CueManager.fire_shot()

func end_turn():
	current_turn_state = TurnState.TURN_ENDING
	
	# Verificar condições de vitória
	if _check_win_condition():
		end_game()
		return
	
	# Passar para próximo jogador
	var next_player = _get_next_player()
	start_turn(next_player)

func _process(delta):
	if not game_active:
		return
	
	# Atualizar timer do turno
	if current_turn_time > 0:
		current_turn_time -= delta
		if current_turn_time <= 0:
			_on_turn_timeout()
	
	# Verificar se todas as bolas pararam
	if current_turn_state == TurnState.BALLS_MOVING:
		if _all_balls_stopped():
			current_turn_state = TurnState.TURN_ENDING
			await get_tree().create_timer(0.5).timeout
			end_turn()

func _on_turn_timeout():
	print("Turn timeout for player: ", current_player_id)
	
	# Forçar fim do turno
	if current_turn_state == TurnState.AIMING or current_turn_state == TurnState.SHOOTING:
		end_turn()

func _on_shot_fired(player_id: int, force: Vector2, position: Vector2):
	current_turn_state = TurnState.BALLS_MOVING
	
	# Tocar som de tacada
	AudioManager.play_ball_hit_sound()
	
	# Verificar se pode dar outra tacada
	if CueManager.can_shoot_again(player_id):
		await get_tree().create_timer(2.0).timeout
		if _all_balls_stopped():
			current_turn_state = TurnState.WAITING_FOR_INPUT

func _on_card_used(card_name: String, player_id: int):
	print("Player ", player_id, " used card: ", card_name)
	
	# Atualizar display de cartas
	UIManager.update_cards_display(player_id, CardManager.get_hand(player_id))
	
	# Mostrar notificação
	var card_info = CardManager.get_card_info(card_name)
	UIManager.show_notification("Carta usada: " + card_info.name)

func _on_ball_pocketed(ball_id: int):
	print("Ball ", ball_id, " pocketed by player ", current_player_id)
	
	# Adicionar pontos
	var points = _get_ball_points(ball_id)
	add_score(current_player_id, points)
	
	# Tocar som
	AudioManager.play_ball_pocket_sound()
	
	# Efeito visual
	EffectsManager.create_magic_effect(Vector2.ZERO, Color.GOLD)
	
	ball_pocketed.emit(ball_id, current_player_id)

func _on_ball_stopped():
	# Verificar se todas as bolas pararam
	if current_turn_state == TurnState.BALLS_MOVING:
		if _all_balls_stopped():
			await get_tree().create_timer(0.5).timeout
			end_turn()

func _on_cat_died(cat_id: int):
	print("Cat ", cat_id, " died")
	
	# Verificar se o jogo deve terminar
	var alive_cats = CatManager.get_alive_cats()
	if alive_cats.size() <= 1:
		end_game()

func _on_game_state_changed(old_state, new_state):
	match new_state:
		GameStateManager.GameState.PLAYING:
			resume_game()
		GameStateManager.GameState.PAUSED:
			pause_game()
		GameStateManager.GameState.MENU:
			end_game()

func add_score(player_id: int, points: int):
	if player_scores.has(player_id):
		player_scores[player_id] += points
		
		# Atualizar UI
		UIManager.update_score(player_id, player_scores[player_id])
		
		# Verificar vitória
		if player_scores[player_id] >= winning_score:
			_declare_winner(player_id)
		
		score_updated.emit(player_id, player_scores[player_id])

func _declare_winner(player_id: int):
	print("Player ", player_id, " wins!")
	
	# Tocar música de vitória
	if player_id == 1:
		AudioManager.play_victory_music()
	else:
		AudioManager.play_defeat_music()
	
	# Mostrar tela de vitória
	UIManager.show_notification("Jogador " + str(player_id) + " venceu!")
	
	end_game()

func end_game():
	game_active = false
	current_turn_state = TurnState.WAITING_FOR_INPUT
	
	print("Game ended")
	
	# Parar todos os efeitos
	EffectsManager.stop_all_effects()
	
	# Limpar dados
	CatManager.clear_all_cats()
	
	game_ended.emit()
	GameStateManager.set_current_state(GameStateManager.GameState.GAME_OVER)

func pause_game():
	game_active = false
	AudioManager.pause_music()

func resume_game():
	game_active = true
	AudioManager.resume_music()

func restart_game():
	end_game()
	await get_tree().create_timer(0.5).timeout
	start_game()

# Métodos utilitários
func _get_cue_ball() -> RigidBody2D:
	var cue_balls = get_tree().get_nodes_in_group("cue_ball")
	if cue_balls.size() > 0:
		return cue_balls[0]
	return null

func _get_target_balls() -> Array:
	return get_tree().get_nodes_in_group("balls")

func _all_balls_stopped() -> bool:
	var balls = get_tree().get_nodes_in_group("balls")
	for ball in balls:
		if ball.linear_velocity.length() > 10.0:
			return false
	return true

func _is_human_player(player_id: int) -> bool:
	return player_id == 1

func _get_next_player() -> int:
	return (current_player_id % max_players) + 1

func _get_player_start_position(player_id: int) -> Vector2:
	match player_id:
		1:
			return Vector2(400, 540)
		2:
			return Vector2(1520, 540)
		_:
			return Vector2(960, 540)

func _get_ball_color(ball_number: int) -> Color:
	var colors = [
		Color.RED,     # 1
		Color.YELLOW,  # 2
		Color.GREEN,   # 3
		Color.BROWN,   # 4
		Color.BLUE,    # 5
		Color.MAGENTA, # 6
		Color.BLACK,   # 7
		Color.ORANGE,  # 8
		Color.PURPLE,  # 9
		Color.CYAN     # 10
	]
	
	if ball_number > 0 and ball_number <= colors.size():
		return colors[ball_number - 1]
	return Color.WHITE

func _get_ball_points(ball_number: int) -> int:
	match ball_number:
		1, 2, 3, 4, 5, 6, 7, 8, 9, 10:
			return ball_number
		_:
			return 1

func _check_win_condition() -> bool:
	# Verificar se algum jogador atingiu a pontuação máxima
	for player_id in player_scores.keys():
		if player_scores[player_id] >= winning_score:
			return true
	
	# Verificar se restam bolas na mesa
	var remaining_balls = get_tree().get_nodes_in_group("balls")
	if remaining_balls.size() <= 1:  # Apenas bola branca
		return true
	
	return false

# Getters
func get_current_player() -> int:
	return current_player_id

func get_player_score(player_id: int) -> int:
	return player_scores.get(player_id, 0)

func get_turn_count() -> int:
	return turn_count

func get_current_turn_time() -> float:
	return current_turn_time

func is_game_active() -> bool:
	return game_active

func get_turn_state() -> TurnState:
	return current_turn_state 