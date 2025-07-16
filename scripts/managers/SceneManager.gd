extends Node

signal scene_changed(scene_name: String)
signal scene_loaded(scene_name: String)

enum SceneType {
	MENU,
	GAME,
	PAUSE,
	GAME_OVER,
	SETTINGS
}

var current_scene: Node
var current_scene_name: String = ""
var scene_paths = {
	SceneType.MENU: "res://scenes/ui/Menu.tscn",
	SceneType.GAME: "res://scenes/main/Main.tscn",
	SceneType.PAUSE: "res://scenes/ui/Pause.tscn",
	SceneType.GAME_OVER: "res://scenes/ui/GameOver.tscn",
	SceneType.SETTINGS: "res://scenes/ui/Settings.tscn"
}

func _ready():
	# Garantir que o SceneManager seja um singleton
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Aguardar um frame para garantir que a árvore de cena esteja pronta
	await get_tree().process_frame
	
	# Inicializar a cena atual
	current_scene = get_tree().current_scene
	if current_scene:
		current_scene_name = current_scene.name
		print("SceneManager: Cena atual inicializada: ", current_scene_name)
	else:
		print("SceneManager: Nenhuma cena atual encontrada")

func change_scene(scene_type: SceneType, transition: bool = false):
	var scene_path = scene_paths.get(scene_type, "")
	if scene_path.is_empty():
		print("ERRO: Caminho da cena não encontrado para: ", scene_type)
		return
	
	print("Mudando para cena: ", scene_type)
	scene_changed.emit(SceneType.keys()[scene_type])
	
	if transition:
		# Aqui você pode adicionar transições visuais
		await _fade_out()
	
	# Carregar a nova cena
	var scene_resource = load(scene_path)
	if scene_resource:
		var new_scene = scene_resource.instantiate()
		get_tree().current_scene.queue_free()
		get_tree().current_scene = new_scene
		get_tree().root.add_child(new_scene)
		
		current_scene = new_scene
		current_scene_name = SceneType.keys()[scene_type]
		
		if transition:
			await _fade_in()
		
		scene_loaded.emit(current_scene_name)
		print("Cena carregada com sucesso: ", current_scene_name)
	else:
		print("ERRO: Não foi possível carregar a cena: ", scene_path)

func reload_current_scene():
	if current_scene_name.is_empty():
		print("ERRO: Nenhuma cena atual para recarregar")
		return
	
	print("Recarregando cena atual: ", current_scene_name)
	var scene_type = _get_scene_type_from_name(current_scene_name)
	if scene_type != -1:
		change_scene(scene_type)

func get_current_scene() -> Node:
	return current_scene

func get_current_scene_name() -> String:
	return current_scene_name



func _get_scene_type_from_name(scene_name: String) -> int:
	for scene_type in SceneType.values():
		if SceneType.keys()[scene_type] == scene_name:
			return scene_type
	return -1

# Funções para transições visuais (pode ser expandido)
func _fade_out():
	# Implementar fade out
	await get_tree().create_timer(0.5).timeout

func _fade_in():
	# Implementar fade in
	await get_tree().create_timer(0.5).timeout

# Função para adicionar novas cenas dinamicamente
func add_scene_path(scene_type: SceneType, path: String):
	scene_paths[scene_type] = path
	print("Novo caminho de cena adicionado: ", scene_type, " -> ", path) 
