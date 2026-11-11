
extends CanvasLayer

onready var panel = $Panel
onready var resume_button = $Panel/Resume
onready var quit_button = $Panel/Quit

var paused = false


func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	panel.hide()

	resume_button.connect("pressed", self, "_on_Resume_pressed")
	quit_button.connect("pressed", self, "_on_Quit_pressed")


func _input(event):
	if event is InputEventKey:
		if event.pressed and not event.echo and event.scancode == KEY_ESCAPE:

			if not is_gameplay_level():
				return

			if paused:
				resume_game()
			else:
				pause_game()

			get_tree().set_input_as_handled()


func is_gameplay_level():
	var current_scene = get_tree().current_scene

	if current_scene == null:
		return false

	var scene_name = current_scene.name

	return scene_name.begins_with("Level")


func pause_game():
	if not is_gameplay_level():
		return

	paused = true
	panel.show()
	get_tree().paused = true


func resume_game():
	paused = false
	get_tree().paused = false
	panel.hide()


func _on_Resume_pressed():
	SfxPlayer.play_sfx(preload("res://Sounds/button_click.mp3"))
	resume_game()


func _on_Quit_pressed():
	SfxPlayer.play_sfx(preload("res://Sounds/button_click.mp3"))
	resume_game()
	get_tree().change_scene("res://MainMenu.tscn")
