extends CharacterBody3D

@export var lanterna_luz: SpotLight3D
@export var walk_speed: float = 20.1
@export var mouse_sensitivity: float = 0.003
@onready var camera = $Camera3D
@onready var hand = $Camera3D/Hand
@onready var interact_ray = $Camera3D/InteractRay
var current_interactable: Node3D = null
# -- Configurações de Câmera (Smoothing) --
var camera_smoothing := 13.0 # Menor = câmera mais "pesada/arrastada"
var target_cam_rotation := Vector2.ZERO 

# -- Configurações do Braço (Sway) --
var sway_amount := 0.001
var sway_smoothing := 8.0
var mouse_delta := Vector2.ZERO
var hand_initial_rotation := Vector3.ZERO
var hand_initial_position := Vector3.ZERO # Salva o centro da mão para o balanço
var is_intro_playing: bool = true # Começa travado
# --- VARIÁVEIS DO HEAD BOBBING ---
var bob_freq: float = 2.3 # Frequência base
@export var bob_amp: float = 0.08 
var t_bob: float = 0.0
var base_camera_pos: Vector3 
var light_drain_rate: float = 0.0095
var light_drain_rate_combat = 0.035

@onready var torch = $Camera3D/SpotLight3D # Sua nova lanterna 3D!
@onready var heart_low = $HeartbeatLow
@onready var heart_high = $HeartbeatHight
@onready var som_passos = $SomPassos

var passo_tocado = false
# Variável de velocidade atual
var speed: float = 5.0 

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hand_initial_rotation = hand.rotation
	hand_initial_position = hand.position # Inicializa a posição base da mão
	target_cam_rotation.y = rotation.y
	target_cam_rotation.x = camera.rotation.x
	base_camera_pos = camera.position 
	GameManager.difficulty_increased.connect(_on_difficulty_increased)
	interact_ray.add_exception(self)
	_setup_intro_fade()
func _input(event: InputEvent) -> void:
	if is_intro_playing: 
		return
	var item_sound = $UseItem
	
	if event.is_action_pressed("toggle_flashlight"):
		GameManager.is_flashlight_on = not GameManager.is_flashlight_on
		
		# Liga ou desliga visualmente a luz
		if lanterna_luz:
			lanterna_luz.visible = GameManager.is_flashlight_on
			
		# Tocar um som de "Click" aqui
	if event.is_action_pressed("interagir"):
		if current_interactable:
			current_interactable.interact()
	# CORRIGIDO: Removido o segundo bloco que rotacionava o player instantaneamente
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			mouse_delta = event.relative
			target_cam_rotation.y -= event.relative.x * mouse_sensitivity
			target_cam_rotation.x -= event.relative.y * mouse_sensitivity
			target_cam_rotation.x = clamp(target_cam_rotation.x, deg_to_rad(-80), deg_to_rad(80))
		
		
	if event.is_action_pressed("usar_cura"):
		if GameManager.cures_count > 0:
			GameManager.cures_count -= 1
			GameManager.terror_level = 0
			item_sound.play()
			GameManager.is_addicted = false # Remove o vício
			GameManager.adrenaline_use_history = []
			print("Você usou a cura! Estado normalizado.")
		else:
			print("Você não tem curas!")

	# USAR ADRENALINA (Tecla Q)
	if event.is_action_pressed("usar_adrenalina"):
		if GameManager.try_use_adrenaline():
			GameManager.terror_level = max(0.0, GameManager.terror_level - 30.0)
			item_sound.play()
			print("PLAYER 3D: Adrenalina injetada!")
			
	if event.is_action_pressed("usar_tocha"):
		if GameManager.torch_refills > 0:
			item_sound.play()
			GameManager.torch_refills -= 1
			torch.light_energy = clamp(torch.light_energy + 2.25, 0.2, 9.99)
			torch.spot_range = clamp(torch.spot_range + 4.5, 3, 20)
			print("Tocha recarregada!")
			
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta: float) -> void:
	_update_heartbeat_audio()
	_check_interaction()
	# --- 1. GESTÃO DE VELOCIDADE E ESTADOS ---
	if GameManager.is_adrenaline_active:
		if GameManager.is_addicted:
			speed = walk_speed * 1.15 # Bônus viciado
			bob_freq = 2.4 # Passos um pouco mais rápidos
		else:
			speed = walk_speed * 1.24 # Corrida desesperada
			bob_freq = 1.8 # Câmera balança muito rápido!
			camera.fov = lerp(camera.fov, 85.0, delta * 3.0)
	elif GameManager.terror_level >= 50.0:
		speed = walk_speed * 0.8 # Lento por pânico
		bob_freq = 1.5 # Passos pesados e arrastados
	else:
		speed = walk_speed # Normal
		bob_freq = 2.4 # Ritmo normal
		camera.fov = lerp(camera.fov, 75.0, delta * 3.0)
		
	# --- 2. DRENO DA LANTERNA ---
	if torch.light_energy > 0.2:
		if GameManager.gasoline_count > 0 and GameManager.is_flashlight_on:
			torch.light_energy -= light_drain_rate_combat * delta
			torch.spot_range -= (light_drain_rate_combat * 2.05) * delta
		elif GameManager.is_flashlight_on:
			torch.light_energy -= light_drain_rate * delta
			torch.spot_range -= (light_drain_rate * 2.05) * delta

	# --- 3. FÍSICA E MOVIMENTO ---
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	var input_dir = Vector2.ZERO
	if is_intro_playing:
		input_dir = Vector2(0, -1) # Força o analógico para a frente!
		speed = walk_speed * 0.35 # Caminhada mais lenta e dramática
	else:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

	# --- 4. GATILHO DE TIMING DO HEAD BOBBING (Movimentação Física) ---
	if is_on_floor() and direction != Vector3.ZERO:
		t_bob += delta * velocity.length() 
		var pure_sin = sin(t_bob * bob_freq)
		
		# --- GATILHO DO ÁUDIO DOS PASSOS ---
		if pure_sin < -0.8 and not passo_tocado:
			tocar_passo()
			passo_tocado = true
		elif pure_sin > -0.5:
			passo_tocado = false
	else:
		t_bob = 0.0
		passo_tocado = false

