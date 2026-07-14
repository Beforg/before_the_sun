extends Area3D

var was_triggered: bool = false

func _on_body_entered(body: Node3D) -> void:
	# Verifica se é o Player e se tem os galões necessários
	if not was_triggered and body.name == "Player" and GameManager.gasoline_count >= 7:
		
		was_triggered = true
		print("DIRETOR: A tempestade começou a passar...")
		var tween = get_tree().create_tween()
		tween.tween_property(GameManager, "storm_multiplier", 0.05, 45.0)
