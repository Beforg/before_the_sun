extends Area3D

@onready var visual = $Battery
@onready var audio = $CollectSound
@onready var collision = $CollisionShape3D


func _on_body_entered(body: Node3D) -> void:
	# Verifica se quem esbarrou foi o Player
	if body.name == "Player":
		
		# 1. Avisa o Cérebro (GameManager)
		GameManager.collect_torch_refill()
		print("Pegou Bateria: ", GameManager.torch_refills)
		
		# 2. Toca o som espacial de coleta
		audio.play()
		
		# 3. Fica invisível e intocável imediatamente para não ser pego duas vezes
		visual.visible = false
		collision.set_deferred("disabled", true)
		
		# 4. A MÁGICA: Espera o som terminar antes de se autodestruir!
		await audio.finished
		queue_free()
