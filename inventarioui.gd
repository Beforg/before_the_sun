extends CanvasLayer

# --- REFERÊNCIAS DOS NÓS NA TELA ---
@onready var label_titulo = $ColorRect/VBoxContainer/Label # A Label escrita "Inventario"
@onready var grid_itens = $ColorRect/VBoxContainer/GridItens
@onready var grid_chaves = $ColorRect/VBoxContainer/GridChaves
@onready var map = $Map
@onready var objective_text = $VBoxContainer/ObjectiveText
# Carrega a cena do quadradinho
var slot_scene = preload("res://item_slot.tscn")

# --- SUAS IMAGENS ---
var tex_cura = preload("res://assets/texture/inv/cure.png")
var tex_bateria = preload("res://assets/texture/inv/battery.png")
var tex_adrenalina = preload("res://assets/texture/inv/adr.png")
var tex_vazio = preload("res://assets/texture/inv/empty.png") # A imagem da moldura vazia
var tex_gas = preload("res://assets/texture/inv/gas3.png")
var tex_key = preload("res://assets/texture/inv/key.png")

func _ready() -> void:
	visible = false 
	map.visible = false
	
	if GameManager.has_signal("inventory_upgraded"):
		GameManager.inventory_upgraded.connect(_on_inventory_upgraded)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventario"):
		visible = !visible 
			
		if visible:
			_update_ui() 
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE 
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED 

func _update_ui() -> void:
	# 1. Atualiza o texto do título para mostrar a capacidade máxima do jogador
	objective_text = GameManager.objective
	if GameManager.has_map:
		map.visible = true
	label_titulo.text = "Inventário (Máx. " + str(GameManager.max_inventory_slots) + " Itens)"

	# 2. Limpa os dois grids forçando a remoção da árvore
	for child in grid_itens.get_children():
		grid_itens.remove_child(child) 
		child.queue_free()
	for child in grid_chaves.get_children():
		grid_chaves.remove_child(child) 
		child.queue_free()
		
	# ---------------------------------------------------------
	# GRID 1: ITENS CONSUMÍVEIS (Fixo em 3 slots visuais)
	# ---------------------------------------------------------
	var itens_desenhados = 0
		
	if GameManager.torch_refills > 0:
		_criar_slot(grid_itens, tex_bateria, GameManager.torch_refills)
		itens_desenhados += 1
		
	if GameManager.adrenaline_count > 0:
		_criar_slot(grid_itens, tex_adrenalina, GameManager.adrenaline_count)
		itens_desenhados += 1
		
	if GameManager.cures_count > 0:
		_criar_slot(grid_itens, tex_cura, GameManager.cures_count)
		itens_desenhados += 1
		
	# Preenche o restante para sempre ter exatos 3 quadrados na tela
	for i in range(3 - itens_desenhados):
		_criar_slot(grid_itens, tex_vazio, 0)
			
	# ---------------------------------------------------------
	# GRID 2: ITENS CHAVE (Fixo em 2 slots visuais)
	# ---------------------------------------------------------
	var chaves_desenhadas = 0
	
	if GameManager.gasoline_count > 0:
		_criar_slot(grid_chaves,tex_gas, GameManager.gasoline_count)
		chaves_desenhadas += 1
	if GameManager.has_gate_key || GameManager.has_door_key:
		_criar_slot(grid_chaves,tex_key, chaves_desenhadas)
		chaves_desenhadas+=1
	# Preenche o restante para sempre ter exatos 2 quadrados para chaves
	for i in range(2 - chaves_desenhadas):
		_criar_slot(grid_chaves, tex_vazio, 0)

# --- FUNÇÃO DE CRIAÇÃO (Agora recebe o Grid Alvo como parâmetro) ---
func _criar_slot(grid_alvo: GridContainer, textura: Texture2D, quantidade: int) -> void:
	var novo_slot = slot_scene.instantiate()
	grid_alvo.add_child(novo_slot) # Agora ele obedece em qual Grid deve entrar!
	
	var icone = novo_slot.get_node("TextureRect")
	var label_qtd = novo_slot.get_node("Label") 
	
	if textura != null:
		icone.texture = textura
	else:
		icone.texture = null 
	
	if quantidade > 1:
		label_qtd.text = str(quantidade)
	else:
		label_qtd.text = ""

func _on_inventory_upgraded(_new_max: int) -> void:
	if visible:
		_update_ui()
