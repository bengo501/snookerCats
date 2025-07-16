extends Node2D

@onready var cue_ball = $Balls/CueBall
@onready var power_bar = $UI/HUD/PowerBar

var is_aiming = false
var aim_direction = Vector2.ZERO
var power = 0.0
var max_power = 1000.0
var cursor_position = Vector2.ZERO
var cursor_speed = 300.0

func _ready():
	cursor_position = cue_ball.global_position
	
func _process(delta):
	handle_input(delta)
	update_power_bar()
	
func handle_input(delta):
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
	
	# Calcular direção da mira
	aim_direction = (cursor_position - cue_ball.global_position).normalized()
	
	# Controle de força
	if Input.is_action_pressed("action"):
		if not is_aiming:
			is_aiming = true
			power = 0.0
		else:
			power = min(power + max_power * delta, max_power)
	
	if Input.is_action_just_released("action"):
		if is_aiming:
			shoot_ball()
			is_aiming = false
			power = 0.0
	
	# Controle com mouse
	if Input.is_action_just_pressed("action") and not is_aiming:
		cursor_position = get_global_mouse_position()
		aim_direction = (cursor_position - cue_ball.global_position).normalized()
	
func shoot_ball():
	if cue_ball and aim_direction != Vector2.ZERO:
		var force = aim_direction * power
		cue_ball.apply_central_impulse(force)
		print("Bola disparada com força: ", power)

func update_power_bar():
	if is_aiming:
		power_bar.value = (power / max_power) * 100
	else:
		power_bar.value = 0

func _draw():
	if is_aiming and aim_direction != Vector2.ZERO:
		# Desenhar linha de mira
		var start_pos = cue_ball.global_position
		var end_pos = start_pos + aim_direction * 100
		draw_line(start_pos, end_pos, Color.RED, 3.0)
		
		# Desenhar cursor
		draw_circle(cursor_position, 10, Color.YELLOW)
	else:
		# Desenhar apenas o cursor
		draw_circle(cursor_position, 8, Color.CYAN)

func _input(event):
	if event is InputEventMouseMotion:
		cursor_position = get_global_mouse_position()
		queue_redraw()
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			cursor_position = get_global_mouse_position()
			aim_direction = (cursor_position - cue_ball.global_position).normalized()
			queue_redraw()

func _on_ball_stopped():
	# Função chamada quando a bola para de se mover
	print("Bola parou de se mover")
	queue_redraw() 