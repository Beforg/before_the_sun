extends Node3D

@export var sun: DirectionalLight3D
@export var world_env: WorldEnvironment

@export var sunrise_duration: float = 60.0 

func _ready() -> void:
	_setup_night()
	
	# Aguarda 2 segundos após o início do Ato 3 para começar
	await get_tree().create_timer(2.0).timeout
	_start_sunrise()

func _setup_night() -> void:
	# Esconde o sol abaixo do horizonte
	sun.rotation_degrees = Vector3(15, -140, 0) 
	sun.light_energy = 0.0
	
	# Configura as cores da madrugada (Azul escuro/Preto)
	if world_env.environment.sky and world_env.environment.sky.sky_material:
		var sky_mat = world_env.environment.sky.sky_material
		sky_mat.sky_energy_multiplier = 0.05
		sky_mat.sky_top_color = Color(0.02, 0.02, 0.05)
		sky_mat.sky_horizon_color = Color(0.05, 0.05, 0.1)
		sky_mat.ground_horizon_color = Color(0.05, 0.05, 0.1)

func _start_sunrise() -> void:
	print("DIRETOR: O sol está nascendo!")
	
	var tween = create_tween()
	tween.set_parallel(true) # Tudo acontece ao mesmo tempo
	
	# 1. Movimento e Força da Luz
	# Gira para -25 graus (o sol fica baixo no horizonte, ótimo para sombras longas)
	tween.tween_property(sun, "rotation_degrees:x", -25.0, sunrise_duration)
	tween.tween_property(sun, "light_energy", 1.5, sunrise_duration)
	
	# 2. A cor da LUZ do sol (Isso pinta a bola do sol e a luz que bate nas árvores)
	sun.light_color = Color(1.0, 0.4, 0.0) # Começa bem Laranja
	# Vai clareando para um amarelo/branco quente
	tween.tween_property(sun, "light_color", Color(1.0, 0.9, 0.7), sunrise_duration) 
	
	# 3. Transição das cores da Abóbada Celeste
	if world_env.environment.sky and world_env.environment.sky.sky_material:
		var sky_mat = world_env.environment.sky.sky_material
		
		# Clareia a luz ambiente do mapa
		tween.tween_property(sky_mat, "sky_energy_multiplier", 1.0, sunrise_duration)
		
		# Transita para as cores da manhã!
		# Topo do céu fica azul claro
		tween.tween_property(sky_mat, "sky_top_color", Color(0.3, 0.5, 0.7), sunrise_duration) 
		# O horizonte vira um Laranja/Dourado vibrante
		tween.tween_property(sky_mat, "sky_horizon_color", Color(0.9, 0.4, 0.1), sunrise_duration) 
		# O horizonte do chão acompanha a cor
		tween.tween_property(sky_mat, "ground_horizon_color", Color(0.9, 0.4, 0.1), sunrise_duration)
