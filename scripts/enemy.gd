extends CharacterBody3D

enum State { HIDDEN, STALKING, HUNTING, FAKE_CHARGE, OBSERVING, INVESTIGATING, INTRO_WALK }
var current_state: State = State.HIDDEN
var is_active: bool = false 

@onready var nav_agent = $NavAgent
@onready var pivot = $Pivot
@onready var anim_player = $Pivot/enemy/AnimationPlayer 
@onready var terror_aura = $TerrorAura
@export var player: Node3D

# --- NOVA VARIÁVEL: Ponto para onde ele vai andar na introdução ---
@export var intro_walk_target: Node3D 

# Configurações de Velocidade e Movimento
@export var stalk_speed: float = 2.2 
@export var hunt_speed: float = 4.6
@export var base_light_energy: float = 7.0

# --- VARIÁVEIS DE COMPORTAMENTO ---
var circle_direction: int = 1 
var stalk_offset_target := Vector3.ZERO
var stalk_timer := 0.0
var stalk_update_rate := 3.5 
var is_stunned_by_light := false
var stun_timer := 0.0
var is_performing_action := false 

# --- VARIÁVEIS DE INVESTIGAÇÃO, MEMÓRIA E ATAQUE ---
var fake_charge_cooldown := 0.0
var escape_grace_period := 0.0 
var grab_cooldown := 0.0
var last_known_pos := Vector3.ZERO
var observe_timer := 0.0

func _ready() -> void:
	GameManager.monster_awakened.connect(_on_monster_awakened)
	GameManager.difficulty_increased.connect(_on_difficulty_increased)
	randomize()
	
	is_active = false 
	visible = true 
	
	anim_player.play("mixamo_com_005")

func _physics_process(delta: float) -> void:
	# 1. GRAVIDADE SEMPRE ATIVA (Impede o Limbo)
	if not is_on_floor():
		velocity.y -= 9.8 * delta
		
	# 2. SE ESTÁ FAZENDO UMA AÇÃO (Girando, Atacando):
	if is_performing_action:
		velocity.x = 0 
		velocity.z = 0
		move_and_slide()
		return
		
	# 3. SE ESTÁ DORMINDO (Esperando o Galão):
	if not is_active:
		# CASO 1: Jogador chegou muito perto do monstro adormecido!
		if player != null and global_position.distance_to(player.global_position) < 4.0:
			_punish_early_wakeup()
		else:
			velocity.x = 0 
			velocity.z = 0
			move_and_slide() 
		return
		
	# Reduz os timers
	if fake_charge_cooldown > 0.0: fake_charge_cooldown -= delta
	if escape_grace_period > 0.0: escape_grace_period -= delta
	if grab_cooldown > 0.0: grab_cooldown -= delta
	if observe_timer > 0.0: observe_timer -= delta
	
	if player != null and player.get("torch") != null and player.get("camera") != null:
		var light = player.torch.light_energy
		var distance = global_position.distance_to(player.global_position)
		
		# --- 1. O SISTEMA DE ATAQUE (LETAL VS NÃO LETAL) ---
		if distance <= 3.2 and current_state != State.FAKE_CHARGE:
			
			if current_state == State.INTRO_WALK:
				# A CORREÇÃO: Aumentamos o gatilho para 2.8 metros! 
				# Isso garante que ele te mate ANTES da cápsula de colisão física travar o movimento.
				if distance <= 2.8: 
					print("DIRETOR: Jogador entrou na frente do monstro caminhando! Punição letal.")
					GameManager.terror_level = 100.0 # Garante a morte
					_execute_lethal_attack()
					return 
			else:
				# COMPORTAMENTO NORMAL (Fora da cena de introdução)
				if GameManager.terror_level >= 80.0:
					_execute_lethal_attack()
					return
				elif grab_cooldown <= 0.0:
					_execute_non_lethal_grab()
					return
		
		# --- 2. GERENCIAMENTO DE STUN (SUSTO NA LUZ) ---
		if is_stunned_by_light:
			anim_player.play("mixamo_com_005")
			stun_timer -= delta
			
			velocity.x = move_toward(velocity.x, 0, stalk_speed * 4.0 * delta)
			velocity.z = move_toward(velocity.z, 0, stalk_speed * 4.0 * delta)
			move_and_slide()
			
			if stun_timer <= 0.0:
				is_stunned_by_light = false
				current_state = State.HIDDEN 
			return

		# --- 3. MÁGICA DA VISÃO E MEMÓRIA ---
		var player_forward = -player.camera.global_transform.basis.z.normalized()
		var dir_to_monster = player.global_position.direction_to(global_position).normalized()
		
		var has_los = _has_line_of_sight()
		var is_looking_angle = player_forward.dot(dir_to_monster) > 0.70
		var is_player_looking = is_looking_angle and has_los
		
		if has_los and light > 1.0:
			last_known_pos = player.global_position
		
		# --- 4. MÁQUINA DE ESTADOS DINÂMICA ---
		_update_monster_state(light, distance, is_player_looking, has_los)
		
		# --- 5. EXECUÇÃO DOS COMPORTAMENTOS ---
		match current_state:
			State.HIDDEN: _process_hidden_behavior(delta)
			State.STALKING: _process_stalking_behavior(delta, is_player_looking, distance)
			State.HUNTING: _process_hunting_behavior(delta, distance)
			State.FAKE_CHARGE: _process_fake_charge_behavior(delta, distance)
			State.OBSERVING: _process_observing_behavior(delta, is_player_looking)
			State.INVESTIGATING: _process_investigating_behavior(delta)
			State.INTRO_WALK: _process_intro_walk_behavior(delta)
					
	# Lógica da Aura de Terror
	_process_terror_aura(delta)

