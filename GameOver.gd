
extends Node2D


func _ready():
	MusicPlayer.play_music(preload("res://Music/defeat.wav"))


func _on_Restart_pressed():
	SfxPlayer.play_sfx(preload("res://Sounds/button_click.mp3"))

	print("RESTART BUTTON CLICKED")

	Globals.health = Globals.max_health
	get_tree().change_scene(Globals.last_level)
