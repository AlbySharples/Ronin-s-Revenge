
extends Area2D

export(PackedScene) var green_enemy_scene
export(PackedScene) var yellow_enemy_scene
export(PackedScene) var bat_scene

export var left_spawn_distance = 1000.0
export var right_spawn_distance = 1300.0

export var enemy_rush_speed = 280.0
export var bat_rush_speed = 250.0

var triggered = false


func _ready():
	if not is_connected("body_entered", self, "_on_body_entered"):
		connect("body_entered", self, "_on_body_entered")


func _on_body_entered(body):
	if triggered:
		return

	if not body.is_in_group("player"):
		return

	if green_enemy_scene == null or yellow_enemy_scene == null or bat_scene == null:
		print("Assign all three enemy scenes in the Inspector!")
		return

	triggered = true
	spawn_ambush(body)


func spawn_ambush(player):
	var center = player.global_position

	# LEFT: green ninja first, yellow ninja behind
	spawn_enemy(green_enemy_scene, center + Vector2(-left_spawn_distance, 0))
	spawn_enemy(yellow_enemy_scene, center + Vector2(-left_spawn_distance - 230, 0))

	# RIGHT: green ninja first, yellow ninja behind
	spawn_enemy(green_enemy_scene, center + Vector2(right_spawn_distance, 0))
	spawn_enemy(yellow_enemy_scene, center + Vector2(right_spawn_distance + 230, 0))

	# LEFT: 2 bats, spaced apart at different heights
	spawn_bat(center + Vector2(-left_spawn_distance - 100, -190))
	spawn_bat(center + Vector2(-left_spawn_distance - 350, -310))

	# RIGHT: 3 bats, staggered at different heights
	spawn_bat(center + Vector2(right_spawn_distance + 80, -250))
	spawn_bat(center + Vector2(right_spawn_distance + 300, -150))
	spawn_bat(center + Vector2(right_spawn_distance + 500, -350))


func spawn_enemy(scene, position):
	var enemy = scene.instance()

	get_parent().add_child(enemy)
	enemy.global_position = position

	if enemy.get("chase_speed") != null:
		enemy.set("chase_speed", enemy_rush_speed)

	if enemy.get("detection_range") != null:
		enemy.set("detection_range", 2500.0)


func spawn_bat(position):
	var bat = bat_scene.instance()

	get_parent().add_child(bat)
	bat.global_position = position

	if bat.get("chase_speed") != null:
		bat.set("chase_speed", bat_rush_speed)

	if bat.get("detection_range") != null:
		bat.set("detection_range", 2500.0)