# --- AÇÕES DE PUNIÇÃO E EVENTOS ---

func _punish_early_wakeup() -> void:
	is_active = true
	is_performing_action = true 
	
	print("DIRETOR: O jogador foi curioso e acordou o monstro cedo! Morte iminente.")
	anim_player.play("mixamo_com_009") 
	
	await anim_player.animation_finished
	
	GameManager.terror_level = 100.0
	hunt_speed *= 1.5 
	
	is_performing_action = false
	current_state = State.HUNTING 

func _execute_lethal_attack() -> void:
	is_performing_action = true
	anim_player.play("mixamo_com_010") 
	velocity = Vector3.ZERO 
	print("Game Over 3D: Ataque Letal!")
	
	await get_tree().create_timer(1.2).timeout 
	GameManager.reset_game()
	get_tree().change_scene_to_file("res://scripts/game_over_screen.tscn")

func _execute_non_lethal_grab() -> void:
	is_performing_action = true
	anim_player.play("mixamo_com_010") 
	velocity = Vector3.ZERO 
	print("GRAB! Monstro feriu a mente do jogador e fugiu.")
	
	GameManager.terror_level = min(100.0, GameManager.terror_level + 50.0)
	
	await get_tree().create_timer(1.0).timeout 
	
	grab_cooldown = 45.0 
	teleport_to_flank_position()
	current_state = State.STALKING
	is_performing_action = false

# --- FUNÇÃO DE TRANSIÇÃO DE ESTADOS ORGÂNICA ---
func _update_monster_state(light: float, distance: float, is_player_looking: bool, has_los: bool) -> void:
	if current_state == State.FAKE_CHARGE or current_state == State.OBSERVING or current_state == State.INTRO_WALK:
		return
	# NOVA REGRA: SISTEMA DE "RUBBER BANDING" (Corda Elástica)
	# Nunca deixa o jogador ficar em paz. Se ele fugir para muito longe
	# e não estiver olhando, o monstro reseta a posição ao redor dele!
	if distance > 28.0 and not is_player_looking:
		teleport_to_flank_position()
		current_state = State.STALKING
		return
	
	if not has_los and light < 2.0 and last_known_pos != Vector3.ZERO:
		current_state = State.INVESTIGATING
		return
	
	if (current_state == State.HIDDEN or current_state == State.STALKING) and is_player_looking and distance < 12.0 and escape_grace_period <= 0.0:
		current_state = State.HUNTING
		GameManager.terror_level = 100.0 
		return

	if current_state == State.STALKING and distance > 16.0 and fake_charge_cooldown <= 0.0:
		if randf() < 0.004: 
			current_state = State.FAKE_CHARGE
			fake_charge_cooldown = 25.0 
			return
			
	if current_state == State.STALKING and distance > 18.0 and observe_timer <= 0.0:
		if randf() < 0.003: 
			current_state = State.OBSERVING
			observe_timer = randf_range(4.0, 7.0)
			return

	var is_furious = (current_state == State.HUNTING and GameManager.terror_level > 80.0)
	if GameManager.terror_level >= 95.0 or is_furious:
		current_state = State.HUNTING
		return
		
	if current_state == State.STALKING and is_player_looking and light > 4.0 and not is_stunned_by_light:
		if randf() < 0.005: 
			is_stunned_by_light = true
			stun_timer = 1.5 
			return

	if light > 5.5 and distance < 15.0 and is_player_looking:
		current_state = State.HIDDEN
	elif light > 2.0:
		current_state = State.STALKING
	else:
		current_state = State.HUNTING

# --- COMPORTAMENTOS ESPECÍFICOS ---

