
extends Node2D

func _ready():
	MusicPlayer.play_music(preload("res://Music/main_menu.mp3"))
	
func _on_Button_pressed():
	SfxPlayer.play_sfx(preload("res://Sounds/button_click.mp3"))
	get_tree().change_scene("res://StoryScreen.tscn")


func _on_Button2_pressed():
	SfxPlayer.play_sfx(preload("res://Sounds/button_click.mp3"))
	get_tree().change_scene("res://Settings.tscn")


func _on_Button3_pressed():
	SfxPlayer.play_sfx(preload("res://Sounds/button_click.mp3"))
	get_tree().change_scene("res://EXtrainfo.tscn")


func _on_Button4_pressed():
	SfxPlayer.play_sfx(preload("res://Sounds/button_click.mp3"))
	get_tree().quit()
