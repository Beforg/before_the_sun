extends CollisionObject3D 

@export var item_name: String = "Bateria"
@export var outline_material: Material # Arraste aquele material "outline_mat.tres" para cá no Inspector!
@onready var mesh = $Battery/m1 
@onready var mesh2 = $Battery/m2
@onready var mesh3 = $Battery/m3
@onready var mesh4 = $Battery/m4
@onready var mesh5 = $Battery/m5
@onready var mesh6 = $Battery/m6

func highlight() -> void:
	# Aplica a borda brilhante por cima do material original
	if mesh and outline_material:
		mesh.material_overlay = outline_material
		mesh2.material_overlay = outline_material
		mesh3.material_overlay = outline_material
		mesh4.material_overlay = outline_material
		mesh5.material_overlay = outline_material
		mesh6.material_overlay = outline_material

func unhighlight() -> void:
	# Remove a borda quando o jogador desvia o olhar
	if mesh:
		mesh.material_overlay = null
		mesh2.material_overlay = null
		mesh3.material_overlay = null
		mesh4.material_overlay = null
		mesh5.material_overlay = null
		mesh6.material_overlay = null

func interact() -> void:
	print("Coletou: ", item_name)
	
	# Aqui você colocará os ifs do GameManager no futuro
	if item_name == "Bateria" && GameManager.has_free_space():
		GameManager.collect_torch_refill()
		queue_free()
	# Destrói o item após coletar
	
