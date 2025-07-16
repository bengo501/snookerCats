extends Node

signal shot_fired(player_id: int, force: Vector2, position: Vector2)
signal shot_prepared(player_id: int, aim_direction: Vector2)
signal special_effect_activated(effect_name: String, player_id: int)

var current_player_id: int = 1
var shot_power: float = 0.0
var max_shot_power: float = 1000.0
var aim_direction: Vector2 = Vector2.ZERO
var is_aiming: bool = false
var is_charging: bool = false

# Modificadores ativos
var active_effects: Dictionary = {}
var shots_remaining: Dictionary = {}

func _ready():
	print("CueManager initialized")
	_initialize_effects()

func _initialize_effects():
	# Inicializar efeitos para cada jogador
	for player_id in range(1, 5):
		active_effects[player_id] = {}
		shots_remaining[player_id] = {}

func start_aiming(player_id: int, start_position: Vector2):
	if not GameStateManager.is_game_active():
		return false
	
	current_player_id = player_id
	is_aiming = true
	shot_power = 0.0
	
	print("Player ", player_id, " started aiming")
	return true

func update_aim(target_position: Vector2):
	if not is_aiming:
		return
	
	var cue_ball = _get_cue_ball()
	if cue_ball:
		aim_direction = (target_position - cue_ball.global_position).normalized()
		shot_prepared.emit(current_player_id, aim_direction)

func start_charging():
	if not is_aiming:
		return false
	
	is_charging = true
	shot_power = 0.0
	print("Started charging shot")
	return true

func update_charge(delta: float):
	if not is_charging:
		return
	
	shot_power = min(shot_power + max_shot_power * delta, max_shot_power)
	
	# Aplicar modificador de velocidade se ativo
	if _has_effect(current_player_id, "speed_boost"):
		var multiplier = active_effects[current_player_id]["speed_boost"]["multiplier"]
		shot_power *= multiplier

func fire_shot() -> bool:
	if not is_charging or aim_direction == Vector2.ZERO:
		return false
	
	var cue_ball = _get_cue_ball()
	if not cue_ball:
		return false
	
	# Calcular força base
	var force = aim_direction * shot_power
	
	# Aplicar modificadores ativos
	force = _apply_shot_modifiers(force)
	
	# Aplicar força na bola
	_apply_shot_force(cue_ball, force)
	
	# Processar efeitos especiais
	_process_special_effects(cue_ball)
	
	# Emitir sinal
	shot_fired.emit(current_player_id, force, cue_ball.global_position)
	
	# Decrementar contadores de efeitos
	_decrement_shot_counters()
	
	# Resetar estado
	is_aiming = false
	is_charging = false
	shot_power = 0.0
	
	print("Shot fired with force: ", force.length())
	return true

func _get_cue_ball() -> RigidBody2D:
	var balls = get_tree().get_nodes_in_group("cue_ball")
	if balls.size() > 0:
		return balls[0]
	return null

func _apply_shot_modifiers(base_force: Vector2) -> Vector2:
	var modified_force = base_force
	
	# Aplicar modificadores baseados nos efeitos ativos
	for effect_name in active_effects[current_player_id].keys():
		match effect_name:
			"speed_boost":
				var multiplier = active_effects[current_player_id][effect_name]["multiplier"]
				modified_force *= multiplier
			"precision_aim":
				# Mira precisa não modifica a força, apenas a visualização
				pass
	
	return modified_force

func _apply_shot_force(cue_ball: RigidBody2D, force: Vector2):
	# Verificar se há efeito de teletransporte
	if _has_effect(current_player_id, "teleport_ball"):
		var teleport_pos = active_effects[current_player_id]["teleport_ball"]["position"]
		cue_ball.global_position = teleport_pos
		_remove_effect(current_player_id, "teleport_ball")
	
	# Aplicar força
	cue_ball.apply_central_impulse(force)

func _process_special_effects(cue_ball: RigidBody2D):
	# Processar efeitos especiais que acontecem após o tiro
	if _has_effect(current_player_id, "explosive_ball"):
		_setup_explosive_ball(cue_ball)
		_remove_effect(current_player_id, "explosive_ball")
	
	if _has_effect(current_player_id, "ghost_ball"):
		_setup_ghost_ball(cue_ball)
		_remove_effect(current_player_id, "ghost_ball")
	
	if _has_effect(current_player_id, "magnetic_ball"):
		_setup_magnetic_ball(cue_ball)

func _setup_explosive_ball(cue_ball: RigidBody2D):
	# Conectar sinal para explosão na primeira colisão
	if not cue_ball.body_entered.is_connected(_on_explosive_collision):
		cue_ball.body_entered.connect(_on_explosive_collision)
	
	# Adicionar efeito visual
	EffectsManager.add_ball_effect(cue_ball, "explosive_aura")
	special_effect_activated.emit("explosive_ball", current_player_id)

