extends StaticBody3D

@export var outline_material: Material
@export var gate_pivot: Node3D # Arraste o nó 'Pivot' do seu PortaoGerador para cá no Inspector!
@export var gate_pivot2: Node3D

# Arraste a malha 3D do seu gerador (o MeshInstance3D dele) para cá:
@onready var generator_mesh =  $GeradorPartes/destaque/destaque
@onready var generator_mesh2 =  $GeradorPartes/destaque2/destaque2
@onready var generator_mesh3 =  $GeradorPartes/dastaque3/destaque3
var is_activated = false

func highlight() -> void:
	# Só destaca o gerador se ele ainda estiver desligado
	if generator_mesh and outline_material and not is_activated:
		if generator_mesh is MeshInstance3D:
			generator_mesh.material_overlay = outline_material
			generator_mesh2.material_overlay = outline_material
			generator_mesh3.material_overlay = outline_material

func unhighlight() -> void:
	if generator_mesh and generator_mesh is MeshInstance3D:
		generator_mesh.material_overlay = null
		generator_mesh2.material_overlay = null
		generator_mesh3.material_overlay = null

func interact() -> void:
	if is_activated:
		return 
		
	if GameManager.gasoline_count >= 10:
		_activate_generator()
	else:
		print("Falta combustível. Tenho " + str(GameManager.gasoline_count) + "/10 galões.")

func _activate_generator() -> void:
	is_activated = true
	unhighlight() # Remove o brilho do gerador para sempre
	print("Gerador roncando! Ligando sistemas e abrindo o portão...")
	
	# Se você esqueceu de arrastar o pivô do portão no Inspector, evita crashar o jogo
	if gate_pivot == null:
		print("ERRO: Esqueceu de arrastar o Pivot do portão no Inspector do Gerador!")
		return
		
	# Cria a animação para abrir o portão remotamente
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Gira o pivô do portão que está lá na cerca
	tween.tween_property(gate_pivot, "rotation_degrees:y", -88, 2.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(gate_pivot2, "rotation_degrees:y", -300, 2.0).set_trans(Tween.TRANS_SINE)
	
	# Se o portão do gerador precisar daquele ajuste de posição, descomente aqui:
	# var posicao_final = gate_pivot.position + Vector3(0.5, 0.0, -0.2)
	# tween.tween_property(gate_pivot, "position", posicao_final, 2.0).set_trans(Tween.TRANS_SINE)
