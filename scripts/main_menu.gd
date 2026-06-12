extends Control

func _ready() -> void:
	# Garante que o mouse fique visível quando o menu abrir
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)



func _on_jogar_pressed() -> void:
	get_tree().change_scene_to_file("res://world/world.tscn")


func _on_sair_pressed() -> void:
		get_tree().quit() # Fecha o jogo
