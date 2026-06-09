extends Area3D

@onready var visual = $Visual
@onready var audio = $CollectSound
@onready var collision = $CollisionShape3D

func _on_body_entered(body: Node3D) -> void:
	# Verifica se quem esbarrou foi o Player
	if body.name == "Player":
		
		GameManager.collect_gasoline()
		print("Pegou Gasolina! Total: ", GameManager.gasoline_count)
		
		audio.play()
		
		visual.visible = false
		collision.set_deferred("disabled", true)
		
		await audio.finished
		queue_free()
