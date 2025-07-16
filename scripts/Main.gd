extends Node2D

@onready var cue_ball = $Balls/CueBall
@onready var power_bar = $UI/HUD/PowerBar

var cursor_position = Vector2.ZERO
var cursor_speed = 300.0

func _ready():
	cursor_position = cue_ball.global_position
	_setup_connections()
	
	# Inicializar jogo através do GameManager
	GameManager.start_game()

func _setup_connections():
	# Conectar sinais dos managers
	CueManager.shot_fired.connect(_on_shot_fired)
	CueManager.shot_prepared.connect(_on_shot_prepared)
	CardManager.card_used.connect(_on_card_used)
	GameManager.turn_changed.connect(_on_turn_changed)
	GameStateManager.state_changed.connect(_on_game_state_changed)
	
	# Configurar bola branca
	cue_ball.add_to_group("cue_ball")
	
func _process(delta):
	# Apenas processar input se estiver no estado correto
	if GameStateManager.is_in_state(GameStateManager.GameState.PLAYING):
		handle_input(delta)
		update_power_bar()
	
func handle_input(delta):
	# Verificar se é o turno do jogador humano
	if GameManager.get_current_player() != 1:
		return
	
	# Movimento do cursor com WASD
	var input_vector = Vector2.ZERO
	
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1
	
	# Atualizar posição do cursor
	cursor_position += input_vector * cursor_speed * delta
	
	# Atualizar mira no CueManager
	CueManager.update_aim(cursor_position)
	
	# Controle de força
	if Input.is_action_just_pressed("action"):
		if not CueManager.is_player_aiming():
			CueManager.start_aiming(1, cue_ball.global_position)
		
		if not CueManager.is_player_charging():
			CueManager.start_charging()
	
	if Input.is_action_just_released("action"):
		if CueManager.is_player_charging():
			CueManager.fire_shot()
	
	# Atualizar força durante carregamento
	if CueManager.is_player_charging():
		CueManager.update_charge(delta)
	
	# Controle com mouse
	if Input.is_action_just_pressed("action") and not CueManager.is_player_aiming():
		cursor_position = get_global_mouse_position()
		CueManager.update_aim(cursor_position)

func update_power_bar():
	var power = CueManager.get_shot_power()
	var max_power = CueManager.get_max_shot_power()
	
	if power > 0:
		UIManager.update_power_bar(power, max_power)
	else:
		UIManager.update_power_bar(0, max_power)

func _draw():
	# Desenhar linha de mira se estiver mirando
	if CueManager.is_player_aiming():
		var aim_dir = CueManager.get_aim_direction()
		if aim_dir != Vector2.ZERO:
			var start_pos = cue_ball.global_position
			var end_pos = start_pos + aim_dir * 100
			
			# Cor da linha baseada na precisão
			var line_color = Color.RED
			if CueManager.has_precision_aim(1):
				line_color = Color.CYAN
			
			draw_line(start_pos, end_pos, line_color, 3.0)
	
	# Desenhar cursor
	var cursor_color = Color.CYAN
	if CueManager.is_player_charging():
		cursor_color = Color.YELLOW
	
	draw_circle(cursor_position, 8, cursor_color)

func _input(event):
	# Processar input apenas se for o turno do jogador
	if GameManager.get_current_player() != 1:
		return
	
	if event is InputEventMouseMotion:
		cursor_position = get_global_mouse_position()
		CueManager.update_aim(cursor_position)
		queue_redraw()
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			cursor_position = get_global_mouse_position()
			CueManager.update_aim(cursor_position)
			queue_redraw()
	
	# Teclas para usar cartas (1-5)
	if event is InputEventKey and event.pressed:
		var card_keys = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5]
		for i in range(card_keys.size()):
			if event.keycode == card_keys[i]:
				_use_card_at_index(i)
				break

func _use_card_at_index(index: int):
	var player_hand = CardManager.get_hand(1)
	if index < player_hand.size():
		var card_name = player_hand[index]
		if CardManager.can_use_card(card_name, 1):
			CardManager.use_card(card_name, 1)

# Callbacks dos sinais dos managers
func _on_shot_fired(player_id: int, force: Vector2, position: Vector2):
	print("Shot fired by player ", player_id, " with force ", force.length())
	queue_redraw()

func _on_shot_prepared(player_id: int, aim_direction: Vector2):
	queue_redraw()

func _on_card_used(card_name: String, player_id: int):
	print("Card used: ", card_name, " by player ", player_id)
	
	# Mostrar feedback visual
	var card_info = CardManager.get_card_info(card_name)
	UIManager.show_notification("Carta usada: " + card_info.name)

func _on_turn_changed(player_id: int):
	print("Turn changed to player: ", player_id)
	
	# Atualizar UI
	UIManager.update_turn_indicator(player_id)
	
	# Limpar estado de mira
	CueManager.cancel_shot()
	queue_redraw()

func _on_game_state_changed(old_state, new_state):
	match new_state:
		GameStateManager.GameState.PLAYING:
			# Jogo iniciado/retomado
			queue_redraw()
		GameStateManager.GameState.PAUSED:
			# Jogo pausado
			CueManager.cancel_shot()
		GameStateManager.GameState.GAME_OVER:
			# Jogo terminou
			CueManager.cancel_shot()
			queue_redraw()

# Métodos de conveniência para debug
func _on_debug_key_pressed():
	if Input.is_action_just_pressed("ui_accept"):
		print("=== DEBUG INFO ===")
		print("Game State: ", GameStateManager.get_current_state())
		print("Current Player: ", GameManager.get_current_player())
		print("Player Score: ", GameManager.get_player_score(1))
		print("Turn Time: ", GameManager.get_current_turn_time())
		print("Active Effects: ", CueManager.get_active_effects(1))
		print("Cards in Hand: ", CardManager.get_hand(1))
		print("================")

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Limpar managers antes de fechar
		EffectsManager.stop_all_effects()
		AudioManager.stop_all_sounds()
		get_tree().quit() 