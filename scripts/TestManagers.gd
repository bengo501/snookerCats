extends Node

func _ready():
	# Aguardar um frame para garantir que os managers estejam inicializados
	await get_tree().process_frame
	
	print("=== TESTE DOS MANAGERS ===")
	test_managers()
	
func test_managers():
	# Teste do SceneManager
	print("\n--- Teste SceneManager ---")
	if SceneManager:
		print("✓ SceneManager encontrado")
		print("Cena atual: ", SceneManager.get_current_scene_name())
	else:
		print("✗ SceneManager não encontrado")
	
	# Teste do GameManager
	print("\n--- Teste GameManager ---")
	if GameManager:
		print("✓ GameManager encontrado")
		print("Estado atual: ", GameManager.GameState.keys()[GameManager.get_current_state()])
		print("Jogador atual: ", GameManager.get_current_player())
		
		# Não mudar o estado, deixar em AIMING
		print("Estado mantido em: ", GameManager.GameState.keys()[GameManager.get_current_state()])
	else:
		print("✗ GameManager não encontrado")
	
	# Teste do CatManager
	print("\n--- Teste CatManager ---")
	if CatManager:
		print("✓ CatManager encontrado")
		print("Número de jogadores: ", CatManager.get_player_count())
		
		# Teste dos jogadores
		var player1 = CatManager.get_player(1)
		if player1:
			print("Jogador 1: ", player1.name, " (", CatManager.CatType.keys()[player1.cat_type], ")")
			print("  Nível: ", player1.level, " | Precisão: ", player1.accuracy)
		
		var player2 = CatManager.get_player(2)
		if player2:
			print("Jogador 2: ", player2.name, " (", CatManager.CatType.keys()[player2.cat_type], ")")
			print("  Nível: ", player2.level, " | Precisão: ", player2.accuracy)
		
		# Teste de modificadores
		print("Modificador de precisão J1: ", CatManager.get_player_accuracy_modifier(1))
		print("Modificador de força J1: ", CatManager.get_player_power_modifier(1))
	else:
		print("✗ CatManager não encontrado")
	
	print("\n=== TESTE CONCLUÍDO ===") 