func _process_intro_walk_behavior(delta: float) -> void:
	anim_player.play("mixamo_com_008", -1, 1.0) 
	pivot.visible = true
	
	if intro_walk_target == null:
		current_state = State.STALKING
		return
		
	nav_agent.target_position = intro_walk_target.global_position
	var next_path_pos = nav_agent.get_next_path_position()
	var dir = global_position.direction_to(next_path_pos).normalized()
	dir.y = 0
	
	var intro_speed = stalk_speed * 0.8 
	
	velocity.x = dir.x * intro_speed 
	velocity.z = dir.z * intro_speed
	
	_look_at_target(intro_walk_target.global_position)
	
	move_and_slide()
	
	var pos_2d = Vector2(global_position.x, global_position.z)
	var target_2d = Vector2(intro_walk_target.global_position.x, intro_walk_target.global_position.z)
	
	if pos_2d.distance_to(target_2d) < 2.5:
		print("DIRETOR: Caminhada concluída. O monstro chegou no ponto e a caçada normal começou!")
		current_state = State.STALKING

func _process_observing_behavior(delta: float, is_player_looking: bool) -> void:
	anim_player.play("mixamo_com_005") 
	pivot.visible = true
	
	velocity = Vector3.ZERO
	_look_at_target(player.global_position)
	
	if is_player_looking and observe_timer < 3.0:
		print("Comportamento Raro: O monstro se sentiu observado e recuou!")
		current_state = State.HIDDEN
		observe_timer = 0.0
		return
		
	if observe_timer <= 0.0:
		current_state = State.STALKING

func _process_investigating_behavior(delta: float) -> void:
	anim_player.play("mixamo_com_008") 
	pivot.visible = true
	
	var distance_to_memory = global_position.distance_to(last_known_pos)
	
	if distance_to_memory < 2.0:
		velocity = Vector3.ZERO
		anim_player.play("mixamo_com_005") 
		
		if randf() < 0.01: 
			last_known_pos = Vector3.ZERO
			current_state = State.STALKING
		return
	
	nav_agent.target_position = last_known_pos
	var next_path_pos = nav_agent.get_next_path_position()
	var dir = global_position.direction_to(next_path_pos).normalized()
	dir.y = 0
	
	velocity.x = dir.x * (stalk_speed * 0.8)
	velocity.z = dir.z * (stalk_speed * 0.8)
	
	_look_at_target(last_known_pos)
	move_and_slide()

func _process_hidden_behavior(delta: float) -> void:
	anim_player.play("mixamo_com_008")
	pivot.visible = true
	
	var escape_dir = player.global_position.direction_to(global_position)
	escape_dir.y = 0
	escape_dir = escape_dir.normalized()
	
	var flee_speed = hunt_speed * 1.5
	velocity.x = escape_dir.x * flee_speed
	velocity.z = escape_dir.z * flee_speed
	
	_look_at_target(global_position + escape_dir)
	move_and_slide()
	
	var distance = global_position.distance_to(player.global_position)
	if distance > 20.0:
		teleport_to_flank_position()
		current_state = State.STALKING

func _process_stalking_behavior(delta: float, is_player_looking: bool, distance: float) -> void:
	anim_player.play("mixamo_com_008")
	pivot.visible = true
	
	stalk_timer += delta
	if stalk_timer >= stalk_update_rate or stalk_offset_target == Vector3.ZERO:
		stalk_timer = 0.0
		var angle_offset = randf_range(PI/3, PI * 1.5) 
		if randf() < 0.5: angle_offset *= -1
		
		var player_back = player.global_transform.basis.z.normalized()
		var flank_dir = player_back.rotated(Vector3.UP, angle_offset).normalized()
		
		stalk_offset_target = player.global_position + (flank_dir * randf_range(6.0, 9.5))
	
	nav_agent.target_position = stalk_offset_target
	var next_path_pos = nav_agent.get_next_path_position()
	var dir = global_position.direction_to(next_path_pos).normalized()
	dir.y = 0
	
	var current_speed = stalk_speed
	if is_player_looking: current_speed *= 0.4 
	
	velocity.x = dir.x * current_speed
	velocity.z = dir.z * current_speed
	
	_look_at_target(player.global_position)
	move_and_slide()

func _process_hunting_behavior(delta: float, distance: float) -> void:
	anim_player.play("mixamo_com_007")
	pivot.visible = true
	
	var player_forward = -player.camera.global_transform.basis.z.normalized()
	var dir_to_monster = player.global_position.direction_to(global_position).normalized()
	
	var is_looking_angle = player_forward.dot(dir_to_monster) > 0.4
	var is_player_looking_now = is_looking_angle and _has_line_of_sight()
	
	if distance > 20.0 and not is_player_looking_now:
		teleport_to_flank_position()
		return
		
	nav_agent.target_position = player.global_position
	var next_path_pos = nav_agent.get_next_path_position()
	var dir = global_position.direction_to(next_path_pos).normalized()
	dir.y = 0
	
	velocity.x = dir.x * hunt_speed
	velocity.z = dir.z * hunt_speed
	
	_look_at_target(player.global_position)
	move_and_slide()

