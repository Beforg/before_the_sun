extends Area3D

# --- CONFIGURAÇÕES DO SUSTO ---
@export var jumpscare_id: String = "vulto_corredor" # Nome único para condicionais
@export var actor: Node3D # O modelo 3D do monstro
@export var target_marker: Marker3D # O ponto de destino
@export var anim_player: AnimationPlayer # O tocador de animações do modelo
@export var run_anim_name: String = "Run" # Nome da animação
@export var run_duration: float = 1.2 # Tempo que ele leva para chegar no ponto
@export var scare_sound: AudioStreamPlayer3D 

var was_triggered: bool = false

func _ready() -> void:
	# Esconde o monstro assim que o jogo começa para o jogador não ver
	if actor:
		actor.visible = false

func _on_body_entered(body: Node3D) -> void:
	if not was_triggered and body.name == "Player":
		
		# ---------------------------------------------------
		# CONDICIONAIS CUSTOMIZADAS BASEADAS NO NOME DO SUSTO
		# ---------------------------------------------------
		match jumpscare_id:
			"vulto_casa_do_mapa":
				if !GameManager.has_map:
					return # Cancela o susto e sai da função
			"vulto_armazem":
				# Exemplo: Só aparece se o jogador estiver com a lanterna desligada
				if not GameManager.has_door_key:
					return 
			"blocked_local":
				if GameManager.has_gate_key == false:
					return
		
		# Se passou pelas regras, dispara o evento!
		was_triggered = true
		_play_jumpscare()

func _play_jumpscare() -> void:
	if scare_sound:
		scare_sound.play()
		
	if actor:
		actor.visible = true
		
		# Toca a animação (se ela existir)
		if anim_player and anim_player.has_animation(run_anim_name):
			# Pega o arquivo da animação lá dentro
			var anim = anim_player.get_animation(run_anim_name)
			# Força o modo de repetição (Loop Linear)
			anim.loop_mode = Animation.LOOP_LINEAR
			
			anim_player.play(run_anim_name)
			
		# Cria a corrida
		var tween = create_tween()
		
		# Move o monstro até a GLOBAL POSITION do marcador (Isso evita bugs de posicionamento)
		tween.tween_property(actor, "global_position", target_marker.global_position, run_duration)
		
		# MÁGICA: Assim que o movimento terminar, a Godot chama a função de desaparecer!
		tween.tween_callback(_on_jumpscare_finished)

func _on_jumpscare_finished() -> void:
	# Apaga o monstro da memória permanentemente
	if actor:
		actor.queue_free()
