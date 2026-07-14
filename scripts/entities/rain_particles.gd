extends GPUParticles3D

@export var max_gallons_storm: float = 7.0 

func _ready() -> void:
	# A chuva começa bem leve (10% das 5000 partículas = 500 gotas)
	amount_ratio = 0.1 

func _process(delta: float) -> void:
	var storm_intensity
	# Calcula a porcentagem da tempestade com base na gasolina (de 0.0 a 1.0)
	if GameManager.is_final_act:
		amount_ratio = 0.0
	else:
		storm_intensity = (GameManager.gasoline_count / max_gallons_storm) * GameManager.storm_multiplier
		amount_ratio = clamp(0.1 + (storm_intensity * 0.9), 0.1, 1.0)
		process_material.direction.x = lerp(0.0, 0.5, storm_intensity)
 
