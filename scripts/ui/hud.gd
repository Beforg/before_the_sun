extends CanvasLayer

# --- REFERÊNCIAS DA UI ---
@onready var terror_bar = $PanicVignette/MarginContainer/VBoxContainer/TerrorBar
@onready var status_label = $PanicVignette/MarginContainer/VBoxContainer/StatusLabel
@onready var panic_vignette = $PanicVignette
@onready var adrenaline_timer_label = $PanicVignette/MarginContainer/VBoxContainer/TextAdrenalineTimer
@onready var battery_icon = $PanicVignette/BatteryIcon

# --- REFERÊNCIA DO JOGADOR ---
# IMPORTANTE: Selecione o nó do HUD no Inspector e arraste o seu "Player" para esta variável!
@export var player: Node3D 
# 1. Adicione a referência da sua Label lá no topo junto com as outras:
@onready var informative_text = $PanicVignette/InformativeText
@onready var adrenaline_overlay = $AdrenalineOverlay
@onready var interactive_text = $PanicVignette/InteractionText

# 2. Crie essa variável de controle para impedir que as mensagens se atropelem:
var message_id: int = 0
# --- IMAGENS DA BATERIA ---
# Substitua pelos nomes reais dos arquivos PNG que você possuiwawd
var bat_crit = preload("res://assets/texture/hud/battery_critical.png")
var bat_4 = preload("res://assets/texture/hud/low-battery.png")
var bat_3 = preload("res://assets/texture/hud/half-battery.png")
var bat_2 = preload("res://assets/texture/hud/battery.png")
var bat_1 = preload("res://assets/texture/hud/full-battery.png")

func _ready() -> void:
	# Começa com o filtro vermelho invisível
	panic_vignette.color.a = 0.0
	informative_text.text = "" 
	interactive_text.text = ""
	GameManager.show_informative_text.connect(_on_show_informative_text)
	GameManager.show_interactive_text.connect(_on_show_interactive_text)
func _process(delta: float) -> void:
	var current_terror = GameManager.terror_level
	
	# ---------------------------------------------------------
	# 1. PROGRESS BAR DE TERROR
	# ---------------------------------------------------------
	terror_bar.value = current_terror
	
	if current_terror > 50.0:
		terror_bar.modulate = Color(1, 0, 0) # Fica Vermelho
	else:
		terror_bar.modulate = Color(1, 1, 1) # Fica Branco
		
	# ---------------------------------------------------------
	# 2. O EFEITO DE PÂNICO (Vignette Shader)
	# ---------------------------------------------------------
	var intensity = clamp(current_terror / 100.0, 0.0, 1.0)
	panic_vignette.material.set_shader_parameter("terror_intensity", intensity)
	
# ---------------------------------------------------------
	# 3. TEXTOS DE STATUS E ADRENALINA (COM EFEITO L4D2)
	# ---------------------------------------------------------
	if GameManager.is_adrenaline_active:
		adrenaline_timer_label.text = "Efeito Adrenalina: " + str(int(GameManager.adrenaline_time_left)) + "s"
		adrenaline_timer_label.visible = true
		
		# O EFEITO VISUAL: Pulsa a opacidade usando uma onda senoidal (simula o coração)
		var pulse = (sin(Time.get_ticks_msec() / 120.0) + 1.0) / 2.0 
		adrenaline_overlay.color.a = lerp(0.04, 0.12, pulse) # Fica pulsando entre 4% e 12% de opacidade
		
	else:
		adrenaline_timer_label.visible = false 
		# Desvanece o efeito suavemente quando a adrenalina acaba
		adrenaline_overlay.color.a = move_toward(adrenaline_overlay.color.a, 0.0, delta * 0.5)
		
	if GameManager.is_addicted:
		status_label.text = "VICIADO"
		status_label.modulate = Color(1, 0, 0) # Vermelho
	elif current_terror >= 60:
		status_label.text = "EM PÂNICO"
		status_label.modulate = Color(1, 0.5, 0) # Laranja
	else:
		status_label.text = ""

	# ---------------------------------------------------------
	# 4. SISTEMA DE ÍCONE DA BATERIA
	# ---------------------------------------------------------
	if player != null and player.get("torch") != null:
		var luz_atual = player.torch.light_energy
		
		if luz_atual >= 6.25:
			battery_icon.texture = bat_1
		elif luz_atual >= 5:
			battery_icon.texture = bat_2
		elif luz_atual >= 3.2:
			battery_icon.texture = bat_3
		elif luz_atual >= 2.1:
			battery_icon.texture = bat_4
		else:
			battery_icon.texture = bat_crit
			
func _on_show_interactive_text(mensagem: String) -> void:
	interactive_text.text = mensagem
	
func _on_show_informative_text(mensagem: String) -> void:
	informative_text.text = mensagem
	
	# Aumenta a ID da mensagem atual
	message_id += 1
	var my_id = message_id 
	
	# Espera exatos 5.0 segundos de forma assíncrona (não trava o jogo!)
	await get_tree().create_timer(5.0).timeout
	
	# Se a ID for a mesma, significa que nenhuma outra mensagem nova sobrescreveu essa. 
	# Então podemos apagar!
	if my_id == message_id:
		informative_text.text = ""
