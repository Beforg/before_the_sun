extends MeshInstance3D

# Função gerada automaticamente pelo sinal
func _on_area_3d_body_entered(body: Node3D) -> void:
	# Verifica se quem caiu na água foi o Player
	# (Verifique se o nome do seu nó principal do jogador é exatamente "Player" com P maiúsculo)
	if body.name == "Player":
		print("O jogador morreu afogado!")
		GameManager.reset_game()
		get_tree().change_scene_to_file("res://game_over_screen.tscn")
