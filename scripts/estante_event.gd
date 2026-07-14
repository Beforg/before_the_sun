extends Area3D

@export var estante_alvo: Node3D 
@export var som_jumpscare: AudioStreamPlayer3D 

var ja_assustou: bool = false

func _on_body_entered(body: Node3D) -> void:
	if not ja_assustou and body.name == "Player":
		ja_assustou = true
		
		# Toca o som de susto imediatamente (se houver)
		if som_jumpscare:
			som_jumpscare.play()
			
		if estante_alvo:
			# Cria a animação de queda
			var tween = create_tween()
			
			# Define uma transição "Bounce" (Quique) ou "Elastic" para a estante bater no chão e tremer
			tween.set_trans(Tween.TRANS_BOUNCE)
			tween.set_ease(Tween.EASE_OUT)
			
			# Faz a estante girar 90 graus (tombando para a frente). 
			# OBS: Dependendo de qual lado a sua estante está virada, pode ser "rotation_degrees:x" ou "z" ou "-90".
			# Teste o eixo de rotação correto manualmente no Inspector antes!
			tween.tween_property(estante_alvo, "rotation_degrees:x", 90.0, 1.0)
