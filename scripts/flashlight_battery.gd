extends CollisionObject3D 

@export var item_name: String = "Bateria"
@export var outline_material: Material # Arraste aquele material "outline_mat.tres" para cá no Inspector!
@onready var mesh = $Battery/MeshInstance3D # Certifique-se de que o nome da sua malha 3D está correto

func highlight() -> void:
	# Aplica a borda brilhante por cima do material original
	if mesh and outline_material:
		mesh.material_overlay = outline_material

func unhighlight() -> void:
	# Remove a borda quando o jogador desvia o olhar
	if mesh:
		mesh.material_overlay = null

func interact() -> void:
	print("Coletou: ", item_name)
	
	# Aqui você colocará os ifs do GameManager no futuro
	if item_name == "Bateria" && GameManager.has_free_space():
		GameManager.collect_torch_refill()
		queue_free()
	# Destrói o item após coletar
	
