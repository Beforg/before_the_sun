extends CollisionObject3D 

@export var item_name: String = "Adrenalina"
@export var outline_material: Material # Arraste aquele material "outline_mat.tres" para cá no Inspector!
@onready var mesh = $"Visual/Adrenaline Syringe_Adrenaline Syringe_0" # Certifique-se de que o nome da sua malha 3D está correto
@onready var sound = $CollectSound
@export var collision: CollisionShape3D
func highlight() -> void:
	# Aplica a borda brilhante por cima do material original
	GameManager.display_interact_text("Pressione [E] para coletar Adrenalina")
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
	if item_name == "Adrenalina" && GameManager.has_free_space():
		sound.play()
		GameManager.collect_adrenaline()
		GameManager.display_message("Adrenalina coletada")
		mesh.visible = false
		
		# 3. Desativa a colisão para o jogador não pegar o item invisível duas vezes
		collision.set_deferred("disabled", true)
		
		# 4. Pausa a execução deste script até o som terminar de tocar
		await sound.finished
		queue_free()
	# Destrói o item após coletar
	
