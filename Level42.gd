
extends Node2D

export var camera_pan_duration = 2.5
export var boss_pause_duration = 1.0
export var dialogue_duration = 3.0

onready var player = $MainCharacter
onready var boss = $Boss
onready var camera = $Camera2D

onready var boss_dialogue = $BossUI/BossDialogue
onready var boss_health_bar = $BossUI/BossHealthBar
onready var boss_bar = $BossUI/BossBar
onready var boss_name = $BossUI/Label

var intro_started = false
var fight_started = false

var intro_camera_start = Vector2.ZERO
var camera_from = Vector2.ZERO
var camera_to = Vector2.ZERO
var camera_elapsed = 0.0
var camera_moving = false

var intro_stage = 0
var stage_timer = 0.0

var dialogue_world_position = Vector2.ZERO


func _ready():
	# Remember dialogue position from editor.
	dialogue_world_position = boss_dialogue.rect_position

	# Hide boss UI until the fight begins.
	boss_dialogue.hide()
	boss_health_bar.hide()
	boss_bar.hide()
	boss_name.hide()

	# Lock boss before the introduction.
	boss.intro_locked = true

	call_deferred("start_boss_intro")


func start_boss_intro():
	if intro_started:
		return

	intro_started = true
		# START KUROKAGE BOSS MUSIC
	MusicPlayer.play_music(preload("res://Music/boss.mp3"))


	# Disable normal camera follow.
	camera.set_process(false)
	camera.set_physics_process(false)

	# Freeze player and boss.
	player.set_physics_process(false)
	player.set_process_input(false)
	player.set_process_unhandled_input(false)

	boss.intro_locked = true
	boss.set_physics_process(false)

	# Keep both characters idle.
	var player_sprite = player.get_node_or_null("AnimatedSprite")
	if player_sprite:
		player_sprite.play("Idle")

	var boss_sprite = boss.get_node_or_null("AnimatedSprite")
	if boss_sprite:
		boss_sprite.play("Idle")

	intro_camera_start = camera.global_position

	begin_camera_pan(boss.global_position)
	intro_stage = 1

	print("INTRO: Moving to boss")


func begin_camera_pan(target):
	camera_from = camera.global_position
	camera_to = target
	camera_elapsed = 0.0
	camera_moving = true


func _process(delta):
	# Update boss health during fight.
	if fight_started:
		boss_health_bar.value = max(0, boss.health)
		return

	if not intro_started:
		return

	# Move camera smoothly.
	if camera_moving:
		camera_elapsed += delta

		var progress = min(
			camera_elapsed / max(camera_pan_duration, 0.01),
			1.0
		)

		var eased = progress * progress * (3.0 - 2.0 * progress)

		camera.global_position = camera_from.linear_interpolate(
			camera_to,
			eased
		)

		if progress >= 1.0:
			camera_moving = false

			if intro_stage == 1:
				intro_stage = 2
				stage_timer = boss_pause_duration
				print("INTRO: Camera reached boss")

			elif intro_stage == 4:
				finish_intro()

		return

	# Pause on boss.
	if intro_stage == 2:
		stage_timer -= delta

		if stage_timer <= 0:
			show_boss_dialogue()
			intro_stage = 3
			stage_timer = dialogue_duration

			print("INTRO: Boss speaking")

	# Finish dialogue and return camera.
	elif intro_stage == 3:
		stage_timer -= delta

		if stage_timer <= 0:
			boss_dialogue.hide()

			# Prepare boss health bar.
			boss_health_bar.min_value = 0
			boss_health_bar.max_value = boss.max_health
			boss_health_bar.value = boss.health

			# Show boss UI.
			boss_health_bar.show()
			boss_bar.show()
			boss_name.show()

			# Return camera to player.
			intro_stage = 4
			begin_camera_pan(intro_camera_start)

			print("INTRO: Returning to player")


func show_boss_dialogue():
	boss_dialogue.text = "You've come a long way, shinobi...\nOnly to meet your end."

	# Convert editor position to screen position.
	var screen_size = get_viewport_rect().size
	var camera_center = camera.get_camera_screen_center()

	boss_dialogue.rect_position = (
		dialogue_world_position
		- camera_center
		+ screen_size / 2.0
	)

	boss_dialogue.show()


func finish_intro():
	intro_stage = 5
	fight_started = true


	# Restore camera following.
	camera.set_process(true)
	camera.set_physics_process(true)

	# Unlock player.
	player.set_physics_process(true)
	player.set_process_input(true)
	player.set_process_unhandled_input(true)

	# IMPORTANT: Unlock boss BEFORE enabling physics.
	boss.intro_locked = false
	boss.set_physics_process(true)

	print("BOSS FIGHT STARTED")
