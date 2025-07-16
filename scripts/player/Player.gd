extends CharacterBody2D

signal player_ready

func _ready():
	print("[Player] Jogador inicializado em: ", global_position)
	emit_signal("player_ready")

func _physics_process(delta):
	# O movimento é controlado pelo PlayerManager
	# Este script serve apenas para configuração inicial
	pass 