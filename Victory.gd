
extends Node2D

onready var time_label = $TimeTaken
onready var enemies_label = $EnemiesDefeated


func _ready():
	MusicPlayer.play_music(preload("res://Music/victory.mp3"))

	var minutes = int(Globals.elapsed_time) / 60
	var seconds = int(Globals.elapsed_time) % 60

	time_label.text = "TIME TAKEN: %02d:%02d" % [minutes, seconds]
	enemies_label.text = "ENEMIES DEFEATED: " + str(Globals.enemies_defeated)


func _on_Home_pressed():
	SfxPlayer.play_sfx(preload("res://Sounds/button_click.mp3"))
	get_tree().change_scene("res://MainMenu.tscn")
