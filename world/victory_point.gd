extends Area3D

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		if GameManager.gasoline_count >= 10:
			print("Vitória! Escapou da floresta.")
			get_tree().change_scene_to_file("res://win_screen.tscn")
		else:
			# Opcional: Mostrar uma mensagem no HUD dizendo "Faltam galões..."
			print("Você ainda não tem gasolina suficiente!")
