extends Node

signal effect_started(effect_name: String, position: Vector2)
signal effect_finished(effect_name: String)

var particle_systems: Dictionary = {}
var active_effects: Dictionary = {}
var tween_effects: Dictionary = {}
var shader_effects: Dictionary = {}

func _ready():
	print("EffectsManager initialized")
	_load_effect_resources()

func _load_effect_resources():
	# Carregar sistemas de partículas
	particle_systems = {
		"explosion": "res://scenes/effects/ExplosionParticles.tscn",
		"magic_sparkles": "res://scenes/effects/MagicSparkles.tscn",
		"smoke_trail": "res://scenes/effects/SmokeTrail.tscn",
		"star_burst": "res://scenes/effects/StarBurst.tscn",
		"teleport_effect": "res://scenes/effects/TeleportEffect.tscn",
		"magnetic_field": "res://scenes/effects/MagneticField.tscn",
		"ghost_particles": "res://scenes/effects/GhostParticles.tscn",
		"speed_lines": "res://scenes/effects/SpeedLines.tscn"
	}
	
	# Carregar shaders
	shader_effects = {
		"ghost_shader": "res://shaders/ghost_effect.gdshader",
		"explosive_shader": "res://shaders/explosive_aura.gdshader",
		"magnetic_shader": "res://shaders/magnetic_field.gdshader",
		"speed_shader": "res://shaders/speed_boost.gdshader"
	}

# Métodos para efeitos de partículas
func create_particle_effect(effect_name: String, position: Vector2, duration: float = 2.0) -> Node2D:
	if not particle_systems.has(effect_name):
		print("Particle effect not found: ", effect_name)
		return null
	
	var effect_path = particle_systems[effect_name]
	if not ResourceLoader.exists(effect_path):
		print("Particle effect file not found: ", effect_path)
		return null
	
	var effect_scene = load(effect_path)
	var effect_instance = effect_scene.instantiate()
	
	# Adicionar à cena atual
	get_tree().current_scene.add_child(effect_instance)
	effect_instance.global_position = position
	
	# Iniciar efeito
	if effect_instance.has_method("start_effect"):
		effect_instance.start_effect()
	
	# Armazenar referência
	var effect_id = effect_name + "_" + str(Time.get_unix_time_from_system())
	active_effects[effect_id] = effect_instance
	
	# Remover após duração
	await get_tree().create_timer(duration).timeout
	_remove_effect(effect_id)
	
	effect_started.emit(effect_name, position)
	print("Created particle effect: ", effect_name, " at ", position)
	
	return effect_instance

func create_explosion(position: Vector2, size: float = 1.0):
	var explosion = await create_particle_effect("explosion", position, 3.0)
	if explosion:
		explosion.scale = Vector2(size, size)
		
		# Adicionar shake da câmera
		_create_camera_shake(0.5, 10.0)
		
		# Efeito de luz
		_create_light_flash(position, Color.ORANGE, 0.3)

func create_magic_effect(position: Vector2, color: Color = Color.CYAN):
	var sparkles = await create_particle_effect("magic_sparkles", position, 2.0)
	if sparkles:
		sparkles.modulate = color

func create_teleport_effect(start_pos: Vector2, end_pos: Vector2):
	# Efeito de saída
	await create_particle_effect("teleport_effect", start_pos, 1.0)
	
	# Aguardar um pouco
	await get_tree().create_timer(0.5).timeout
	
	# Efeito de entrada
	await create_particle_effect("teleport_effect", end_pos, 1.0)

# Métodos para efeitos de tween
func create_tween_effect(target: Node, property: String, from_value, to_value, duration: float, ease_type: Tween.EaseType = Tween.EASE_OUT):
	var tween = create_tween()
	tween.set_ease(ease_type)
	
	target.set(property, from_value)
	tween.tween_property(target, property, to_value, duration)
	
	var effect_id = str(target.get_instance_id()) + "_" + property
	tween_effects[effect_id] = tween
	
	await tween.finished
	tween_effects.erase(effect_id)

