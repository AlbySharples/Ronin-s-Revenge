
extends Area2D

export(PackedScene) var next_level

var transitioning = false


func _on_Portal_body_entered(body):
	print("Portal touched by: ", body.name)

	if transitioning:
		return

	if body.name == "MainCharacter":
		if next_level == null:
			print("ERROR: Next Level has not been assigned!")
			return

		transitioning = true
		get_tree().change_scene_to(next_level)
