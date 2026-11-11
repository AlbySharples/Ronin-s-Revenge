
extends KinematicBody2D

signal tutorial_enemy_defeated

export var speed = 350
export var jump_force = -600
export var gravity = 950
export var combat_enabled = true

export(PackedScene) var shuriken_scene
export var throw_cooldown = 0.5
export var throw_release_frame = 3

export var sword_range = 350
export var sword_damage = 1
export var sword_hit_frame = 3
export var sword_vertical_range = 1000

export var floor_snap_length = 24.0
export var max_floor_angle = 60.0

onready var sprite = $AnimatedSprite
onready var spawn_point = $ShurikenSpawn

var velocity = Vector2.ZERO
var facing_direction = 1

var is_attacking = false
var is_throwing = false
var is_hurt = false

var shuriken_released = false
var throw_timer = 0.0

var controls_locked = false
var sword_unlocked = true
var shuriken_unlocked = true

var combo_index = 0
var combo_animations = ["Attack1", "Attack3", "Attack2"]
var enemies_hit_this_attack = []


func _ready():
	var level_path = get_tree().current_scene.filename

	if level_path.get_file().begins_with("Level"):
		Globals.heal_for_new_level(level_path)

	add_to_group("player")

	if not sprite.is_connected("animation_finished", self, "_on_animation_finished"):
		sprite.connect("animation_finished", self, "_on_animation_finished")

	if not sprite.is_connected("frame_changed", self, "_on_frame_changed"):
		sprite.connect("frame_changed", self, "_on_frame_changed")

	update_spawn_position()
	sprite.play("Idle")


func lock_controls():
	controls_locked = true
	sword_unlocked = false
	shuriken_unlocked = false
	velocity.x = 0
	is_attacking = false
	is_throwing = false
	shuriken_released = false
	sprite.play("Idle")


func enable_tutorial_attack():
	controls_locked = true
	sword_unlocked = true
	shuriken_unlocked = false


func unlock_controls():
	controls_locked = false
	sword_unlocked = true


func enable_shuriken_tutorial():
	controls_locked = true
	sword_unlocked = false
	shuriken_unlocked = true

	velocity.x = 0
	is_attacking = false
	is_throwing = false
	sprite.play("Idle")


func unlock_everything():
	controls_locked = false
	sword_unlocked = true
	shuriken_unlocked = true


func _input(event):
	if not combat_enabled:
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == BUTTON_RIGHT and sword_unlocked:
			start_attack()

		elif event.button_index == BUTTON_LEFT and shuriken_unlocked:
			start_throw()


func _physics_process(delta):
	throw_timer = max(0.0, throw_timer - delta)

	var movement = 0.0

	if not controls_locked and not is_attacking and not is_throwing and not is_hurt:
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			movement = 1.0
		elif Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			movement = -1.0

	velocity.x = movement * speed

	if movement != 0:
		facing_direction = 1 if movement > 0 else -1
		sprite.flip_h = facing_direction == -1

	update_spawn_position()

	var jumping = false

	if not controls_locked:
		if Input.is_action_just_pressed("jump"):
			if is_on_floor() and not is_attacking and not is_throwing and not is_hurt:
				velocity.y = jump_force
				jumping = true

	if not is_on_floor() or velocity.y < 0:
		if not jumping:
			velocity.y += gravity * delta
	else:
		velocity.y = 0

	var snap = Vector2.DOWN * floor_snap_length
	if velocity.y < 0:
		snap = Vector2.ZERO

	velocity = move_and_slide_with_snap(
		velocity,
		snap,
		Vector2.UP,
		true,
		4,
		deg2rad(max_floor_angle)
	)

	update_animation()


func update_spawn_position():
	pass


func update_animation():
	if is_attacking or is_throwing or is_hurt:
		return

	var next_animation = "Idle"

	if not is_on_floor():
		next_animation = "Jump"
	elif Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		if not controls_locked:
			next_animation = "Move"

	if sprite.animation != next_animation or not sprite.playing:
		sprite.play(next_animation)


func start_attack():
	if not sword_unlocked or not combat_enabled:
		return

	if is_attacking or is_throwing or is_hurt:
		return

	is_attacking = true
	velocity.x = 0
	enemies_hit_this_attack.clear()

	var attack_name = combo_animations[combo_index]
	sprite.play(attack_name)
	sprite.frame = 0

	SfxPlayer.play_sfx(preload("res://Sounds/sword_sfx.wav"))

	combo_index = (combo_index + 1) % 3


