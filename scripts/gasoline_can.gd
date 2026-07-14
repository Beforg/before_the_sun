extends CollisionObject3D # Funciona tanto para Area3D quanto para StaticBody3D

@export var item_name: String = "Gasoline"
@export var outline_material: Material # Arraste aquele material "outline_mat.tres" para cá no Inspector!
@onready var mesh = $Visual/Object_2 # Certifique-se de que o nome da sua malha 3D está correto
@onready var sound = $CollectSound
@export var collision: CollisionShape3D
func highlight() -> void:
	# Aplica a borda brilhante por cima do material original
	GameManager.display_interact_text("Pressione [E] para coletar Gasolina")
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
	if item_name == "Gasoline":
		sound.play()
		GameManager.collect_gasoline()
		GameManager.display_message("Gasolina coletada")
		mesh.visible = false
		
		# 3. Desativa a colisão para o jogador não pegar o item invisível duas vezes
		collision.set_deferred("disabled", true)
		
		# 4. Pausa a execução deste script até o som terminar de tocar
		await sound.finished
		queue_free()