func _process(delta: float) -> void:
	# ==========================================
	# 1. CAMERA SMOOTHING (Arrasto do Pescoço)
	# ==========================================
	rotation.y = lerp_angle(rotation.y, target_cam_rotation.y, camera_smoothing * delta)
	camera.rotation.x = lerp_angle(camera.rotation.x, target_cam_rotation.x, camera_smoothing * delta)

	# ==========================================
	# 2. HEAD BOBBING VISUAL (Aplicado no frame de renderização)
	# ==========================================
	var horizontal_velocity = Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and horizontal_velocity > 0.1:
		var pure_sin = sin(t_bob * bob_freq)
		var bob_y = pure_sin * bob_amp
		var bob_x = cos(t_bob * bob_freq / 2.0) * bob_amp
		
		camera.position = base_camera_pos + Vector3(bob_x, bob_y, 0)
		
		# Faz a mão acompanhar sutilmente o balanço do corpo para dar peso extra
		var hand_bob_y = hand_initial_position.y + (pure_sin * (bob_amp * 0.2))
		var hand_bob_x = hand_initial_position.x + (cos(t_bob * bob_freq / 2.0) * (bob_amp * 0.1))
		hand.position = hand.position.lerp(Vector3(hand_bob_x, hand_bob_y, hand_initial_position.z), delta * 12.0)
	else:
		camera.position.y = lerp(camera.position.y, base_camera_pos.y, delta * 10.0)
		camera.position.x = lerp(camera.position.x, base_camera_pos.x, delta * 10.0)
		hand.position = hand.position.lerp(hand_initial_position, delta * 10.0)

	# ==========================================
	# 3. WEAPON SWAY (Arrasto Lateral do Braço)
	# ==========================================
	var target_sway_x = hand_initial_rotation.x + (mouse_delta.y * sway_amount)
	var target_sway_y = hand_initial_rotation.y + (mouse_delta.x * sway_amount)

	hand.rotation.x = lerp_angle(hand.rotation.x, target_sway_x, sway_smoothing * delta)
	hand.rotation.y = lerp_angle(hand.rotation.y, target_sway_y, sway_smoothing * delta)

	# Reduz progressivamente o delta do mouse acumulado
	mouse_delta = mouse_delta.lerp(Vector2.ZERO, sway_smoothing * delta)

func _update_heartbeat_audio():
	var level = GameManager.terror_level
	if level >= 50:
		if not heart_high.playing:
			heart_high.play()
			heart_low.stop()
	elif level >= 25:
		if not heart_low.playing:
			heart_low.play()
			heart_high.stop()
	else:
		if heart_low.playing: heart_low.stop()
		if heart_high.playing: heart_high.stop()

func _on_difficulty_increased(level: int) -> void:
	if level == 1:
		light_drain_rate = 0.13 
		print("PLAYER: A bateria está gastando mais rápido (Nível 1)")
	elif level == 2:
		light_drain_rate = 0.15 
		print("PLAYER: A luz enfraqueceu e o cone fechou! (Nível 2)")

func tocar_passo() -> void:
	som_passos.pitch_scale = randf_range(0.85, 1.15)
	som_passos.volume_db = randf_range(-5.0, 0.0)
	som_passos.play()

func _check_interaction() -> void:
	interact_ray.force_raycast_update()
	if interact_ray.is_colliding():
		var hit = interact_ray.get_collider()
		# Se o laser bateu em algo novo e que possui a função "interact"
		if hit != current_interactable and hit.has_method("interact"):
			print("Colidindo com item!!")
			if current_interactable:
				current_interactable.unhighlight() # Tira o brilho do antigo
				
			current_interactable = hit
			current_interactable.highlight() # Bota brilho no novo
			
	else:
		# Se o laser não está encostando em nada, remove o brilho do que estava olhando
		if current_interactable:
			current_interactable.unhighlight()
			current_interactable = null
func _setup_intro_fade() -> void:
	# 1. Cria a Tela Preta via código 
	var canvas = CanvasLayer.new()
	canvas.layer = 100 # Fica por cima da UI
	add_child(canvas)

	var fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(fade_rect)

	# 2. Anima a tela sumindo (Fade Out do preto)
	var tween = create_tween()
	tween.tween_interval(3.5) # Espera meio segundo no escuro para a engine carregar os modelos e texturas
	tween.tween_property(fade_rect, "modulate:a", 0.0, 3) # O Fade leva 2.5 segundos

	# 3. Quando a animação terminar, libera o jogador!
	tween.tween_callback(func(): 
		is_intro_playing = false
		canvas.queue_free() # Destrói a tela preta para não pesar na RAM
		print("DIRETOR: Fade terminado, jogador livre!")
	)
