extends Node3D
@onready var terror_ambient = $TerrorAmbience

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
func _process(delta: float) -> void:
	if GameManager.gasoline_count >= 1 and not terror_ambient.playing:
		terror_ambient.play()
