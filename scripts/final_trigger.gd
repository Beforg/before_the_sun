extends Area3D

@export var main_menu_path: String = "res://scripts/main-menu.tscn" # IMPORTANTE: Coloque o caminho exato da sua cena de Menu aqui!

@onready var fade_rect = $CanvasLayer/ColorRect
@onready var dialogo = $DialogoFinal

var ja_ativado: bool = false

func _ready() -> void:
	# Garante que a tela comece 100% invisível
	fade_rect.modulate.a = 0.0
	
	# >>> A MÁGICA <<<
	# Dizemos para este gatilho (e o áudio dele) continuarem vivos mesmo se o jogo pausar
	process_mode = Node.PROCESS_MODE_ALWAYS

func _on_body_entered(body: Node3D) -> void:
	# Verifica se quem pisou foi o jogador (CharacterBody3D) e se já não ativou antes
	if body.name == "Player" and not ja_ativado:
		ja_ativado = true
		print("DIRETOR: O fim está próximo...")
		
		# 1. CONGELA O MUNDO INTEIRO
		# O jogador trava no lugar, a câmera para, os sons do mapa e monstros calam.
		get_tree().paused = true
		
		# 2. FADE OUT PARA O PRETO (Leva 3.5 segundos)
		var tween = create_tween()
		tween.tween_property(fade_rect, "modulate:a", 1.0, 0.5)
		
		# O código cruza os braços e espera a tela ficar 100% preta
		await tween.finished
		
		# 3. TOCA O DIÁLOGO NO ESCURO
		if dialogo.stream != null:
			dialogo.play()
			await dialogo.finished
			
		# 4. SILÊNCIO DRAMÁTICO
		# Espera 2 segundos no escuro absoluto antes de ir pro menu
		var wait_tween = create_tween()
		wait_tween.tween_interval(2.0)
		await wait_tween.finished
		
		# 5. PREPARAÇÃO PARA O MENU
		# É fundamental soltar o pause e liberar o mouse do jogador antes de trocar de cena!
		get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) 
		
		# 6. ROLA OS CRÉDITOS / VOLTA AO MENU
		get_tree().change_scene_to_file(main_menu_path)
