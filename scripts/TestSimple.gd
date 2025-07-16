extends Node

func _ready():
	print("=== TESTE SIMPLES DOS MANAGERS ===")
	
	# Aguardar um frame para garantir que os managers estejam inicializados
	await get_tree().process_frame
	
	# Teste básico dos managers
	if SceneManager:
		print("✓ SceneManager OK")
	else:
		print("✗ SceneManager FALHOU")
	
	if GameManager:
		print("✓ GameManager OK")
	else:
		print("✗ GameManager FALHOU")
	
	if CatManager:
		print("✓ CatManager OK")
	else:
		print("✗ CatManager FALHOU")
	
	if PlayerManager:
		print("✓ PlayerManager OK")
	else:
		print("✗ PlayerManager FALHOU")
	
	print("=== TESTE CONCLUÍDO ===")
	
	# Remover este nó após o teste
	queue_free() 