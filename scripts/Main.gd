extends Node2D

@onready var cue_ball = $Balls/CueBall
@onready var power_bar = $UI/HUD/PowerBar
@onready var player = $Player

func _ready():
	print("[Main] Main scene inicializando...")
	await get_tree().process_frame
	
	# Verificar cena atual
	if SceneManager:
		print("[Main] Cena atual: ", SceneManager.get_current_scene_name())
	else:
		print("[Main] ✗ SceneManager não encontrado")
	
	# Verificar bola
	if cue_ball:
		print("[Main] ✓ Bola encontrada em: ", cue_ball.global_position)
		print("[Main] Bola tem script: ", cue_ball.get_script() != null)
	else:
		print("[Main] ✗ Bola não encontrada")
	
	# Verificar power bar
	if power_bar:
		print("[Main] ✓ PowerBar encontrada")
	else:
		print("[Main] ✗ PowerBar não encontrada")
	
	# Verificar jogador
	if player:
		print("[Main] ✓ Jogador encontrado em: ", player.global_position)
	else:
		print("[Main] ✗ Jogador não encontrado")
	
	# Configurar CueManager
	if CueManager:
		CueManager.setup(cue_ball, power_bar)
		print("[Main] ✓ CueManager configurado")
	else:
		print("[Main] ✗ CueManager não encontrado")
	
	# Configurar PlayerManager
	if PlayerManager:
		PlayerManager.setup(player)
		print("[Main] ✓ PlayerManager configurado")
	else:
		print("[Main] ✗ PlayerManager não encontrado")
	
	# Verificar estado do jogo
	if GameManager:
		var current_state = GameManager.get_current_state()
		var state_name = GameManager.GameState.keys()[current_state]
		print("[Main] Estado inicial do jogo: ", state_name)
	else:
		print("[Main] ✗ GameManager não encontrado")

func _process(delta):
	queue_redraw()

func _draw():
	if CueManager and cue_ball:
		var is_aiming = CueManager.is_aiming_now()
		var aim_direction = CueManager.get_aim_direction()
		var cursor_position = CueManager.get_cursor_position()
		
		print("[Main] Desenhando - Mira: ", is_aiming, " Direção: ", aim_direction, " Cursor: ", cursor_position)
		
		if is_aiming and aim_direction != Vector2.ZERO:
			# Desenhar linha de mira
			var start_pos = cue_ball.global_position
			var end_pos = start_pos + aim_direction * 100
			draw_line(start_pos, end_pos, Color.RED, 3.0)
			# Desenhar cursor
			draw_circle(cursor_position, 10, Color.YELLOW)
			print("[Main] ✓ Linha de mira desenhada")
		else:
			# Desenhar apenas o cursor
			draw_circle(cursor_position, 8, Color.CYAN)
			print("[Main] ✓ Cursor desenhado")
	else:
		print("[Main] ✗ Não foi possível desenhar - CueManager: ", CueManager, " Bola: ", cue_ball) 
