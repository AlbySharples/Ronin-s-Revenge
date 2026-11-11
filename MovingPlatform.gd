extends KinematicBody2D

export var move_distance = 300.0
export var move_speed = 100.0

var start_y = 0.0
var direction = -1

func _ready():
	start_y = global_position.y


func _physics_process(delta):
	var movement = direction * move_speed * delta

	global_position.y += movement

	if global_position.y <= start_y - move_distance:
		direction = 1

	elif global_position.y >= start_y:
		direction = -1
