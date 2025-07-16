extends Node

signal cat_health_changed(cat_id: int, new_health: int)
signal cat_died(cat_id: int)
signal cat_skill_used(cat_id: int, skill_name: String)

class_name CatData
extends Resource

@export var cat_id: int
@export var name: String
@export var max_health: int = 100
@export var current_health: int = 100
@export var speed: float = 1.0
@export var skin_texture: Texture2D
@export var special_ability: String = ""
@export var cards_in_hand: Array[String] = []
@export var is_ai: bool = false

var current_cats: Dictionary = {}
var cat_scenes: Dictionary = {}
var cat_data_resources: Dictionary = {}

func _ready():
	print("CatManager initialized")
	_load_cat_data()

func _load_cat_data():
	# Carregar dados dos gatos de arquivos de recursos
	var cat_files = [
		"res://data/cats/orange_cat.tres",
		"res://data/cats/black_cat.tres",
		"res://data/cats/white_cat.tres",
		"res://data/cats/gray_cat.tres"
	]
	
	for file_path in cat_files:
		if ResourceLoader.exists(file_path):
			var cat_data = load(file_path) as CatData
			if cat_data:
				cat_data_resources[cat_data.cat_id] = cat_data
				print("Loaded cat data for: ", cat_data.name)

func create_cat(cat_id: int, position: Vector2 = Vector2.ZERO, is_player: bool = true) -> Node2D:
	if not cat_data_resources.has(cat_id):
		print("Cat data not found for ID: ", cat_id)
		return null
	
	var cat_data = cat_data_resources[cat_id]
	var cat_scene = preload("res://scenes/player/Cat.tscn").instantiate()
	
	# Configurar dados do gato
	cat_scene.setup_cat(cat_data, is_player)
	cat_scene.global_position = position
	
	# Conectar sinais
	cat_scene.health_changed.connect(_on_cat_health_changed)
	cat_scene.died.connect(_on_cat_died)
	cat_scene.skill_used.connect(_on_cat_skill_used)
	
	# Armazenar referência
	current_cats[cat_id] = cat_scene
	
	print("Created cat: ", cat_data.name, " at position: ", position)
	return cat_scene

func get_cat(cat_id: int) -> Node2D:
	return current_cats.get(cat_id, null)

func get_cat_data(cat_id: int) -> CatData:
	return cat_data_resources.get(cat_id, null)

func get_all_cats() -> Array:
	return current_cats.values()

func get_player_cats() -> Array:
	var player_cats = []
	for cat in current_cats.values():
		if cat.is_player:
			player_cats.append(cat)
	return player_cats

func get_ai_cats() -> Array:
	var ai_cats = []
	for cat in current_cats.values():
		if not cat.is_player:
			ai_cats.append(cat)
	return ai_cats

func damage_cat(cat_id: int, damage: int):
	var cat = get_cat(cat_id)
	if cat:
		cat.take_damage(damage)

func heal_cat(cat_id: int, heal_amount: int):
	var cat = get_cat(cat_id)
	if cat:
		cat.heal(heal_amount)

func set_cat_speed(cat_id: int, speed_multiplier: float):
	var cat = get_cat(cat_id)
	if cat:
		cat.set_speed_multiplier(speed_multiplier)

func give_card_to_cat(cat_id: int, card_name: String):
	var cat_data = get_cat_data(cat_id)
	if cat_data:
		cat_data.cards_in_hand.append(card_name)
		print("Gave card '", card_name, "' to cat: ", cat_data.name)

func use_cat_skill(cat_id: int, skill_name: String):
	var cat = get_cat(cat_id)
	if cat:
		cat.use_skill(skill_name)

func get_cat_cards(cat_id: int) -> Array[String]:
	var cat_data = get_cat_data(cat_id)
	if cat_data:
		return cat_data.cards_in_hand
	return []

func remove_card_from_cat(cat_id: int, card_name: String):
	var cat_data = get_cat_data(cat_id)
	if cat_data:
		var index = cat_data.cards_in_hand.find(card_name)
		if index != -1:
			cat_data.cards_in_hand.remove_at(index)
			print("Removed card '", card_name, "' from cat: ", cat_data.name)

func get_alive_cats() -> Array:
	var alive_cats = []
	for cat in current_cats.values():
		if cat.is_alive():
			alive_cats.append(cat)
	return alive_cats

func get_dead_cats() -> Array:
	var dead_cats = []
	for cat in current_cats.values():
		if not cat.is_alive():
			dead_cats.append(cat)
	return dead_cats

func respawn_cat(cat_id: int, position: Vector2 = Vector2.ZERO):
	var cat = get_cat(cat_id)
	if cat:
		cat.respawn(position)

func remove_cat(cat_id: int):
	if current_cats.has(cat_id):
		var cat = current_cats[cat_id]
		cat.queue_free()
		current_cats.erase(cat_id)
		print("Removed cat with ID: ", cat_id)

func clear_all_cats():
	for cat in current_cats.values():
		cat.queue_free()
	current_cats.clear()
	print("All cats cleared")

# Métodos de callback para sinais
func _on_cat_health_changed(cat_id: int, new_health: int):
	cat_health_changed.emit(cat_id, new_health)
	print("Cat ", cat_id, " health changed to: ", new_health)

func _on_cat_died(cat_id: int):
	cat_died.emit(cat_id)
	print("Cat ", cat_id, " died")
	
	# Verificar se o jogo acabou
	var alive_cats = get_alive_cats()
	if alive_cats.size() == 0:
		GameStateManager.end_game()

func _on_cat_skill_used(cat_id: int, skill_name: String):
	cat_skill_used.emit(cat_id, skill_name)
	print("Cat ", cat_id, " used skill: ", skill_name)
	
	# Aplicar efeitos visuais
	EffectsManager.play_skill_effect(cat_id, skill_name)

# Métodos para salvar/carregar dados
func save_cat_data():
	var save_data = {}
	for cat_id in cat_data_resources.keys():
		save_data[cat_id] = cat_data_resources[cat_id]
	
	# Salvar em arquivo
	var file = FileAccess.open("user://cat_data.save", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()

func load_cat_data():
	var file = FileAccess.open("user://cat_data.save", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			var save_data = json.data
			# Processar dados carregados
			print("Cat data loaded successfully")
		else:
			print("Failed to parse cat save data") 