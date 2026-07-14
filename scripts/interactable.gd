extends CollisionObject3D # Funciona tanto para Area3D quanto para StaticBody3D

@export var item_name: String = "Chave do Portao"
@export var outline_material: Material # Arraste aquele material "outline_mat.tres" para cá no Inspector!
@export var mesh: MeshInstance3D # Certifique-se de que o nome da sua malha 3D está correto
@export var canvas: CanvasLayer = null
@export var canvas_text: Label = null
@export var texto_bilhete: String
@export var collect_sound: AudioStreamPlayer3D

var is_reading: bool = false
var can_close: bool = false

func _ready() -> void:
	if canvas != null:
		canvas.visible = false

func highlight() -> void:
	# Aplica a borda brilhante por cima do material original
	if item_name == "Chave do Portao":
		GameManager.display_interact_text("Pressione [E] para coletar Chave")
	elif item_name == "p1_act1":
		GameManager.display_interact_text("Pressione [E] para coletar Chave")
	elif item_name == "map":
		GameManager.display_interact_text("Pressione [E] para coletar Mapa")
	elif item_name == "door_key":
		GameManager.display_interact_text("Pressione [E] para coletar Chave da Casa")
	elif item_name == "Bilhete":
		GameManager.display_interact_text("Pressione [E] para ler Anotação")
	elif item_name == "toy":
		GameManager.display_interact_text("Pressione [E] para coletar Colecionável")
		
	if mesh and outline_material:
		mesh.material_overlay = outline_material

func unhighlight() -> void:
	# Remove a borda quando o jogador desvia o olhar
	GameManager.clear_interaction_text()
	if mesh:
		mesh.material_overlay = null

func interact() -> void:
	print("Coletou: ", item_name)
	
	# ==========================================
	# 1. AÇÃO IMEDIATA (Serve para TODOS os itens)
	# ==========================================
	unhighlight() # Remove o brilho e o texto da tela na hora
	
	if mesh:
		mesh.visible = false # Esconde a malha diretamente
		
	# Desativa a colisão com segurança (evita erros da engine de física)
	$CollisionShape3D.set_deferred("disabled", true)
	
	if collect_sound != null:
		collect_sound.play()
		
	# ==========================================
	# 2. LÓGICA ESPECÍFICA DE CADA ITEM
	# ==========================================
	if item_name == "Chave do Portao":
		GameManager.has_gate_key = true
		GameManager.display_message("Chave coletada")
		if collect_sound: await collect_sound.finished
		queue_free()
		
	elif item_name == "door_key":
		GameManager.has_door_key = true
		GameManager.display_message("Chave da Casa coletada")
		if collect_sound: await collect_sound.finished
		queue_free()
		
	elif item_name == "p1_act1":
		GameManager.display_message("Chave coletada")
		GameManager.has_gate_key = true 
		if collect_sound: await collect_sound.finished
		queue_free()
		
	elif item_name == "toy":
		GameManager.toy_count += 1
		GameManager.display_message("Colecionável coletado: "+str(GameManager.toy_count)+"/3")
		if collect_sound: await collect_sound.finished
		queue_free()
		
	elif item_name == "map":
		GameManager.display_message("Mapa coletado")
		GameManager._collect_map()
		if collect_sound: await collect_sound.finished
		queue_free()
		
	elif item_name == "Bilhete":
		if canvas != null:
			# O item já ficou invisível e sem colisão lá em cima!
			# Agora só precisamos cuidar da interface da leitura:
			canvas.visible = true
			canvas_text.text = texto_bilhete
			GameManager._collect_bilhete()
			
			is_reading = true
			
			# Um pequeno atraso para o jogador não fechar a tela sem querer 
			# com o mesmo clique duplo rápido que usou para abrir
			await get_tree().create_timer(0.5).timeout
			can_close = true
	
# A função nativa que escuta os teclados a todo momento
func _input(event: InputEvent) -> void:
	# Se o jogador estiver lendo, puder fechar, e apertar a tecla "E" (troque para a sua ação)
	if is_reading and can_close and event.is_action_pressed("interagir"):
		canvas.visible = false
		is_reading = false # É sempre bom desligar a variável
		
		# AGORA SIM, o jogador terminou de ler, podemos mandar o item para o ralo!
		queue_free()
