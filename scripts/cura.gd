extends CollisionObject3D # Funciona tanto para Area3D quanto para StaticBody3D

@export var item_name: String = "Cura"
@export var outline_material: Material # Arraste aquele material "outline_mat.tres" para cá no Inspector!
@onready var mesh = $Visual/LP_Material_0 # Certifique-se de que o nome da sua malha 3D está correto

func highlight() -> void:
	# Aplica a borda brilhante por cima do material original
	GameManager.display_interact_text("Pressione [E] para coletar Cura")
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
	if item_name == "Cura" && GameManager.has_free_space():
		GameManager.display_message("Cura coletada")
		GameManager.collect_cure()
		queue_free()
	# Destrói o item após coletar