func _setup_ghost_ball(cue_ball: RigidBody2D):
	# Temporariamente desabilitar colisão com paredes
	cue_ball.collision_mask &= ~2  # Remove layer 2 (walls)
	
	# Reabilitar após 2 segundos
	await get_tree().create_timer(2.0).timeout
	cue_ball.collision_mask |= 2  # Adiciona layer 2 de volta
	
	# Efeito visual
	EffectsManager.add_ball_effect(cue_ball, "ghost_effect")
	special_effect_activated.emit("ghost_ball", current_player_id)

func _setup_magnetic_ball(cue_ball: RigidBody2D):
	# Adicionar área magnética
	var magnetic_area = preload("res://scenes/effects/MagneticArea.tscn").instantiate()
	cue_ball.add_child(magnetic_area)
	
	# Efeito visual
	EffectsManager.add_ball_effect(cue_ball, "magnetic_field")
	special_effect_activated.emit("magnetic_ball", current_player_id)

func _on_explosive_collision(body):
	if body.is_in_group("balls"):
		# Criar explosão
		var explosion_force = 500.0
		var explosion_radius = 100.0
		
		var nearby_balls = get_tree().get_nodes_in_group("balls")
		for ball in nearby_balls:
			var distance = body.global_position.distance_to(ball.global_position)
			if distance < explosion_radius:
				var direction = (ball.global_position - body.global_position).normalized()
				var force = direction * explosion_force * (1.0 - distance / explosion_radius)
				ball.apply_central_impulse(force)
		
		# Efeito visual da explosão
		EffectsManager.create_explosion(body.global_position)
		AudioManager.play_explosion_sound()

func _decrement_shot_counters():
	for effect_name in shots_remaining[current_player_id].keys():
		shots_remaining[current_player_id][effect_name] -= 1
		if shots_remaining[current_player_id][effect_name] <= 0:
			_remove_effect(current_player_id, effect_name)

# Métodos para ativar efeitos de cartas
func enable_double_shot(player_id: int):
	active_effects[player_id]["double_shot"] = {"active": true}
	shots_remaining[player_id]["double_shot"] = 2
	print("Double shot enabled for player: ", player_id)

func enable_explosive_ball(player_id: int):
	active_effects[player_id]["explosive_ball"] = {"active": true}
	shots_remaining[player_id]["explosive_ball"] = 1
	print("Explosive ball enabled for player: ", player_id)

func enable_ghost_ball(player_id: int):
	active_effects[player_id]["ghost_ball"] = {"active": true}
	shots_remaining[player_id]["ghost_ball"] = 1
	print("Ghost ball enabled for player: ", player_id)

func enable_precision_aim(player_id: int, duration: float):
	active_effects[player_id]["precision_aim"] = {"active": true, "duration": duration}
	
	# Remover após duração
	await get_tree().create_timer(duration).timeout
	_remove_effect(player_id, "precision_aim")
	print("Precision aim enabled for player: ", player_id)

func enable_teleport_mode(player_id: int):
	active_effects[player_id]["teleport_ball"] = {"active": true, "position": Vector2.ZERO}
	UIManager.show_teleport_selector(player_id)
	print("Teleport mode enabled for player: ", player_id)

func set_teleport_position(player_id: int, position: Vector2):
	if _has_effect(player_id, "teleport_ball"):
		active_effects[player_id]["teleport_ball"]["position"] = position
		shots_remaining[player_id]["teleport_ball"] = 1

func enable_magnetic_ball(player_id: int, shots: int):
	active_effects[player_id]["magnetic_ball"] = {"active": true}
	shots_remaining[player_id]["magnetic_ball"] = shots
	print("Magnetic ball enabled for player: ", player_id, " for ", shots, " shots")

func enable_speed_boost(player_id: int, multiplier: float, shots: int):
	active_effects[player_id]["speed_boost"] = {"active": true, "multiplier": multiplier}
	shots_remaining[player_id]["speed_boost"] = shots
	print("Speed boost enabled for player: ", player_id, " (", multiplier, "x for ", shots, " shots)")

# Métodos utilitários
func _has_effect(player_id: int, effect_name: String) -> bool:
	return active_effects[player_id].has(effect_name)

func _remove_effect(player_id: int, effect_name: String):
	if active_effects[player_id].has(effect_name):
		active_effects[player_id].erase(effect_name)
	if shots_remaining[player_id].has(effect_name):
		shots_remaining[player_id].erase(effect_name)
	print("Removed effect: ", effect_name, " from player: ", player_id)

func get_active_effects(player_id: int) -> Dictionary:
	return active_effects.get(player_id, {})

func has_precision_aim(player_id: int) -> bool:
	return _has_effect(player_id, "precision_aim")

func can_shoot_again(player_id: int) -> bool:
	return _has_effect(player_id, "double_shot")

func get_shot_power() -> float:
	return shot_power

func get_max_shot_power() -> float:
	return max_shot_power

func get_aim_direction() -> Vector2:
	return aim_direction

func is_player_aiming() -> bool:
	return is_aiming

func is_player_charging() -> bool:
	return is_charging

func cancel_shot():
	is_aiming = false
	is_charging = false
	shot_power = 0.0
	print("Shot cancelled")

func reset_player_effects(player_id: int):
	active_effects[player_id].clear()
	shots_remaining[player_id].clear()
	print("Reset effects for player: ", player_id) 