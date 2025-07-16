extends Node

# Sinais para UI ou outros managers
signal aiming_started
signal aiming_ended
signal shot_fired(force: Vector2)

# Referências
var cue_ball: RigidBody2D = null
var power_bar: ProgressBar = null

# Estado da tacada
var is_aiming := false
var aim_direction := Vector2.ZERO
var power := 0.0
var max_power := 1000.0
var cursor_position := Vector2.ZERO
var cursor_speed := 300.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[CueManager] CueManager inicializado")
	print("[CueManager] Process mode: ", process_mode)

func setup(cue_ball_ref: RigidBody2D, power_bar_ref: ProgressBar):
	print("[CueManager] Setup chamado")
	cue_ball = cue_ball_ref
	power_bar = power_bar_ref
	if cue_ball:
		cursor_position = cue_ball.global_position
		print("[CueManager] ✓ Bola referenciada em: ", cursor_position)
	else:
		print("[CueManager] ✗ Bola não encontrada")
	if power_bar:
		print("[CueManager] ✓ PowerBar referenciada")
	else:
		print("[CueManager] ✗ PowerBar não encontrada")

func _process(delta):
	if not cue_ball:
		print("[CueManager] _process: Bola não encontrada")
		return
	
	# Verificar estado do GameManager
	if GameManager:
		var current_state = GameManager.get_current_state()
		var state_name = GameManager.GameState.keys()[current_state]
		print("[CueManager] Estado atual do jogo: ", state_name)
		
		# Processar input apenas no turno do jogador ou quando estiver mirando
		if current_state == GameManager.GameState.PLAYER_TURN or current_state == GameManager.GameState.AIMING:
			_handle_input(delta)
			_update_power_bar()
		else:
			print("[CueManager] Não está no turno do jogador, estado atual: ", state_name)
	else:
		print("[CueManager] ✗ GameManager não encontrado")

func _handle_input(delta):
	print("[CueManager] _handle_input chamado - delta: ", delta)
	var input_vector = Vector2.ZERO
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
		print("[CueManager] Tecla esquerda pressionada")
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
		print("[CueManager] Tecla direita pressionada")
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1
		print("[CueManager] Tecla cima pressionada")
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1
		print("[CueManager] Tecla baixo pressionada")
	cursor_position += input_vector * cursor_speed * delta

	# Mouse mira
	if Input.is_action_just_pressed("action") and not is_aiming:
		cursor_position = get_viewport().get_mouse_position()
		print("[CueManager] Botão de ação pressionado, cursor movido para: ", cursor_position)

	# Calcular direção da mira
	aim_direction = (cursor_position - cue_ball.global_position).normalized()
	print("[CueManager] Direção da mira: ", aim_direction)

	# Carregar força
	if Input.is_action_pressed("action"):
		if not is_aiming:
			is_aiming = true
			power = 0.0
			emit_signal("aiming_started")
			print("[CueManager] ✓ Iniciando mira")
		else:
			power = min(power + max_power * delta, max_power)
			print("[CueManager] Força atual: ", power)
	if Input.is_action_just_released("action"):
		if is_aiming:
			_shoot_ball()
			is_aiming = false
			power = 0.0
			emit_signal("aiming_ended")
			print("[CueManager] ✓ Mira finalizada")

func _shoot_ball():
	print("[CueManager] _shoot_ball chamado, força:", power, " direção:", aim_direction)
	if cue_ball and aim_direction != Vector2.ZERO:
		var final_power = power
		if CatManager:
			var player = CatManager.get_current_player()
			if player:
				final_power *= player.power_control
				print("[CueManager] Modificador do jogador: ", player.power_control)
		var force = aim_direction * final_power
		print("[CueManager] Aplicando força: ", force)
		cue_ball.apply_central_impulse(force)
		emit_signal("shot_fired", force)
		
		# Mudar para estado SHOOTING e depois para ENEMY_TURN
		if GameManager:
			GameManager.change_state(GameManager.GameState.SHOOTING)
			# Aguardar um pouco e mudar para o turno do inimigo
			await get_tree().create_timer(0.5).timeout
			GameManager.change_state(GameManager.GameState.ENEMY_TURN)
		
		print("[CueManager] ✓ Tacada disparada com força: ", final_power)
	else:
		print("[CueManager] ✗ Não foi possível disparar - bola: ", cue_ball, " direção: ", aim_direction)

func _update_power_bar():
	if power_bar:
		if is_aiming:
			power_bar.value = (power / max_power) * 100
			print("[CueManager] PowerBar atualizada: ", power_bar.value, "%")
		else:
			power_bar.value = 0
	else:
		print("[CueManager] ✗ PowerBar não encontrada para atualizar")

# Métodos utilitários para UI
func get_cursor_position() -> Vector2:
	return cursor_position
func get_aim_direction() -> Vector2:
	return aim_direction
func get_power() -> float:
	return power
func is_aiming_now() -> bool:
	return is_aiming 

func enable_aiming():
	print("[CueManager] ✓ Sistema de mira habilitado")
	# Resetar estado de mira
	is_aiming = false
	power = 0.0

func disable_aiming():
	print("[CueManager] ✓ Sistema de mira desabilitado")
	is_aiming = false
	power = 0.0 
