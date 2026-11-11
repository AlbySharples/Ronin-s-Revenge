extends Node2D

export(PackedScene) var bird_scene

export var min_spawn_time = 1.0
export var max_spawn_time = 2.0
export var spawn_distance = 100.0

export var min_flight_height = -150.0
export var max_flight_height = 150.0

export var max_birds = 5
export var minimum_height_gap = 80.0

var spawn_timer = 0.0
var active_birds = []


func _ready():
	randomize()
	reset_timer()


func _process(delta):
	# Remove birds that have been deleted.
	for i in range(active_birds.size() - 1, -1, -1):
		if not is_instance_valid(active_birds[i]):
			active_birds.remove(i)

	spawn_timer -= delta

	if spawn_timer <= 0:
		if active_birds.size() < max_birds:
			spawn_bird()

		reset_timer()


func reset_timer():
	spawn_timer = rand_range(min_spawn_time, max_spawn_time)


func spawn_bird():
	if bird_scene == null:
		print("ERROR: Bird scene not assigned!")
		return

	var camera = get_parent().get_node_or_null("Camera2D")

	if camera == null:
		print("ERROR: Camera2D not found!")
		return

	var camera_center = camera.get_camera_screen_center()
	var half_width = get_viewport_rect().size.x * camera.zoom.x / 2.0

	# Find a height away from existing birds.
	var spawn_y = camera_center.y
	var valid_height = false

	for attempt in range(20):
		spawn_y = camera_center.y + rand_range(
			min_flight_height,
			max_flight_height
		)

		valid_height = true

		for other_bird in active_birds:
			if is_instance_valid(other_bird):
				if abs(spawn_y - other_bird.global_position.y) < minimum_height_gap:
					valid_height = false
					break

		if valid_height:
			break

	if not valid_height:
		return

	var bird = bird_scene.instance()

	var from_right = randi() % 2 == 0

	if from_right:
		bird.direction = -1
	else:
		bird.direction = 1

	get_parent().add_child(bird)

	var spawn_x = camera_center.x

	if from_right:
		spawn_x += half_width + spawn_distance
	else:
		spawn_x -= half_width + spawn_distance

	bird.global_position = Vector2(spawn_x, spawn_y)

	active_birds.append(bird)
