extends Area3D

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func _on_body_entered(body: Node3D) -> void:
	# Verifica se quem pisou na área foi realmente o jogador
	if body.name == "Player":
		print("Iniciando o Ato 2...")
		LoadingScreen.load_scene("res://scripts/act2.tscn")
