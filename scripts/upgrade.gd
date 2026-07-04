extends Area3D

# Um enum elegante para você escolher o tipo do item direto no painel da Godot
enum UpgradeType { INVENTORY, ADRENALINE }
@export var outline_material: Material # Arraste aquele material "outline_mat.tres" para cá no Inspector!
@export var mesh: MeshInstance3D;
@export var type: UpgradeType = UpgradeType.INVENTORY
@export var upgrade_amount: int = 2 # Pode dar +2 slots ou +50 estamina, dependendo do tipo

# --- SE VOCÊ USA O SEU INTERACT_RAY PARA CLICAR E PEGAR ---
func highlight() -> void:
	# Aplica a borda brilhante por cima do material original
	if mesh and outline_material:
		mesh.material_overlay = outline_material

func unhighlight() -> void:
	# Remove a borda quando o jogador desvia o olhar
	if mesh:
		mesh.material_overlay = null
		
func interact() -> void:
	_apply_upgrade()

func _apply_upgrade() -> void:
	if type == UpgradeType.INVENTORY:
		GameManager.upgrade_inventory()
	elif type == UpgradeType.ADRENALINE:
		# Converte para float para manter a matemática da estamina precisa
		GameManager.upgrade_adrenaline()
		
	# Toca um som de coleta global aqui se tiver
	queue_free() # Destrói o item do mundo
