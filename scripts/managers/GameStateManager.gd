extends Node

signal state_changed(old_state: GameState, new_state: GameState)
signal state_entered(state: GameState)
signal state_exited(state: GameState)

enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	ENEMY_TURN,
	OPTIONS,
	SKILLS,
	GAME_OVER,
	LOADING
}

var current_state: GameState = GameState.MENU
var previous_state: GameState = GameState.MENU
var state_stack: Array[GameState] = []

func _ready():
	print("GameStateManager initialized")
	set_current_state(GameState.MENU)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		handle_escape_key()

func set_current_state(new_state: GameState):
	if current_state == new_state:
		return
	
	var old_state = current_state
	previous_state = current_state
	current_state = new_state
	
	print("State changed from ", GameState.keys()[old_state], " to ", GameState.keys()[new_state])
	
	# Emitir sinais
	state_exited.emit(old_state)
	state_changed.emit(old_state, new_state)
	state_entered.emit(new_state)
	
	# Processar mudança de estado
	_process_state_change(old_state, new_state)

func _process_state_change(old_state: GameState, new_state: GameState):
	match new_state:
		GameState.MENU:
			_enter_menu_state()
		GameState.PLAYING:
			_enter_playing_state()
		GameState.PAUSED:
			_enter_paused_state()
		GameState.ENEMY_TURN:
			_enter_enemy_turn_state()
		GameState.OPTIONS:
			_enter_options_state()
		GameState.SKILLS:
			_enter_skills_state()
		GameState.GAME_OVER:
			_enter_game_over_state()
		GameState.LOADING:
			_enter_loading_state()

func _enter_menu_state():
	UIManager.show_main_menu()
	AudioManager.play_menu_music()
	get_tree().paused = false

func _enter_playing_state():
	UIManager.show_game_ui()
	AudioManager.play_game_music()
	get_tree().paused = false
	GameManager.resume_game()

func _enter_paused_state():
	UIManager.show_pause_menu()
	AudioManager.pause_music()
	get_tree().paused = true

func _enter_enemy_turn_state():
	UIManager.show_enemy_turn_indicator()
	GameManager.start_enemy_turn()

func _enter_options_state():
	UIManager.show_options_menu()

func _enter_skills_state():
	UIManager.show_skills_menu()
	CardManager.show_available_cards()

func _enter_game_over_state():
	UIManager.show_game_over_screen()
	AudioManager.play_game_over_sound()
	get_tree().paused = true

func _enter_loading_state():
	UIManager.show_loading_screen()

func push_state(new_state: GameState):
	"""Empilha o estado atual e muda para um novo estado"""
	state_stack.push_back(current_state)
	set_current_state(new_state)

func pop_state():
	"""Volta para o estado anterior na pilha"""
	if state_stack.size() > 0:
		var previous_state = state_stack.pop_back()
		set_current_state(previous_state)

func handle_escape_key():
	match current_state:
		GameState.PLAYING:
			set_current_state(GameState.PAUSED)
		GameState.PAUSED:
			set_current_state(GameState.PLAYING)
		GameState.OPTIONS:
			pop_state()
		GameState.SKILLS:
			set_current_state(GameState.PLAYING)
		GameState.GAME_OVER:
			set_current_state(GameState.MENU)

func get_current_state() -> GameState:
	return current_state

func get_previous_state() -> GameState:
	return previous_state

func is_in_state(state: GameState) -> bool:
	return current_state == state

func is_game_active() -> bool:
	return current_state == GameState.PLAYING or current_state == GameState.ENEMY_TURN

func can_use_skills() -> bool:
	return current_state == GameState.PLAYING or current_state == GameState.SKILLS

func can_pause() -> bool:
	return current_state == GameState.PLAYING or current_state == GameState.ENEMY_TURN

# Métodos de conveniência
func start_game():
	set_current_state(GameState.PLAYING)

func pause_game():
	if can_pause():
		set_current_state(GameState.PAUSED)

func resume_game():
	if current_state == GameState.PAUSED:
		set_current_state(GameState.PLAYING)

func open_skills_menu():
	if can_use_skills():
		push_state(GameState.SKILLS)

func open_options():
	push_state(GameState.OPTIONS)

func end_game():
	set_current_state(GameState.GAME_OVER)

func return_to_menu():
	state_stack.clear()
	set_current_state(GameState.MENU) 