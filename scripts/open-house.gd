extends StaticBody3D

@export var outline_material: Material
@export var locked_sound: AudioStreamPlayer3D
@export var open_sound: AudioStreamPlayer3D
# A malha 3D é o "pai" deste StaticBody3D (o Object_10)
@onready var mesh = get_parent() 

# O pivô de rotação é o "avô" deste StaticBody3D (o nó Portao)
@onready var pivot = get_parent().get_parent() 

var is_open = false

func highlight() -> void:
	if mesh and outline_material and not is_open:
		GameManager.display_interact_text("Pressione [E] para Abrir")
		# Aplica o material na malha visual
		if mesh is MeshInstance3D:
			mesh.material_overlay = outline_material

func unhighlight() -> void:
	if mesh and mesh is MeshInstance3D:
		GameManager.clear_interaction_text()
		mesh.material_overlay = null

func interact() -> void:
	if is_open:
		return 
		
	if GameManager.has_door_key:
		if open_sound != null:
			open_sound.play()
		_open_gate()
	else:
		if locked_sound != null:
			locked_sound.play()
		GameManager.display_message("Trancado.")

func _open_gate() -> void:
	is_open = true
	unhighlight() 
	print("A porta foi destrancada!")
	GameManager.has_door_key = false
	var tween = create_tween()
	tween.set_parallel(true)
	
	var posicao_final_aberta = Vector3(-140, 0, -46.237) 
	
	# 2. O TEMPO: Defina um tempo maior (ex: 1.5 segundos) para o movimento ser visível e suave
	var tempo_de_abertura = 0.5
	
	# Move e Gira o portão de forma sincronizada
	tween.tween_property(pivot, "position", posicao_final_aberta, tempo_de_abertura).set_trans(Tween.TRANS_SINE)
	tween.tween_property(pivot, "rotation_degrees:y", -115.2, 0.45).set_trans(Tween.TRANS_SINE)
	
