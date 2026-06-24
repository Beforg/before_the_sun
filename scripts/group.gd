extends Node3D

@export var player: Node3D
@export var render_distance := 120.0

func _process(_delta):
	var should_show = global_position.distance_to(player.global_position) < render_distance

	for child in get_children():
		if child is Node3D:
			child.visible = should_show
