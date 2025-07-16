extends Node

signal game_over
signal turn_changed
signal score_updated

enum GameState {
	AIMING,
	SHOOTING,
	BALLS_MOVING,
	TURN_END
}

var current_state = GameState.AIMING
var current_player = 1
var player_scores = [0, 0]
var balls_in_play = []
var turn_count = 0

func _ready():
	print("Game Manager initialized")

func change_state(new_state: GameState):
	current_state = new_state
	print("Game state changed to: ", GameState.keys()[new_state])
	
	match new_state:
		GameState.AIMING:
			enable_aiming()
		GameState.SHOOTING:
			disable_aiming()
		GameState.BALLS_MOVING:
			wait_for_balls_to_stop()
		GameState.TURN_END:
			end_turn()

func enable_aiming():
	# Permitir que o jogador mire
	pass

func disable_aiming():
	# Desabilitar controles de mira
	pass

func wait_for_balls_to_stop():
	# Aguardar todas as bolas pararem
	await get_tree().create_timer(0.5).timeout
	change_state(GameState.TURN_END)

func end_turn():
	# Mudar para o próximo jogador
	current_player = 2 if current_player == 1 else 1
	turn_count += 1
	turn_changed.emit()
	print("Turn changed to player: ", current_player)
	change_state(GameState.AIMING)

func add_score(player: int, points: int):
	if player >= 1 and player <= 2:
		player_scores[player - 1] += points
		score_updated.emit()
		print("Player ", player, " scored ", points, " points. Total: ", player_scores[player - 1])

func get_player_score(player: int) -> int:
	if player >= 1 and player <= 2:
		return player_scores[player - 1]
	return 0

func ball_pocketed(ball_number: int):
	print("Ball ", ball_number, " pocketed!")
	# Adicionar pontos baseado na bola encaçapada
	add_score(current_player, get_ball_points(ball_number))

func get_ball_points(ball_number: int) -> int:
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

func check_game_over():
	# Verificar condições de fim de jogo
	if balls_in_play.size() <= 1:  # Apenas bola branca restante
		game_over.emit()
		print("Game Over! Final scores - Player 1: ", player_scores[0], " Player 2: ", player_scores[1])

func reset_game():
	current_state = GameState.AIMING
	current_player = 1
	player_scores = [0, 0]
	turn_count = 0
	balls_in_play.clear()
	print("Game reset")

func get_current_player() -> int:
	return current_player

func get_current_state() -> GameState:
	return current_state 