extends CollisionObject3D # Funciona tanto para Area3D quanto para StaticBody3D

@export var item_name: String = "Chave do Portao"
@export var outline_material: Material # Arraste aquele material "outline_mat.tres" para cá no Inspector!
@export var mesh: MeshInstance3D # Certifique-se de que o nome da sua malha 3D está correto
@export var canvas: CanvasLayer = null
@export var canvas_text: Label = null
@export var texto_bilhete: String
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
	elif item_name == "Bilhete":
		GameManager.display_interact_text("Pressione [E] para coletar Anotacao")
	if mesh and outline_material:
		mesh.material_overlay = outline_material

func unhighlight() -> void:
	# Remove a borda quando o jogador desvia o olhar
	GameManager.clear_interaction_text()
	if mesh:
		mesh.material_overlay = null

func interact() -> void:
	print("Coletou: ", item_name)
	
	# Aqui você colocará os ifs do GameManager no futuro
	if item_name == "Chave do Portao":
		GameManager.has_gate_key = true
		GameManager.display_message("Chave coletada")
		queue_free()
	elif item_name == "p1_act1":
		GameManager.display_message("Chave coletada")
		GameManager.has_gate_key = true # trocar dps
		queue_free()
	elif item_name == "map":
		GameManager.display_message("Mapa coletado")
		GameManager._collect_map()
		queue_free()
	elif item_name == "Bilhete":
		if canvas != null:
			# 1. Abre a interface
			canvas.visible = true
			canvas_text.text = texto_bilhete
			GameManager._collect_bilhete()
			
			# 2. Esconde o item do mundo real e remove a borda
			if mesh:
				mesh.visible = false
				mesh.material_overlay = null
				
			# 3. Desativa a colisão para o raio não bater mais nele
			$CollisionShape3D.disabled = true
			GameManager.clear_interaction_text()
			
			# 4. Trava o jogador na leitura
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
		
		# AGORA SIM, o jogador terminou de ler, podemos mandar o item para o ralo!
		queue_free()
