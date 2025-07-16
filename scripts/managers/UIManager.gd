extends Node

signal ui_element_shown(element_name: String)
signal ui_element_hidden(element_name: String)
signal button_pressed(button_name: String)

var ui_elements: Dictionary = {}
var current_ui_state: String = "none"

func _ready():
	print("UIManager initialized")
	_initialize_ui_elements()

func _initialize_ui_elements():
	# Inicializar referências para elementos de UI
	ui_elements = {
		"main_menu": null,
		"game_ui": null,
		"pause_menu": null,
		"options_menu": null,
		"skills_menu": null,
		"game_over_screen": null,
		"loading_screen": null,
		"cards_ui": null,
		"teleport_selector": null,
		"enemy_turn_indicator": null
	}

func show_main_menu():
	_hide_all_ui()
	_show_ui_element("main_menu")
	current_ui_state = "main_menu"

func show_game_ui():
	_hide_all_ui()
	_show_ui_element("game_ui")
	current_ui_state = "game_ui"

func show_pause_menu():
	_show_ui_element("pause_menu")
	current_ui_state = "pause_menu"

func show_options_menu():
	_show_ui_element("options_menu")
	current_ui_state = "options_menu"

func show_skills_menu():
	_show_ui_element("skills_menu")
	current_ui_state = "skills_menu"

func show_game_over_screen():
	_show_ui_element("game_over_screen")
	current_ui_state = "game_over"

func show_loading_screen():
	_show_ui_element("loading_screen")
	current_ui_state = "loading"

func hide_loading_screen():
	_hide_ui_element("loading_screen")

func show_cards_ui(cards_data: Dictionary):
	_show_ui_element("cards_ui")
	if ui_elements["cards_ui"]:
		ui_elements["cards_ui"].update_cards(cards_data)

func show_teleport_selector(player_id: int):
	_show_ui_element("teleport_selector")
	if ui_elements["teleport_selector"]:
		ui_elements["teleport_selector"].setup_for_player(player_id)

func show_enemy_turn_indicator():
	_show_ui_element("enemy_turn_indicator")

func hide_enemy_turn_indicator():
	_hide_ui_element("enemy_turn_indicator")

func _show_ui_element(element_name: String):
	if not ui_elements.has(element_name):
		print("UI element not found: ", element_name)
		return
	
	# Carregar elemento se necessário
	if ui_elements[element_name] == null:
		ui_elements[element_name] = _load_ui_element(element_name)
	
	var element = ui_elements[element_name]
	if element:
		element.visible = true
		element.modulate.a = 0.0
		
		# Animação de fade in
		var tween = create_tween()
		tween.tween_property(element, "modulate:a", 1.0, 0.3)
		
		ui_element_shown.emit(element_name)
		print("Showed UI element: ", element_name)

func _hide_ui_element(element_name: String):
	if not ui_elements.has(element_name) or ui_elements[element_name] == null:
		return
	
	var element = ui_elements[element_name]
	if element and element.visible:
		# Animação de fade out
		var tween = create_tween()
		tween.tween_property(element, "modulate:a", 0.0, 0.2)
		await tween.finished
		
		element.visible = false
		ui_element_hidden.emit(element_name)
		print("Hid UI element: ", element_name)

func _hide_all_ui():
	for element_name in ui_elements.keys():
		_hide_ui_element(element_name)

func _load_ui_element(element_name: String) -> Control:
	var scene_paths = {
		"main_menu": "res://scenes/ui/MainMenu.tscn",
		"game_ui": "res://scenes/ui/GameUI.tscn",
		"pause_menu": "res://scenes/ui/PauseMenu.tscn",
		"options_menu": "res://scenes/ui/OptionsMenu.tscn",
		"skills_menu": "res://scenes/ui/SkillsMenu.tscn",
		"game_over_screen": "res://scenes/ui/GameOverScreen.tscn",
		"loading_screen": "res://scenes/ui/LoadingScreen.tscn",
		"cards_ui": "res://scenes/ui/CardsUI.tscn",
		"teleport_selector": "res://scenes/ui/TeleportSelector.tscn",
		"enemy_turn_indicator": "res://scenes/ui/EnemyTurnIndicator.tscn"
	}
	
	if scene_paths.has(element_name):
		var scene_path = scene_paths[element_name]
		if ResourceLoader.exists(scene_path):
			var scene = load(scene_path)
			var instance = scene.instantiate()
			
			# Adicionar à árvore de cenas
			get_tree().current_scene.add_child(instance)
			
			# Conectar sinais se necessário
			_connect_ui_signals(instance, element_name)
			
			return instance
	
	print("Failed to load UI element: ", element_name)
	return null

