extends CanvasLayer

@onready var progress_bar = $ColorRect/VBoxContainer/ProgressBar
@onready var color_rect = $ColorRect

var next_scene_path: String = ""
var is_loading: bool = false

func _ready() -> void:
	# Garante que a tela de loading comece invisível
	visible = false

func load_scene(path: String) -> void:
	next_scene_path = path
	
	# 1. Revela a tela preta e zera a barra
	progress_bar.value = 0
	visible = true
	
	# 2. Pede para a Godot carregar a cena pesada nos bastidores!
	ResourceLoader.load_threaded_request(next_scene_path)
	is_loading = true

func _process(delta: float) -> void:
	if not is_loading:
		return
		
	# 3. Verifica a porcentagem do carregamento
	var progress_array = []
	var status = ResourceLoader.load_threaded_get_status(next_scene_path, progress_array)
	
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		# progress_array[0] retorna um valor de 0.0 a 1.0. Multiplicamos por 100.
		progress_bar.value = progress_array[0] * 100
		
	elif status == ResourceLoader.THREAD_LOAD_LOADED:
		# 4. Carregamento terminou a 100%!
		progress_bar.value = 100
		is_loading = false
		
		# Pega a cena que estava sendo preparada nos bastidores
		var new_scene = ResourceLoader.load_threaded_get(next_scene_path)
		
		# Troca de cena instantaneamente sem travar
		get_tree().change_scene_to_packed(new_scene)
		
		# Opcional: Adiciona um atraso dramático de meio segundo antes de remover a tela preta
		await get_tree().create_timer(0.5).timeout
		visible = false
