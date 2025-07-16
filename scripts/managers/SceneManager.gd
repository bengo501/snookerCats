extends Node

signal scene_changed(scene_name: String)
signal scene_loading_started
signal scene_loading_finished

var current_scene: Node = null
var loading_thread: Thread
var is_loading: bool = false

func _ready():
	# Definir como singleton
	set_process(false)
	current_scene = get_tree().current_scene

func change_scene(scene_path: String, with_transition: bool = true):
	if is_loading:
		print("Already loading a scene, please wait...")
		return
	
	print("Changing scene to: ", scene_path)
	
	if with_transition:
		await show_loading_screen()
	
	_load_scene(scene_path)

func _load_scene(scene_path: String):
	is_loading = true
	scene_loading_started.emit()
	
	# Remover cena atual
	if current_scene:
		current_scene.queue_free()
		current_scene = null
	
	# Carregar nova cena
	var new_scene = load(scene_path)
	if new_scene:
		current_scene = new_scene.instantiate()
		get_tree().root.add_child(current_scene)
		get_tree().current_scene = current_scene
		
		print("Scene loaded successfully: ", scene_path)
		scene_changed.emit(scene_path)
	else:
		print("Failed to load scene: ", scene_path)
	
	is_loading = false
	scene_loading_finished.emit()
	
	await hide_loading_screen()

func show_loading_screen():
	# Aqui você pode adicionar uma tela de carregamento
	UIManager.show_loading_screen()
	await get_tree().create_timer(0.5).timeout

func hide_loading_screen():
	UIManager.hide_loading_screen()
	await get_tree().create_timer(0.2).timeout

func reload_current_scene():
	if current_scene:
		var scene_path = current_scene.scene_file_path
		change_scene(scene_path)

func get_current_scene() -> Node:
	return current_scene

func get_current_scene_name() -> String:
	if current_scene:
		return current_scene.name
	return ""

# Métodos de conveniência para cenas específicas
func go_to_main_menu():
	change_scene("res://scenes/ui/MainMenu.tscn")

func go_to_game():
	change_scene("res://scenes/main/Main.tscn")

func go_to_options():
	change_scene("res://scenes/ui/Options.tscn")

func go_to_shop():
	change_scene("res://scenes/ui/Shop.tscn") 