func _connect_ui_signals(ui_element: Control, element_name: String):
	# Conectar sinais comuns de botões
	var buttons = _find_all_buttons(ui_element)
	for button in buttons:
		if not button.pressed.is_connected(_on_button_pressed):
			button.pressed.connect(_on_button_pressed.bind(button.name))

func _find_all_buttons(node: Node) -> Array:
	var buttons = []
	if node is Button:
		buttons.append(node)
	
	for child in node.get_children():
		buttons.append_array(_find_all_buttons(child))
	
	return buttons

func _on_button_pressed(button_name: String):
	button_pressed.emit(button_name)
	print("Button pressed: ", button_name)
	
	# Processar ações de botões comuns
	match button_name:
		"StartGame":
			GameStateManager.start_game()
		"ResumeGame":
			GameStateManager.resume_game()
		"PauseGame":
			GameStateManager.pause_game()
		"Options":
			GameStateManager.open_options()
		"Skills":
			GameStateManager.open_skills_menu()
		"MainMenu":
			GameStateManager.return_to_menu()
		"QuitGame":
			get_tree().quit()
		"RestartGame":
			SceneManager.reload_current_scene()

# Métodos para atualizar elementos específicos da UI
func update_health_bar(player_id: int, health: int, max_health: int):
	if ui_elements["game_ui"]:
		ui_elements["game_ui"].update_health_bar(player_id, health, max_health)

func update_power_bar(power: float, max_power: float):
	if ui_elements["game_ui"]:
		ui_elements["game_ui"].update_power_bar(power, max_power)

func update_turn_indicator(player_id: int):
	if ui_elements["game_ui"]:
		ui_elements["game_ui"].update_turn_indicator(player_id)

func update_score(player_id: int, score: int):
	if ui_elements["game_ui"]:
		ui_elements["game_ui"].update_score(player_id, score)

func update_cards_display(player_id: int, cards: Array):
	if ui_elements["game_ui"]:
		ui_elements["game_ui"].update_cards_display(player_id, cards)

func show_notification(message: String, duration: float = 3.0):
	if ui_elements["game_ui"]:
		ui_elements["game_ui"].show_notification(message, duration)

func show_damage_indicator(position: Vector2, damage: int, color: Color = Color.RED):
	# Criar indicador de dano flutuante
	var damage_label = preload("res://scenes/ui/DamageIndicator.tscn").instantiate()
	get_tree().current_scene.add_child(damage_label)
	damage_label.setup(position, str(damage), color)

func show_card_preview(card_name: String, position: Vector2):
	# Mostrar preview da carta
	var card_info = CardManager.get_card_info(card_name)
	if ui_elements["game_ui"]:
		ui_elements["game_ui"].show_card_preview(card_info, position)

func hide_card_preview():
	if ui_elements["game_ui"]:
		ui_elements["game_ui"].hide_card_preview()

func show_aim_line(start_pos: Vector2, end_pos: Vector2, color: Color = Color.RED):
	if ui_elements["game_ui"]:
		ui_elements["game_ui"].show_aim_line(start_pos, end_pos, color)

func hide_aim_line():
	if ui_elements["game_ui"]:
		ui_elements["game_ui"].hide_aim_line()

func show_trajectory_preview(points: PackedVector2Array):
	if ui_elements["game_ui"]:
		ui_elements["game_ui"].show_trajectory_preview(points)

func hide_trajectory_preview():
	if ui_elements["game_ui"]:
		ui_elements["game_ui"].hide_trajectory_preview()

func set_ui_theme(theme_name: String):
	# Aplicar tema à UI
	var theme_resource = load("res://themes/" + theme_name + ".tres")
	if theme_resource:
		for element in ui_elements.values():
			if element:
				element.theme = theme_resource

func get_current_ui_state() -> String:
	return current_ui_state

func is_ui_element_visible(element_name: String) -> bool:
	if ui_elements.has(element_name) and ui_elements[element_name]:
		return ui_elements[element_name].visible
	return false

func toggle_ui_element(element_name: String):
	if is_ui_element_visible(element_name):
		_hide_ui_element(element_name)
	else:
		_show_ui_element(element_name)

func cleanup_ui():
	for element in ui_elements.values():
		if element:
			element.queue_free()
	ui_elements.clear()
	print("UI cleaned up") 