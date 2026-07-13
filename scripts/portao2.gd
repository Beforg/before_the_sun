extends StaticBody3D

@export var outline_material: Material

# A malha 3D é o "pai" deste StaticBody3D (o Object_10)
@onready var mesh = get_parent() 

# O pivô de rotação é o "avô" deste StaticBody3D (o nó Portao)
@onready var pivot = get_parent().get_parent() 

var is_open = false

func highlight() -> void:
	if mesh and outline_material and not is_open:
		# Aplica o material na malha visual
		GameManager.display_interact_text("Pressione [E] para Abrir")
		if mesh is MeshInstance3D:
			mesh.material_overlay = outline_material

func unhighlight() -> void:
	GameManager.clear_interaction_text()
	if mesh and mesh is MeshInstance3D:
		
		mesh.material_overlay = null

func interact() -> void:
	if is_open:
		return 
		
	if GameManager.has_gate_key && GameManager.gasoline_count > 0:
		_open_gate()
	else:
		GameManager.display_message("Trancado.")

func _open_gate() -> void:
	is_open = true
	unhighlight() 
	print("O Portão foi destrancado!")
	
	var tween = create_tween()
	var posicao_final_aberta = Vector3(0.565, 5.001, 3.492) 
	tween.tween_property(pivot, "position", posicao_final_aberta, 0.1).set_trans(Tween.TRANS_SINE)
	# Gira o "avô" (nó Portao) 90 graus no eixo Y
	tween.tween_property(pivot, "rotation_degrees:y", 90.0, 1.0).set_trans(Tween.TRANS_SINE)
