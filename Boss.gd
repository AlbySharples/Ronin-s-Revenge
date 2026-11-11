
extends KinematicBody2D

export var max_health = 20
export var run_speed = 150.0
export var gravity = 950.0

export var attack_range = 150.0
export var idle_start_range = 130.0
export var attack_damage = 1
export var attack_cooldown = 2.0
export var attack_hit_frame = 3
export var attack_windup = 0.5

export var dodge_distance = 130.0
export var dash_speed = 900.0
export var dash_duration = 0.35
export var dash_cooldown = 2.0

export var phase_two_speed_multiplier = 1.25

var phase_two = false

var health = 20
var velocity = Vector2.ZERO
var player = null
var facing_direction = -1

var intro_locked = true
var is_dead = false
var is_dashing = false
var is_attacking = false
var is_winding_up = false

var attack_timer = 0.0
var windup_timer = 0.0
var dash_timer = 0.0
var dash_time_left = 0.0
var dash_direction = -1

var attack_has_hit = false
var ignored_startup_shurikens = []

onready var sprite = $AnimatedSprite


func _ready():
	add_to_group("Enemies")
	health = max_health

	ignored_startup_shurikens = get_tree().get_nodes_in_group("shurikens")

	if not sprite.is_connected("animation_finished", self, "_on_animation_finished"):
		sprite.connect("animation_finished", self, "_on_animation_finished")

	if not sprite.is_connected("frame_changed", self, "_on_frame_changed"):
		sprite.connect("frame_changed", self, "_on_frame_changed")

	find_player()
	sprite.play("Idle")


func find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]


func face_player():
	if not is_instance_valid(player):
		return

	var difference_x = player.global_position.x - global_position.x

	if difference_x < 0:
		facing_direction = -1
	elif difference_x > 0:
		facing_direction = 1

	sprite.flip_h = facing_direction == -1


func get_distance_to_player():
	if not is_instance_valid(player):
		return INF

	return abs(player.global_position.x - global_position.x)


func get_speed_multiplier():
	if phase_two:
		return phase_two_speed_multiplier
	return 1.0


func _physics_process(delta):
	if is_dead:
		return

	if intro_locked:
		velocity.x = 0
		set_animation("Idle")
		return

	var speed_multiplier = get_speed_multiplier()

	attack_timer = max(0.0, attack_timer - delta)
	dash_timer = max(0.0, dash_timer - delta)

	if not is_instance_valid(player):
		find_player()

	velocity.y += gravity * delta

	if is_dashing:
		dash_time_left -= delta
		velocity.x = dash_direction * dash_speed * speed_multiplier
		velocity = move_and_slide(velocity, Vector2.UP)

		if dash_time_left <= 0:
			end_dash()
		return

	if is_winding_up:
		velocity.x = 0
		windup_timer -= delta

		face_player()
		set_animation("Idle")
		velocity = move_and_slide(velocity, Vector2.UP)

		if windup_timer <= 0:
			is_winding_up = false
			start_attack_animation()

		return

	if is_attacking:
		velocity.x = 0
		velocity = move_and_slide(velocity, Vector2.UP)
		return

	if not is_instance_valid(player):
		velocity.x = 0
		set_animation("Idle")
		velocity = move_and_slide(velocity, Vector2.UP)
		return

	check_for_incoming_shurikens()

	if is_dashing:
		return

	face_player()
	var distance = get_distance_to_player()

	if distance <= attack_range:
		velocity.x = 0
		set_animation("Idle")

		if attack_timer <= 0:
			begin_attack_windup()

		velocity = move_and_slide(velocity, Vector2.UP)
		return

	velocity.x = facing_direction * run_speed * speed_multiplier
	velocity = move_and_slide(velocity, Vector2.UP)

	set_animation("Run")


func begin_attack_windup():
	is_winding_up = true
	windup_timer = attack_windup / get_speed_multiplier()
	velocity.x = 0
	set_animation("Idle")


