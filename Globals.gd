
extends Node

# PLAYER HEALTH
var max_health = 100
var health = 100

# SHURIKENS
var max_shurikens = 10
var shurikens = 10

# STOPWATCH
var elapsed_time = 0.0

# VICTORY STATS
var enemies_defeated = 0
var game_completed = false

# CHECKPOINT
var last_level = ""


func reset_game():
	health = max_health
	shurikens = max_shurikens
	elapsed_time = 0.0
	enemies_defeated = 0
	game_completed = false
	last_level = ""



var last_health_level = ""

func heal_for_new_level(level_path):
	if level_path == last_health_level:
		return

	last_health_level = level_path

	health = min(
		health + max_health * 0.25,
		max_health
	)