func create_bounce_effect(target: Node, intensity: float = 0.2, duration: float = 0.5):
	var original_scale = target.scale
	var bounce_scale = original_scale * (1.0 + intensity)
	
	var tween = create_tween()
	tween.set_loops(2)
	tween.tween_property(target, "scale", bounce_scale, duration / 2)
	tween.tween_property(target, "scale", original_scale, duration / 2)

func create_fade_effect(target: Node, from_alpha: float, to_alpha: float, duration: float):
	await create_tween_effect(target, "modulate:a", from_alpha, to_alpha, duration)

func create_slide_effect(target: Node, from_pos: Vector2, to_pos: Vector2, duration: float):
	await create_tween_effect(target, "position", from_pos, to_pos, duration)

func create_rotation_effect(target: Node, rotation_amount: float, duration: float):
	var start_rotation = target.rotation
	var end_rotation = start_rotation + rotation_amount
	await create_tween_effect(target, "rotation", start_rotation, end_rotation, duration)

# Métodos para efeitos de câmera
func _create_camera_shake(duration: float, intensity: float):
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return
	
	var original_position = camera.global_position
	var shake_tween = create_tween()
	
	var shake_count = int(duration * 30) # 30 FPS
	for i in range(shake_count):
		var shake_offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		shake_tween.tween_property(camera, "global_position", original_position + shake_offset, duration / shake_count)
	
	shake_tween.tween_property(camera, "global_position", original_position, 0.1)

func _create_light_flash(position: Vector2, color: Color, duration: float):
	var light = PointLight2D.new()
	light.color = color
	light.energy = 2.0
	light.texture_scale = 3.0
	light.global_position = position
	
	get_tree().current_scene.add_child(light)
	
	# Fade out
	var tween = create_tween()
	tween.tween_property(light, "energy", 0.0, duration)
	await tween.finished
	
	light.queue_free()

# Métodos para efeitos específicos de cartas
func play_card_effect(card_name: String, player_id: int):
	var player_pos = _get_player_position(player_id)
	
	match card_name:
		"explosive_ball":
			create_magic_effect(player_pos, Color.RED)
			_create_camera_shake(0.3, 5.0)
		"teleport_ball":
			create_magic_effect(player_pos, Color.CYAN)
		"ghost_ball":
			create_magic_effect(player_pos, Color.WHITE)
		"magnetic_ball":
			create_magic_effect(player_pos, Color.PURPLE)
		"speed_boost":
			create_particle_effect("speed_lines", player_pos, 1.0)
		"freeze_time":
			_create_screen_freeze_effect()
		_:
			create_magic_effect(player_pos, Color.YELLOW)

func play_skill_effect(cat_id: int, skill_name: String):
	var cat_pos = _get_cat_position(cat_id)
	
	match skill_name:
		"meow_attack":
			_create_sound_wave_effect(cat_pos)
		"purr_heal":
			create_magic_effect(cat_pos, Color.GREEN)
		"scratch_damage":
			_create_scratch_effect(cat_pos)
		_:
			create_magic_effect(cat_pos, Color.GOLD)

# Métodos para efeitos em bolas
func add_ball_effect(ball: Node2D, effect_name: String):
	match effect_name:
		"explosive_aura":
			_add_explosive_aura(ball)
		"ghost_effect":
			_add_ghost_effect(ball)
		"magnetic_field":
			_add_magnetic_field(ball)
		"speed_trail":
			_add_speed_trail(ball)

func _add_explosive_aura(ball: Node2D):
	var aura_particles = await create_particle_effect("magic_sparkles", ball.global_position, 5.0)
	if aura_particles:
		aura_particles.reparent(ball)
		aura_particles.position = Vector2.ZERO
		aura_particles.modulate = Color.RED

func _add_ghost_effect(ball: Node2D):
	# Aplicar shader de fantasma
	var sprite = ball.get_node("Sprite")
	if sprite:
		var ghost_shader = load(shader_effects["ghost_shader"])
		var material = ShaderMaterial.new()
		material.shader = ghost_shader
		sprite.material = material
		
		# Animar transparência
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(sprite, "modulate:a", 0.3, 0.5)
		tween.tween_property(sprite, "modulate:a", 0.7, 0.5)