func set_animation(animation_name):
	if sprite.animation != animation_name or not sprite.playing:
		sprite.play(animation_name)


func start_attack_animation():
	is_attacking = true
	attack_has_hit = false
	attack_timer = attack_cooldown / get_speed_multiplier()
	velocity.x = 0

	sprite.play("Attack1")
	sprite.frame = 0

	SfxPlayer.play_sfx(preload("res://Sounds/kurokage_attack.mp3"))


func _on_frame_changed():
	if is_dead or intro_locked:
		return

	if is_attacking and sprite.animation == "Attack1":
		if sprite.frame == attack_hit_frame and not attack_has_hit:
			attack_has_hit = true
			check_attack_hit()


func check_attack_hit():
	if not is_instance_valid(player):
		return

	var difference = player.global_position - global_position
	var forward_distance = difference.x * facing_direction

	if forward_distance >= 0 and forward_distance <= attack_range:
		if player.has_method("take_damage"):
			player.take_damage(attack_damage)


func _on_animation_finished():
	if sprite.animation == "Death" and is_dead:
		Globals.game_completed = true
		get_tree().call_deferred("change_scene", "res://Victory.tscn")
		return

	if is_dead or intro_locked:
		return

	if sprite.animation == "Attack1":
		is_attacking = false
		set_animation("Idle")


func check_for_incoming_shurikens():
	if dash_timer > 0 or is_dashing or is_attacking or is_winding_up:
		return

	for shuriken in get_tree().get_nodes_in_group("shurikens"):
		if not is_instance_valid(shuriken):
			continue
		if not shuriken is Area2D:
			continue
		if shuriken in ignored_startup_shurikens:
			continue
		if shuriken.get("has_hit") != false:
			continue

		var projectile_speed = shuriken.get("speed")
		var projectile_direction = shuriken.get("direction")

		if projectile_speed == null or projectile_direction == null:
			continue

		var projectile_velocity = projectile_speed * projectile_direction

		if abs(projectile_velocity) < 100:
			continue

		var difference = global_position - shuriken.global_position

		if difference.x * projectile_velocity <= 0:
			continue
		if abs(shuriken.global_position.y - global_position.y) > 65:
			continue
		if abs(difference.x) > dodge_distance:
			continue

		start_dash(-projectile_direction)
		return


func start_dash(direction):
	if intro_locked or is_dashing or is_dead:
		return

	is_dashing = true
	is_attacking = false
	is_winding_up = false

	dash_timer = dash_cooldown / get_speed_multiplier()
	dash_time_left = dash_duration / get_speed_multiplier()
	dash_direction = direction
	facing_direction = direction

	sprite.flip_h = facing_direction == -1

	if is_instance_valid(player):
		add_collision_exception_with(player)

	sprite.play("Dash")
	sprite.frame = 0


func end_dash():
	is_dashing = false
	velocity.x = 0

	if is_instance_valid(player):
		remove_collision_exception_with(player)

	set_animation("Idle")


func take_damage(amount):
	if is_dead or intro_locked or is_dashing:
		return false

	health = max(0, health - amount)
	print("Boss health: ", health, "/", max_health)

	if not phase_two and health > 0 and health <= max_health / 2.0:
		activate_phase_two()

	if health <= 0:
		die()

	return true


func activate_phase_two():
	phase_two = true

	sprite.speed_scale = phase_two_speed_multiplier

	attack_timer /= phase_two_speed_multiplier
	dash_timer /= phase_two_speed_multiplier

	print("KUROKAGE PHASE 2 ACTIVATED!")


func die():
	if is_dead:
		return

	is_dead = true
	is_attacking = false
	is_winding_up = false
	is_dashing = false
	velocity.x = 0

	if is_instance_valid(player):
		remove_collision_exception_with(player)

	Globals.enemies_defeated += 1

	sprite.play("Death")
	sprite.frame = 0
