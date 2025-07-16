extends Node

signal game_state_changed(new_state: GameState)
signal turn_changed(player: int)
signal score_updated(player: int, new_score: int)
signal game_over(winner: int)
signal ball_pocketed(ball_number: int)

enum GameState {
	MENU,
	PLAYER_TURN,
	ENEMY_TURN,
	PLAYING,
	PAUSED,
	AIMING,
	SHOOTING,
	BALLS_MOVING,
	TURN_END,
	GAME_OVER
}

var current_state: GameState = GameState.PLAYER_TURN  # Começar no turno do jogador
var current_player: int = 1
var player_scores: Array[int] = [0, 0]
var balls_in_play: Array = []
var turn_count: int = 0
var max_turns: int = 50  # Limite de turnos para evitar loop infinito

# Referências para outros managers
var scene_manager: Node
var cat_manager: Node
var card_manager: Node
var cue_manager: Node
var ui_manager: Node
var audio_manager: Node
var player_manager: Node  # Novo manager para o jogador

func _ready():
	print("[GameManager] GameManager inicializado")
	# Configurar como singleton
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Aguardar um frame para garantir que a árvore de cena esteja pronta
	await get_tree().process_frame
	
	# Buscar referências dos outros managers
	_find_managers()
	
	# Mostrar estado inicial
	print("[GameManager] Estado inicial: ", GameState.keys()[current_state])

func _find_managers():
	print("[GameManager] Buscando managers...")
	# Buscar managers na árvore de cena
	var managers = get_tree().get_nodes_in_group("managers")
	for manager in managers:
		if manager.has_method("get_manager_type"):
			var manager_type = manager.get_manager_type()
			print("[GameManager] Manager encontrado: ", manager_type)
			match manager_type:
				"SceneManager":
					scene_manager = manager
				"CatManager":
					cat_manager = manager
				"CardManager":
					card_manager = manager
				"CueManager":
					cue_manager = manager
				"UIManager":
					ui_manager = manager
				"AudioManager":
					audio_manager = manager
				"PlayerManager":
					player_manager = manager
	
	print("[GameManager] Total de managers encontrados: ", managers.size())
	print("[GameManager] CueManager referenciado: ", cue_manager != null)
	print("[GameManager] PlayerManager referenciado: ", player_manager != null)

func start_new_game():
	print("Iniciando novo jogo...")
	current_state = GameState.PLAYING
	current_player = 1
	player_scores = [0, 0]
	turn_count = 0
	balls_in_play.clear()
	
	# Notificar outros managers
	if scene_manager:
		scene_manager.change_scene(scene_manager.SceneType.GAME)
	
	change_state(GameState.AIMING)
	game_state_changed.emit(current_state)

func change_state(new_state: GameState):
	var old_state = current_state
	current_state = new_state
	
	print("[GameManager] Estado do jogo mudou: ", GameState.keys()[old_state], " -> ", GameState.keys()[new_state])
	game_state_changed.emit(current_state)
	
	# Notificar outros managers sobre a mudança de estado
	_notify_managers_of_state_change()
	
	match current_state:
		GameState.PLAYER_TURN:
			_start_player_turn()
		GameState.ENEMY_TURN:
			_start_enemy_turn()
		GameState.AIMING:
			_enable_aiming()
		GameState.SHOOTING:
			_disable_aiming()
		GameState.BALLS_MOVING:
			_wait_for_balls_to_stop()
		GameState.TURN_END:
			_end_turn()
		GameState.GAME_OVER:
			_end_game()

func _notify_managers_of_state_change():
	# Notificar managers específicos sobre mudanças de estado
	if ui_manager and ui_manager.has_method("on_game_state_changed"):
		ui_manager.on_game_state_changed(current_state)
	
	if cue_manager and cue_manager.has_method("on_game_state_changed"):
		cue_manager.on_game_state_changed(current_state)

func _enable_aiming():
	print("[GameManager] Habilitando sistema de mira para jogador: ", current_player)
	# Permitir que o jogador mire
	if cue_manager:
		print("[GameManager] ✓ CueManager encontrado para habilitar mira")
		cue_manager.enable_aiming()
	else:
		print("[GameManager] ✗ CueManager não encontrado para habilitar mira")

func _disable_aiming():
	print("[GameManager] Desabilitando sistema de mira")
	# Desabilitar controles de mira
	if cue_manager:
		print("[GameManager] ✓ CueManager encontrado para desabilitar mira")
		cue_manager.disable_aiming()
	else:
		print("[GameManager] ✗ CueManager não encontrado para desabilitar mira")

