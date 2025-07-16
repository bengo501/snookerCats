extends RigidBody2D

signal ball_stopped
signal ball_pocketed

var is_moving = false
var velocity_threshold = 10.0
var ball_color = Color.WHITE
var ball_number = 0

func _ready():
	print("Bola inicializada")
	
	# Configurar propriedades da bola
	gravity_scale = 0.0
	lock_rotation = true
	linear_damp = 2.0
	
	# Conectar sinais
	body_entered.connect(_on_body_entered)
	print("✓ Sinais da bola conectados")
	
func _physics_process(delta):
	check_movement()
	
func check_movement():
	var current_velocity = linear_velocity.length()
	
	if current_velocity > velocity_threshold:
		if not is_moving:
			is_moving = true
			print("[Ball] ✓ Bola começou a se mover - velocidade: ", current_velocity)
	else:
		if is_moving:
			is_moving = false
			linear_velocity = Vector2.ZERO
			ball_stopped.emit()
			print("[Ball] ✓ Bola parou de se mover")

func _on_body_entered(body):
	# Verificar colisão com caçapas (pockets)
	if body.is_in_group("pockets"):
		ball_pocketed.emit()
		queue_free()

func set_ball_properties(color: Color, number: int):
	ball_color = color
	ball_number = number
	
	# Atualizar visual da bola
	var sprite = get_node("Sprite")
	if sprite:
		sprite.color = color

func get_ball_number() -> int:
	return ball_number

func get_ball_color() -> Color:
	return ball_color 
