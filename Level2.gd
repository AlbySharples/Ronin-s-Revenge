
extends Node2D

onready var player = $MainCharacter
onready var enemy1 = $Enemy1
onready var enemy2 = $Enemy2

onready var shuriken_trigger = $ShurikenTutorialTrigger
onready var tutorial_label = $TutorialUI/TutorialLabel
onready var tween = $Tween

var tutorial_stage = 0


func _ready():

	player.lock_controls()

	tutorial_label.hide()
	tutorial_label.modulate.a = 0.0

	enemy1.connect("attack_started", self, "_on_enemy1_attack_started")
	enemy1.connect("defeated", self, "_on_enemy1_defeated")
	enemy2.connect("defeated", self, "_on_enemy2_defeated")

	shuriken_trigger.connect(
		"body_entered",
		self,
		"_on_shuriken_trigger_entered"
	)

	yield(get_tree(), "idle_frame")

	tutorial_stage = 1

	show_message("ENEMIES WILL ATTACK IF YOU GET TOO CLOSE!")

	enemy1.start_encounter(player)


func _on_enemy1_attack_started():
	if tutorial_stage != 1:
		return

	tutorial_stage = 2

	show_message("RIGHT CLICK TO PERFORM A SLASH ATTACK!")

	player.enable_tutorial_attack()


func _on_enemy1_defeated():
	if tutorial_stage != 2:
		return

	tutorial_stage = 3

	# Movement and sword unlocked, shurikens still locked
	player.unlock_controls()

	fade_out_message()


func _on_shuriken_trigger_entered(body):
	if body != player:
		return

	if tutorial_stage != 3:
		return

	tutorial_stage = 4

	# Player must now use shurikens
	player.enable_shuriken_tutorial()

	show_message(
		"ENEMIES AT RANGE CAN BE ATTACKED\n USING THE SHURIKEN THROW!"
	)

	# Change to the control instruction after a short pause
	yield(get_tree().create_timer(2.5), "timeout")

	if tutorial_stage != 4:
		return

	show_message("LEFT CLICK TO THROW A SHURIKEN!")


func _on_enemy2_defeated():
	if tutorial_stage != 4:
		return

	tutorial_stage = 5

	# Everything is now unlocked
	player.unlock_everything()

	fade_out_message()

	print("LEVEL 2 TUTORIAL COMPLETE!")


func show_message(message):
	tutorial_label.text = message
	tutorial_label.show()

	tween.stop_all()
	tutorial_label.modulate.a = 0.0

	tween.interpolate_property(
		tutorial_label,
		"modulate:a",
		0.0,
		1.0,
		0.35,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN_OUT
	)
	tween.start()


func fade_out_message():
	tween.stop_all()

	tween.interpolate_property(
		tutorial_label,
		"modulate:a",
		tutorial_label.modulate.a,
		0.0,
		0.35,
		Tween.TRANS_LINEAR,
		Tween.EASE_IN_OUT
	)
	tween.start()
