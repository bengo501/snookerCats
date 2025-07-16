extends Node

signal music_changed(track_name: String)
signal sound_played(sound_name: String)
signal volume_changed(bus_name: String, volume: float)

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var ambient_player: AudioStreamPlayer

var music_tracks: Dictionary = {}
var sound_effects: Dictionary = {}
var current_music_track: String = ""
var music_volume: float = 0.8
var sfx_volume: float = 1.0
var ambient_volume: float = 0.6

var sfx_player_pool_size: int = 10
var current_sfx_player_index: int = 0

func _ready():
	print("AudioManager initialized")
	_setup_audio_players()
	_load_audio_resources()
	_setup_audio_buses()

func _setup_audio_players():
	# Criar player de música
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Music"
	add_child(music_player)
	
	# Criar pool de players para efeitos sonoros
	for i in range(sfx_player_pool_size):
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.name = "SFXPlayer_" + str(i)
		sfx_player.bus = "SFX"
		add_child(sfx_player)
		sfx_players.append(sfx_player)
	
	# Criar player para sons ambientes
	ambient_player = AudioStreamPlayer.new()
	ambient_player.name = "AmbientPlayer"
	ambient_player.bus = "Ambient"
	ambient_player.autoplay = false
	add_child(ambient_player)

func _setup_audio_buses():
	# Configurar volumes iniciais dos buses
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(1.0))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(music_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(sfx_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Ambient"), linear_to_db(ambient_volume))

func _load_audio_resources():
	# Carregar trilhas de música
	music_tracks = {
		"menu": "res://assets/sounds/music/menu_theme.ogg",
		"game": "res://assets/sounds/music/game_theme.ogg",
		"victory": "res://assets/sounds/music/victory_theme.ogg",
		"defeat": "res://assets/sounds/music/defeat_theme.ogg"
	}
	
	# Carregar efeitos sonoros
	sound_effects = {
		"ball_hit": "res://assets/sounds/sfx/ball_hit.wav",
		"ball_pocket": "res://assets/sounds/sfx/ball_pocket.wav",
		"wall_bounce": "res://assets/sounds/sfx/wall_bounce.wav",
		"card_use": "res://assets/sounds/sfx/card_use.wav",
		"card_draw": "res://assets/sounds/sfx/card_draw.wav",
		"explosion": "res://assets/sounds/sfx/explosion.wav",
		"teleport": "res://assets/sounds/sfx/teleport.wav",
		"power_up": "res://assets/sounds/sfx/power_up.wav",
		"button_click": "res://assets/sounds/sfx/button_click.wav",
		"button_hover": "res://assets/sounds/sfx/button_hover.wav",
		"cat_meow": "res://assets/sounds/sfx/cat_meow.wav",
		"cat_purr": "res://assets/sounds/sfx/cat_purr.wav",
		"game_over": "res://assets/sounds/sfx/game_over.wav",
		"turn_change": "res://assets/sounds/sfx/turn_change.wav",
		"skill_activate": "res://assets/sounds/sfx/skill_activate.wav"
	}

# Métodos para música
func play_music(track_name: String, fade_in: bool = true):
	if current_music_track == track_name and music_player.playing:
		return
	
	if not music_tracks.has(track_name):
		print("Music track not found: ", track_name)
		return
	
	var track_path = music_tracks[track_name]
	if not ResourceLoader.exists(track_path):
		print("Music file not found: ", track_path)
		return
	
	var audio_stream = load(track_path)
	if not audio_stream:
		print("Failed to load music: ", track_path)
		return
	
	# Fade out música atual se estiver tocando
	if music_player.playing and fade_in:
		await fade_out_music()
	
	music_player.stream = audio_stream
	music_player.play()
	
	if fade_in:
		fade_in_music()
	
	current_music_track = track_name
	music_changed.emit(track_name)
	print("Playing music: ", track_name)

func stop_music(fade_out: bool = true):
	if fade_out:
		await fade_out_music()
	else:
		music_player.stop()
	
	current_music_track = ""
	print("Music stopped")

func pause_music():
	music_player.stream_paused = true
	print("Music paused")

func resume_music():
	music_player.stream_paused = false
	print("Music resumed")

func fade_in_music(duration: float = 1.0):
	music_player.volume_db = -80
	var tween = create_tween()
	tween.tween_method(_set_music_volume_db, -80, 0, duration)

func fade_out_music(duration: float = 1.0):
	var tween = create_tween()
	tween.tween_method(_set_music_volume_db, 0, -80, duration)
	await tween.finished

func _set_music_volume_db(volume_db: float):
	music_player.volume_db = volume_db

# Métodos para efeitos sonoros
func play_sound(sound_name: String, volume: float = 1.0, pitch: float = 1.0):
	if not sound_effects.has(sound_name):
		print("Sound effect not found: ", sound_name)
		return
	
	var sound_path = sound_effects[sound_name]
	if not ResourceLoader.exists(sound_path):
		print("Sound file not found: ", sound_path)
		return
	
	var audio_stream = load(sound_path)
	if not audio_stream:
		print("Failed to load sound: ", sound_path)
		return
	
	var player = _get_available_sfx_player()
	if player:
		player.stream = audio_stream
		player.volume_db = linear_to_db(volume)
		player.pitch_scale = pitch
		player.play()
		
		sound_played.emit(sound_name)
		print("Playing sound: ", sound_name)

func play_sound_at_position(sound_name: String, position: Vector2, volume: float = 1.0):
	# Para sons posicionais, você pode usar AudioStreamPlayer2D
	play_sound(sound_name, volume)

func _get_available_sfx_player() -> AudioStreamPlayer:
	# Encontrar player disponível no pool
	for i in range(sfx_player_pool_size):
		var player_index = (current_sfx_player_index + i) % sfx_player_pool_size
		var player = sfx_players[player_index]
		
		if not player.playing:
			current_sfx_player_index = (player_index + 1) % sfx_player_pool_size
			return player
	
	# Se todos estão ocupados, usar o próximo na fila
	var player = sfx_players[current_sfx_player_index]
	current_sfx_player_index = (current_sfx_player_index + 1) % sfx_player_pool_size
	return player

# Métodos específicos do jogo
func play_menu_music():
	play_music("menu")

func play_game_music():
	play_music("game")

func play_victory_music():
	play_music("victory")

func play_defeat_music():
	play_music("defeat")

func play_ball_hit_sound():
	play_sound("ball_hit", randf_range(0.8, 1.2), randf_range(0.9, 1.1))

func play_ball_pocket_sound():
	play_sound("ball_pocket")

func play_wall_bounce_sound():
	play_sound("wall_bounce", randf_range(0.6, 1.0))

func play_card_sound(card_name: String):
	match card_name:
		"teleport_ball":
			play_sound("teleport")
		"explosive_ball":
			play_sound("power_up")
		_:
			play_sound("card_use")

func play_explosion_sound():
	play_sound("explosion")

func play_cat_sound(sound_type: String):
	match sound_type:
		"meow":
			play_sound("cat_meow")
		"purr":
			play_sound("cat_purr")

func play_ui_sound(ui_element: String):
	match ui_element:
		"button_click":
			play_sound("button_click")
		"button_hover":
			play_sound("button_hover")

func play_game_over_sound():
	play_sound("game_over")

func play_turn_change_sound():
	play_sound("turn_change")

func play_skill_sound():
	play_sound("skill_activate")

# Métodos para controle de volume
func set_master_volume(volume: float):
	volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(volume))
	volume_changed.emit("Master", volume)

func set_music_volume(volume: float):
	music_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(music_volume))
	volume_changed.emit("Music", music_volume)