func _add_magnetic_field(ball: Node2D):
	var magnetic_particles = await create_particle_effect("magnetic_field", ball.global_position, 10.0)
	if magnetic_particles:
		magnetic_particles.reparent(ball)
		magnetic_particles.position = Vector2.ZERO

func _add_speed_trail(ball: Node2D):
	var trail_particles = await create_particle_effect("speed_lines", ball.global_position, 3.0)
	if trail_particles:
		trail_particles.reparent(ball)
		trail_particles.position = Vector2.ZERO

# Efeitos especiais
func _create_screen_freeze_effect():
	var screen_overlay = ColorRect.new()
	screen_overlay.color = Color(0.5, 0.8, 1.0, 0.3)
	screen_overlay.size = get_viewport().size
	
	get_tree().current_scene.add_child(screen_overlay)
	
	# Efeito de congelamento
	var tween = create_tween()
	tween.tween_property(screen_overlay, "modulate:a", 0.0, 1.0)
	await tween.finished
	
	screen_overlay.queue_free()

func _create_sound_wave_effect(position: Vector2):
	var wave_count = 3
	for i in range(wave_count):
		await get_tree().create_timer(0.2 * i).timeout
		
		var wave_circle = _create_expanding_circle(position, Color.YELLOW, 0.5)
		var tween = create_tween()
		tween.parallel().tween_property(wave_circle, "scale", Vector2(5, 5), 0.8)
		tween.parallel().tween_property(wave_circle, "modulate:a", 0.0, 0.8)
		
		await tween.finished
		wave_circle.queue_free()

func _create_scratch_effect(position: Vector2):
	var scratch_lines = []
	for i in range(5):
		var line = Line2D.new()
		line.add_point(Vector2.ZERO)
		line.add_point(Vector2(randf_range(20, 40), randf_range(-10, 10)))
		line.width = 3.0
		line.default_color = Color.WHITE
		line.position = position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		
		get_tree().current_scene.add_child(line)
		scratch_lines.append(line)
		
		# Fade out
		var tween = create_tween()
		tween.tween_property(line, "modulate:a", 0.0, 0.3)
	
	await get_tree().create_timer(0.5).timeout
	for line in scratch_lines:
		line.queue_free()

func _create_expanding_circle(position: Vector2, color: Color, duration: float) -> Node2D:
	var circle = Node2D.new()
	circle.position = position
	
	# Criar visual do círculo usando Line2D
	var line = Line2D.new()
	var points = []
	var segments = 32
	for i in range(segments + 1):
		var angle = (i / float(segments)) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * 10)
	
	for point in points:
		line.add_point(point)
	
	line.width = 2.0
	line.default_color = color
	line.closed = true
	
	circle.add_child(line)
	get_tree().current_scene.add_child(circle)
	
	return circle

# Métodos utilitários
func _get_player_position(player_id: int) -> Vector2:
	var cat = CatManager.get_cat(player_id)
	if cat:
		return cat.global_position
	return Vector2.ZERO

func _get_cat_position(cat_id: int) -> Vector2:
	var cat = CatManager.get_cat(cat_id)
	if cat:
		return cat.global_position
	return Vector2.ZERO

func _remove_effect(effect_id: String):
	if active_effects.has(effect_id):
		var effect = active_effects[effect_id]
		if effect and is_instance_valid(effect):
			effect.queue_free()
		active_effects.erase(effect_id)

func stop_effect(effect_id: String):
	_remove_effect(effect_id)

func stop_all_effects():
	for effect_id in active_effects.keys():
		_remove_effect(effect_id)
	
	for tween in tween_effects.values():
		tween.kill()
	tween_effects.clear()
	
	print("All effects stopped")

func get_active_effects_count() -> int:
	return active_effects.size()

# Métodos para performance
func set_effects_quality(quality: String):
	# Ajustar qualidade dos efeitos baseado na performance
	match quality:
		"low":
			_set_particle_quality(0.5)
		"medium":
			_set_particle_quality(0.75)
		"high":
			_set_particle_quality(1.0)

func _set_particle_quality(quality_factor: float):
	# Aplicar fator de qualidade aos efeitos de partículas
	for effect in active_effects.values():
		if effect.has_method("set_quality"):
			effect.set_quality(quality_factor) 