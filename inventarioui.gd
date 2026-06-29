extends CanvasLayer

@onready var grid_itens = $ColorRect/VBoxContainer/GridItens # Ajuste o caminho para o seu Grid
@onready var grid_chaves = $ColorRect/VBoxContainer/GridChaves # Ajuste o caminho

# Carrega a cena do quadradinho que criamos no Passo 3
var slot_scene = preload("res://item_slot.tscn")

# Carregue aqui as imagens png que você desenhou
var tex_cura = preload("res://assets/models/cura.png")
var tex_bateria = preload("res://assets/models/enemy_iddle.png")
var tex_adrenalina = preload("res://assets/models/adrenalina.png")
var tex_bloqueado = preload("res://assets/models/items/pubg_mobile_adrenaline_syringe_2.png") # A imagem do X

func _ready() -> void:
	visible = false # Começa escondido

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventario"):
		visible = !visible 
		
		if visible:
			_update_ui() 
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE # Solta o mouse
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED # Prende o mouse

func _update_ui() -> void:
	# 1. Limpa o grid antigo
	for child in grid_itens.get_children():
		child.queue_free()
		
	# 2. Adiciona os Itens Agrupados
	# A Lanterna (Item fixo que não conta no limite de 6 slots)
	
	if GameManager.cures_count > 0:
		_criar_slot(tex_cura, GameManager.cures_count)
	if GameManager.torch_refills > 0:
		_criar_slot(tex_bateria, GameManager.torch_refills)
	if GameManager.adrenaline_count > 0:
		_criar_slot(tex_adrenalina, GameManager.adrenaline_count)
		
	# 3. Preencher os espaços vazios e bloqueados
	# O cálculo visual: Quantos "quadrados" de itens normais desenhamos?
	var quadrados_desenhados = grid_itens.get_child_count()
	
	# Para desenhar a exata imagem do seu design, vamos preencher até dar 6 colunas
	# Se ele tiver os 6 slots liberados, mas só 3 itens diferentes, desenha os vazios
	var limite_visual = max(6, GameManager.max_inventory_slots)
	
	for i in range(limite_visual - quadrados_desenhados):
		# Se o slot visual que estamos desenhando agora é maior que o max_inventory_slots, ele é um slot bloqueado com X
		if quadrados_desenhados + i >= GameManager.max_inventory_slots:
			_criar_slot(tex_bloqueado, 0) # Slot com X
		else:
			_criar_slot(null, 0) # Slot vazio escuro

func _criar_slot(textura: Texture2D, quantidade: int) -> void:
	var novo_slot = slot_scene.instantiate()
	grid_itens.add_child(novo_slot)
	
	# Busca a imagem e o texto dentro do quadradinho
	var icone = novo_slot.get_node("TextureRect")
	var label_qtd = novo_slot.get_node("Label")
	
	if textura != null:
		icone.texture = textura
	
	if quantidade > 1:
		label_qtd.text = str(quantidade)
	else:
		label_qtd.text = "" # Esconde o número se for 1, 0 ou item bloqueado