func get_hit_center(body):
	var collision = body.get_node_or_null("CollisionShape2D")
	if collision:
		return collision.global_position
	return body.global_position


func get_hit_half_width(body):
	var collision = body.get_node_or_null("CollisionShape2D")

	if collision == null or collision.shape == null:
		return 0.0

	var scale_x = abs(collision.global_scale.x)

	if collision.shape is RectangleShape2D:
		return collision.shape.extents.x * scale_x

	if collision.shape is CapsuleShape2D:
		return collision.shape.radius * scale_x

	if collision.shape is CircleShape2D:
		return collision.shape.radius * scale_x

	return 0.0


func check_sword_hit():
	var enemies = get_tree().get_nodes_in_group("Enemies")
	var player_center = get_hit_center(self)

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		if enemy in enemies_hit_this_attack:
			continue

		if enemy.get("is_dead") == true:
			continue

		if not enemy.has_method("take_damage"):
			continue

		var enemy_center = get_hit_center(enemy)
		var difference = enemy_center - player_center

		if abs(difference.y) > sword_vertical_range:
			continue

		var enemy_half_width = get_hit_half_width(enemy)
		var forward_distance = difference.x * facing_direction

		if forward_distance < -enemy_half_width:
			continue

		if forward_distance > sword_range + enemy_half_width:
			continue

		var accepted = enemy.take_damage(sword_damage)

		if accepted == false:
			continue

		enemies_hit_this_attack.append(enemy)

		SfxPlayer.play_sfx(preload("res://Sounds/sword_hit.mp3"))

		if enemy.get("is_dead") == true:
			emit_signal("tutorial_enemy_defeated")


func start_throw():
	if not shuriken_unlocked or not combat_enabled:
		return

	if is_attacking or is_throwing or is_hurt:
		return

	if throw_timer > 0:
		return

	if shuriken_scene == null:
		print("ERROR: Assign Shuriken.tscn in the Inspector!")
		return

	is_throwing = true
	shuriken_released = false
	velocity.x = 0
	throw_timer = throw_cooldown

	sprite.play("Throw")
	sprite.frame = 0


func spawn_shuriken():
	if shuriken_scene == null:
		return

	if Globals.shurikens <= 0:
		return

	Globals.shurikens -= 1

	var shuriken = shuriken_scene.instance()
	shuriken.direction = facing_direction

	get_tree().current_scene.add_child(shuriken)
	shuriken.global_position = spawn_point.global_position

	SfxPlayer.play_sfx(preload("res://Sounds/shuriken_throw.mp3"))


func _on_frame_changed():
	if is_attacking and sprite.animation in combo_animations:
		if sprite.frame == sword_hit_frame:
			check_sword_hit()

	if is_throwing and sprite.animation == "Throw":
		if sprite.frame == throw_release_frame and not shuriken_released:
			spawn_shuriken()
			shuriken_released = true


func _on_animation_finished():
	if sprite.animation in combo_animations:
		is_attacking = false
	elif sprite.animation == "Throw":
		is_throwing = false
	elif sprite.animation == "Hurt":
		is_hurt = false


func take_damage(amount):
	if is_hurt or Globals.health <= 0:
		return

	Globals.health = max(0, Globals.health - amount)
	print("Player health: ", Globals.health, "/", Globals.max_health)

	is_attacking = false
	is_throwing = false
	shuriken_released = false
	is_hurt = true
	velocity.x = 0

	if Globals.health <= 0:
		die()
		return

	SfxPlayer.play_sfx(preload("res://Sounds/player_hurt.mp3"), -15.0)

	sprite.play("Hurt")
	sprite.frame = 0


func die():
	SfxPlayer.play_sfx(preload("res://Sounds/player_death.mp3"))
	print("PLAYER DEFEATED!")
	game_over()


func game_over():
	var current_level = get_tree().current_scene.filename
	var level_name = current_level.get_file().get_basename()

	var level_number = int(level_name.replace("Level", ""))
	var checkpoint_number = int(level_number / 10) * 10 + 1

	Globals.last_level = "res://Level" + str(checkpoint_number) + ".tscn"

	get_tree().change_scene("res://GameOver.tscn")