func _process_fake_charge_behavior(delta: float, distance: float) -> void:
	anim_player.play("mixamo_com_007")
	pivot.visible = true
	
	if distance <= 4.8:
		GameManager.terror_level = min(100.0, GameManager.terror_level + 15.0)
		escape_grace_period = 8.0 
		current_state = State.HIDDEN
		return
		
	var dir = global_position.direction_to(player.global_position)
	dir.y = 0
	dir = dir.normalized()
	
	var sprint_speed = hunt_speed * 1.8
	velocity.x = dir.x * sprint_speed
	velocity.z = dir.z * sprint_speed
	
	_look_at_target(player.global_position)
	move_and_slide()

# --- AUXILIARES E RAYCAST ---

func _has_line_of_sight() -> bool:
	var space_state = get_world_3d().direct_space_state
	var origin = global_position + Vector3(0, 1.5, 0)
	var target = player.global_position + Vector3(0, 1.5, 0)
	
	var query = PhysicsRayQueryParameters3D.create(origin, target)
	query.exclude = [self.get_rid()] 
	
	var result = space_state.intersect_ray(query)
	if result and result.collider == player:
		return true
	return false

func _look_at_target(target_pos: Vector3) -> void:
	var look_pos = target_pos
	look_pos.y = global_position.y 
	if global_position.distance_to(look_pos) > 0.1:
		pivot.look_at(look_pos, Vector3.UP)

func teleport_to_flank_position() -> void:
	var desired_pos = Vector3.ZERO
	var random_choice = randf()
	
	# Usamos a câmera como referência para saber exatamente para onde o jogador está olhando
	var cam_basis = player.camera.global_transform.basis
	
	if random_choice < 0.20:
		# 20% DE CHANCE: FRENTE (Muito longe e ligeiramente para os lados)
		var player_forward = -cam_basis.z.normalized()
		var angle_offset = randf_range(PI/8, PI/4) # Desvia a rota para não nascer no centro da tela
		if randf() > 0.5: angle_offset *= -1
		
		var spawn_dir = player_forward.rotated(Vector3.UP, angle_offset).normalized()
		desired_pos = player.global_position + (spawn_dir * randf_range(18.0, 24.0))
		
	elif random_choice < 0.60:
		# 40% DE CHANCE: FLANCOS LATERAIS (Esquerda ou Direita)
		var player_right = cam_basis.x.normalized()
		var side_dir = player_right if randf() > 0.5 else -player_right # Escolhe um dos lados
		
		var angle_variation = randf_range(-PI/6, PI/6) # Dá uma leve angulada para frente ou para trás
		var spawn_dir = side_dir.rotated(Vector3.UP, angle_variation).normalized()
		desired_pos = player.global_position + (spawn_dir * randf_range(12.0, 16.0))
		
	else:
		# 40% DE CHANCE: COSTAS (Perto para pressão imediata)
		var player_back = cam_basis.z.normalized()
		var angle_variation = randf_range(-PI/3, PI/3)
		var spawn_dir = player_back.rotated(Vector3.UP, angle_variation).normalized()
		desired_pos = player.global_position + (spawn_dir * randf_range(9.0, 14.0))
		
	# Nasce acima do jogador para cair no chão e não dentro do morro
	desired_pos.y = player.global_position.y + 3.0 
	
	var map = get_world_3d().get_navigation_map()
	var safe_pos = NavigationServer3D.map_get_closest_point(map, desired_pos)
	
	if safe_pos != Vector3.ZERO:
		global_position = safe_pos
	else:
		global_position = desired_pos
		
	stalk_offset_target = Vector3.ZERO
func _process_terror_aura(delta: float) -> void:
	var bodies = terror_aura.get_overlapping_bodies()
	for body in bodies:
		if body.name == "Player":
			var dist = global_position.distance_to(body.global_position)
			var intensity = remap(dist, 25.0, 0.0, 4.0, 22.0)
			GameManager.increase_terror(intensity * delta)

func _on_monster_awakened() -> void:
	if is_active:
		return
		
	is_active = true
	is_performing_action = true 
	
	visible = true 
	
	print("DIRETOR: Monstro acordou! Tocando animação de virar...")
	anim_player.play("mixamo_com_009")
	
	await anim_player.animation_finished
	
	is_performing_action = false
	
	if intro_walk_target != null:
		current_state = State.INTRO_WALK
		print("DIRETOR: Ponto de destino encontrado. Iniciando caminhada lenta.")
	else:
		teleport_to_flank_position()
		current_state = State.STALKING

func _on_difficulty_increased(level: int) -> void:
	if level == 1:
		stalk_speed += 0.4
		stalk_update_rate = 2.5 
	elif level == 2:
		stalk_speed += 0.3  
		hunt_speed += 1.2
