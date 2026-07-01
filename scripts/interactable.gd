extends CollisionObject3D # Funciona tanto para Area3D quanto para StaticBody3D

@export var item_name: String = "Chave do Portao"
@export var outline_material: Material # Arraste aquele material "outline_mat.tres" para cá no Inspector!
@onready var mesh = $Chave/Sketchfab_model/Key2_obj_cleaner_materialmerger_gles/Object_2 # Certifique-se de que o nome da sua malha 3D está correto

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
	if item_name == "Chave do Portao":
		GameManager.has_gate_key = true
	elif item_name == "p1_act1":
		GameManager.has_gate_key = true # trocar dps
		
	# Destrói o item após coletar
	queue_free()
