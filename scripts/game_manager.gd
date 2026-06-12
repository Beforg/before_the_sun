extends Node

signal monster_awakened
signal difficulty_increased(level)
signal spawn_second_monster 

# Variáveis básicas
var gasoline_count: int = 0
var dollars: int = 0
var adrenaline_count: int = 0
var torch_refills: int = 0
var terror_level: float = 0.0
var cures_count: int = 0
const MAX_TERROR: float = 100.0

# Sistema de Vício
var is_addicted: bool = false
var adrenaline_time_left: float = 0.0
var is_adrenaline_active: bool = false
var adrenaline_use_history: Array = [] 

func collect_gasoline(): 
	gasoline_count += 1
	_check_difficulty_milestones()
func collect_dollar(amount: int): dollars += amount
func collect_adrenaline(): adrenaline_count += 1
func collect_torch_refill(): torch_refills += 1
func collect_cure(): cures_count += 1

func _check_difficulty_milestones():
	match gasoline_count:
		1:
			print("DIRETOR: O jogador pegou o 1º galão. Acordem o monstro!")
			emit_signal("monster_awakened")
		3:
			print("DIRETOR: 3 galões. Aumentando dificuldade para o Nível 1.")
			emit_signal("difficulty_increased", 1)
		5:
			print("DIRETOR: 5 galões. Aumentando dificuldade para o Nível 2.")
			emit_signal("difficulty_increased", 2)
		7:
			print("DIRETOR: 7 galões. A situação saiu de controle. Soltem o clone!")
			emit_signal("spawn_second_monster")

func try_use_adrenaline() -> bool:
	if adrenaline_count > 0:
		adrenaline_count -= 1
		var current_time = Time.get_ticks_msec() / 1000.0
		adrenaline_use_history.append(current_time)
		
		_check_addiction()
		
		# --- A PARTE QUE FALTAVA ---
		is_adrenaline_active = true
		if is_addicted:
			adrenaline_time_left = 7.5
		else:
			adrenaline_time_left = 10.0
			
		return true 
	return false

func _check_addiction():
	var now = Time.get_ticks_msec() / 1000.0
	while adrenaline_use_history.size() > 0 and now - adrenaline_use_history[0] > 60.0:
		adrenaline_use_history.remove_at(0)
	
	if adrenaline_use_history.size() >= 3:
		is_addicted = true
		print("ESTADO: VICIADO! Eficiência reduzida.")

func cure_addiction():
	is_addicted = false
	adrenaline_use_history.clear()
	terror_level = 0
	print("ESTADO: LIMPO! Vício curado.")
	
func reset_game():
	gasoline_count = 0
	dollars = 0
	adrenaline_count = 0
	torch_refills = 0 
	is_addicted = false
	adrenaline_use_history.clear()
	terror_level = 0
	cures_count = 0
	is_adrenaline_active = false
	adrenaline_time_left = 0.0
	
func _process(delta: float) -> void:
	# 1. Dreno do Terror
	if terror_level > 0:
		terror_level -= 2 * delta
	terror_level = clamp(terror_level, 0.0, MAX_TERROR)
	
	# 2. CONTAGEM DO TEMPO DA ADRENALINA (Agora o GameManager gerencia isso!)
	if adrenaline_time_left > 0:
		adrenaline_time_left -= delta
		if adrenaline_time_left <= 0:
			adrenaline_time_left = 0.0
			is_adrenaline_active = false # Aqui ele desliga o boost!
			print("Efeito da Adrenalina acabou no GameManager")	
	
func increase_terror(amount: float):
	terror_level += amount
	terror_level = clamp(terror_level, 0.0, MAX_TERROR)