func set_sfx_volume(volume: float):
	sfx_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(sfx_volume))
	volume_changed.emit("SFX", sfx_volume)

func set_ambient_volume(volume: float):
	ambient_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Ambient"), linear_to_db(ambient_volume))
	volume_changed.emit("Ambient", ambient_volume)

func get_master_volume() -> float:
	return db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))

func get_music_volume() -> float:
	return music_volume

func get_sfx_volume() -> float:
	return sfx_volume

func get_ambient_volume() -> float:
	return ambient_volume

# Métodos para sons ambiente
func play_ambient_sound(sound_name: String, loop: bool = true):
	if not sound_effects.has(sound_name):
		print("Ambient sound not found: ", sound_name)
		return
	
	var sound_path = sound_effects[sound_name]
	if ResourceLoader.exists(sound_path):
		var audio_stream = load(sound_path)
		if audio_stream:
			ambient_player.stream = audio_stream
			ambient_player.play()
			print("Playing ambient sound: ", sound_name)

func stop_ambient_sound():
	ambient_player.stop()
	print("Ambient sound stopped")

# Métodos utilitários
func is_music_playing() -> bool:
	return music_player.playing

func get_current_music_track() -> String:
	return current_music_track

func mute_all_audio():
	set_master_volume(0.0)

func unmute_all_audio():
	set_master_volume(1.0)

func stop_all_sounds():
	for player in sfx_players:
		player.stop()
	music_player.stop()
	ambient_player.stop()
	print("All audio stopped") 