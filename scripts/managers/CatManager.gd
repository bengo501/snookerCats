extends Node

signal player_data_updated(player_id: int)
signal player_level_up(player_id: int, new_level: int)

enum CatType {
	ORANGE,
	BLACK,
	WHITE,
	STRIPED,
	PERSIAN
}

class PlayerData:
	var id: int
	var name: String
	var cat_type: CatType
	var level: int
	var experience: int
	var total_score: int
	var games_won: int
	var games_played: int
	var favorite_shot: String
	var accuracy: float
	var power_control: float
	
	func _init(player_id: int, player_name: String, cat: CatType):
		id = player_id
		name = player_name
		cat_type = cat
		level = 1
		experience = 0
		total_score = 0
		games_won = 0
		games_played = 0
		favorite_shot = "straight"
		accuracy = 0.5
		power_control = 0.5
	
	func add_experience(exp: int):
		experience += exp
		_check_level_up()
	
	func _check_level_up():
		var exp_needed = level * 100
		if experience >= exp_needed:
			level += 1
			experience -= exp_needed
			# Melhorar stats com level up
			accuracy = min(accuracy + 0.05, 1.0)
			power_control = min(power_control + 0.05, 1.0)
	
	func get_win_rate() -> float:
		if games_played == 0:
			return 0.0
		return float(games_won) / float(games_played)
	
	func get_cat_color() -> Color:
		match cat_type:
			CatType.ORANGE:
				return Color.ORANGE
			CatType.BLACK:
				return Color.BLACK
			CatType.WHITE:
				return Color.WHITE
			CatType.STRIPED:
				return Color(0.5, 0.3, 0.1)  # Marrom
			CatType.PERSIAN:
				return Color(0.8, 0.8, 0.9)  # Cinza claro
			_:
				return Color.GRAY

var players: Dictionary = {}
var current_player_id: int = 1
var max_players: int = 2

func _ready():
	print("CatManager inicializado")
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Aguardar um frame para garantir que a árvore de cena esteja pronta
	await get_tree().process_frame
	
	# Criar jogadores padrão
	_create_default_players()

func _create_default_players():
	# Jogador 1 - Gato Laranja
	var player1 = PlayerData.new(1, "Gato Laranja", CatType.ORANGE)
	player1.favorite_shot = "straight"
	player1.accuracy = 0.6
	player1.power_control = 0.7
	players[1] = player1
	
	# Jogador 2 - Gato Preto
	var player2 = PlayerData.new(2, "Gato Preto", CatType.BLACK)
	player2.favorite_shot = "curve"
	player2.accuracy = 0.7
	player2.power_control = 0.5
	players[2] = player2
	
	print("Jogadores padrão criados")

func get_player(player_id: int) -> PlayerData:
	return players.get(player_id, null)

func get_current_player() -> PlayerData:
	return get_player(current_player_id)

func set_current_player(player_id: int):
	if players.has(player_id):
		current_player_id = player_id
		print("Jogador atual mudou para: ", players[player_id].name)

func add_player(name: String, cat_type: CatType) -> int:
	if players.size() >= max_players:
		print("ERRO: Número máximo de jogadores atingido")
		return -1
	
	var new_id = players.size() + 1
	var new_player = PlayerData.new(new_id, name, cat_type)
	players[new_id] = new_player
	
	print("Novo jogador adicionado: ", name, " (ID: ", new_id, ")")
	player_data_updated.emit(new_id)
	return new_id

func update_player_stats(player_id: int, game_score: int, won: bool):
	var player = get_player(player_id)
	if not player:
		print("ERRO: Jogador não encontrado: ", player_id)
		return
	
	player.total_score += game_score
	player.games_played += 1
	if won:
		player.games_won += 1
		player.add_experience(50)  # Bônus por vitória
	else:
		player.add_experience(10)  # Experiência por jogar
	
	print("Stats atualizadas para ", player.name, ": Score=", player.total_score, " Level=", player.level)
	player_data_updated.emit(player_id)

func get_player_accuracy_modifier(player_id: int) -> float:
	var player = get_player(player_id)
	if player:
		return player.accuracy
	return 0.5

func get_player_power_modifier(player_id: int) -> float:
	var player = get_player(player_id)
	if player:
		return player.power_control
	return 0.5

func get_player_favorite_shot(player_id: int) -> String:
	var player = get_player(player_id)
	if player:
		return player.favorite_shot
	return "straight"

func get_all_players() -> Array:
	return players.values()

func get_player_count() -> int:
	return players.size()

func reset_player_stats(player_id: int):
	var player = get_player(player_id)
	if player:
		player.total_score = 0
		player.games_won = 0
		player.games_played = 0
		player.experience = 0
		player.level = 1
		print("Stats resetadas para: ", player.name)
		player_data_updated.emit(player_id)

func get_player_color(player_id: int) -> Color:
	var player = get_player(player_id)
	if player:
		return player.get_cat_color()
	return Color.GRAY

func get_manager_type() -> String:
	return "CatManager" 