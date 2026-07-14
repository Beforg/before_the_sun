extends Node

@export var tree_material: ShaderMaterial 
@export var world_env: WorldEnvironment
@export var max_gallons_storm: float = 7.0 

@export var nevoeiro_minimo: float = 0.05 
@export var nevoeiro_maximo: float = 0.20
var is_storm_passing: bool = false
func _process(delta: float) -> void:
	var storm_progress = (GameManager.gasoline_count / max_gallons_storm) * GameManager.storm_multiplier
	if tree_material != null:
		var current_speed = lerp(1.55, 3.5, storm_progress)
		
		var current_strength = lerp(0.5, 5.0, storm_progress)
		
		# Envia os dois parâmetros para o Shader simultaneamente
		tree_material.set_shader_parameter("wind_speed", current_speed)
		tree_material.set_shader_parameter("wind_strength", current_strength)
	if world_env != null and world_env.environment != null:
		var current_fog = lerp(nevoeiro_minimo, nevoeiro_maximo, storm_progress)
		world_env.environment.volumetric_fog_density = current_fog