func _wait_for_balls_to_stop():
	print("Aguardando bolas pararem...")
	# Aguardar todas as bolas pararem
	await get_tree().create_timer(1.0).timeout
	change_state(GameState.TURN_END)

func _end_turn():
	print("Finalizando turno do jogador: ", current_player)
	
	# Mudar para o próximo jogador
	current_player = 2 if current_player == 1 else 1
	turn_count += 1
	
	# Verificar limite de turnos
	if turn_count >= max_turns:
		print("Limite de turnos atingido!")
		change_state(GameState.GAME_OVER)
		return
	
	turn_changed.emit(current_player)
	print("Turno mudou para jogador: ", current_player)
	
	# Verificar se o jogo deve continuar
	_check_game_conditions()
	
	if current_state != GameState.GAME_OVER:
		change_state(GameState.AIMING)

func _end_game():
	print("Jogo finalizado!")
	var winner = 1 if player_scores[0] > player_scores[1] else 2
	if player_scores[0] == player_scores[1]:
		winner = 0  # Empate
	
	game_over.emit(winner)
	print("Vencedor: ", winner, " | Placar final - Jogador 1: ", player_scores[0], " Jogador 2: ", player_scores[1])

func add_score(player: int, points: int):
	if player >= 1 and player <= 2:
		player_scores[player - 1] += points
		score_updated.emit(player, player_scores[player - 1])
		print("Jogador ", player, " marcou ", points, " pontos. Total: ", player_scores[player - 1])

func on_ball_pocketed(ball_number: int):
	print("Bola ", ball_number, " encaçapada!")
	ball_pocketed.emit(ball_number)
	
	# Adicionar pontos baseado na bola encaçapada
	var points = _get_ball_points(ball_number)
	add_score(current_player, points)
	
	# Verificar se a bola branca foi encaçapada (falta)
	if ball_number == 0:
		print("FALTA! Bola branca encaçapada!")
		add_score(current_player, -4)  # Penalidade

func _get_ball_points(ball_number: int) -> int:
	# Sistema de pontuação básico
	match ball_number:
		0: # Bola branca (falta)
			return -4
		1: # Bola vermelha
			return 1
		2: # Bola amarela
			return 2
		3: # Bola verde
			return 3
		4: # Bola marrom
			return 4
		5: # Bola azul
			return 5
		6: # Bola rosa
			return 6
		7: # Bola preta
			return 7
		_:
			return 1

func _check_game_conditions():
	# Verificar condições de fim de jogo
	if balls_in_play.size() <= 1:  # Apenas bola branca restante
		print("Apenas bola branca restante - Fim de jogo!")
		change_state(GameState.GAME_OVER)

func pause_game():
	if current_state == GameState.PLAYING or current_state == GameState.AIMING:
		change_state(GameState.PAUSED)
		print("Jogo pausado")

func resume_game():
	if current_state == GameState.PAUSED:
		change_state(GameState.AIMING)
		print("Jogo resumido")

func reset_game():
	print("Resetando jogo...")
	current_state = GameState.MENU
	current_player = 1
	player_scores = [0, 0]
	turn_count = 0
	balls_in_play.clear()

# Getters para outros managers
func get_current_state() -> GameState:
	return current_state

func get_current_player() -> int:
	return current_player

func get_player_score(player: int) -> int:
	if player >= 1 and player <= 2:
		return player_scores[player - 1]
	return 0

func get_turn_count() -> int:
	return turn_count

func get_manager_type() -> String:
	return "GameManager" 

func _start_player_turn():
	print("[GameManager] Iniciando turno do jogador")
	# Habilitar movimento do jogador
	if player_manager:
		player_manager.enable_movement()
		print("[GameManager] ✓ Movimento do jogador habilitado")
	else:
		print("[GameManager] ✗ PlayerManager não encontrado")
	
	# Habilitar sistema de tacada
	if cue_manager:
		cue_manager.enable_aiming()
		print("[GameManager] ✓ Sistema de tacada habilitado")
	else:
		print("[GameManager] ✗ CueManager não encontrado")

func _start_enemy_turn():
	print("[GameManager] Iniciando turno do inimigo")
	# Por enquanto, apenas voltar para o turno do jogador
	# (implementação do inimigo será feita depois)
	await get_tree().create_timer(1.0).timeout
	change_state(GameState.PLAYER_TURN) 
