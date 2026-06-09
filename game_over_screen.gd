extends Control

func _ready() -> void:
	# O Autoplay do AudioStreamPlayer já vai fazer o som tocar na hora!
	
	# Garante que o GameManager zere todos os status (galões, vício, terror, etc.)
	GameManager.reset_game()
	
	# Deixa a tela de Game Over aparecendo por 4 segundos
	await get_tree().create_timer(4.0).timeout
	
	# Volta para a tela inicial do jogo
	get_tree().change_scene_to_file("res://main-menu.tscn")
