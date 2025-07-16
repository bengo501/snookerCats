extends Node

signal player_moved(new_position: Vector2)
signal player_action_performed(action: String)

# Referência para o jogador na cena
var player: CharacterBody2D = null
var player_sprite: Sprite2D = null

# Estado do jogador
var can_move := false
var can_aim := false
var movement_speed := 200.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[PlayerManager] PlayerManager inicializado")

func setup(player_ref: CharacterBody2D):
	player = player_ref
	if player:
		player_sprite = player.get_node("Sprite2D") if player.has_node("Sprite2D") else null
		print("[PlayerManager] ✓ Jogador referenciado em: ", player.global_position)
	else:
		print("[PlayerManager] ✗ Jogador não encontrado")

func _process(delta):
	if not player or not can_move:
		return
	
	_handle_movement(delta)

func _handle_movement(delta):
	var input_vector = Vector2.ZERO
	
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1
	
	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized()
		player.velocity = input_vector * movement_speed
		player.move_and_slide()
		
		# Emitir sinal de movimento
		player_moved.emit(player.global_position)
		print("[PlayerManager] Jogador movido para: ", player.global_position)
	else:
		player.velocity = Vector2.ZERO

func enable_movement():
	can_move = true
	print("[PlayerManager] ✓ Movimento habilitado")

func disable_movement():
	can_move = false
	player.velocity = Vector2.ZERO
	print("[PlayerManager] ✓ Movimento desabilitado")

func enable_aiming():
	can_aim = true
	print("[PlayerManager] ✓ Mira habilitada")

func disable_aiming():
	can_aim = false
	print("[PlayerManager] ✓ Mira desabilitada")

func get_player_position() -> Vector2:
	if player:
		return player.global_position
	return Vector2.ZERO

func set_player_position(position: Vector2):
	if player:
		player.global_position = position
		print("[PlayerManager] Jogador posicionado em: ", position)

func get_manager_type() -> String:
	return "PlayerManager" 