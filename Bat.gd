
extends KinematicBody2D

export var detection_range = 350.0
export var fly_speed = 280.0
export var attack_range = 80.0
export var attack_damage = 10
export var attack_cooldown = 0.6
export var target_height = 40.0
export var attack_animation_speed = 2.5

# Idle fluttering settings
export var wander_radius = 70.0
export var wander_speed = 65.0
export var idle_duration = 1.0
export var flutter_duration = 2.0

onready var sprite = $AnimatedSprite

var player = null
var is_attacking = false
var is_dead = false
var attack_timer = 0.0
var damage_dealt = false

var home_position = Vector2.ZERO
var wander_target = Vector2.ZERO
var wander_timer = 0.0
var is_fluttering = false


func _ready():
	randomize()

	add_to_group("Enemies")
	home_position = global_position

	sprite.play("Idle")

	if not sprite.is_connected("animation_finished", self, "_on_animation_finished"):
		sprite.connect("animation_finished", self, "_on_animation_finished")

	find_player()
	start_idle()


func find_player():
	var players = get_tree().get_nodes_in_group("player")

	if players.size() > 0:
		player = players[0]
	else:
		player = null


func get_target_position():
	return player.global_position + Vector2(0, -target_height)


func _physics_process(delta):
	if is_dead:
		return

	attack_timer = max(0.0, attack_timer - delta)

	if not is_instance_valid(player):
		find_player()

	if is_attacking:
		return

	if is_instance_valid(player):
		var difference = get_target_position() - global_position
		var distance = difference.length()

		if distance <= detection_range:
			chase_player(difference, distance, delta)
			return

	# No player nearby: flutter and idle.
	wander(delta)


func chase_player(difference, distance, delta):
	sprite.flip_h = difference.x < 0

	if distance <= attack_range:
		if attack_timer <= 0:
			start_attack()
		else:
			sprite.speed_scale = 1.0

			if sprite.animation != "Idle":
				sprite.play("Idle")
		return

	var movement = difference.normalized() * min(
		fly_speed * delta,
		distance - attack_range
	)

	global_position += movement

	sprite.speed_scale = 1.0

	if sprite.animation != "Fly":
		sprite.play("Fly")


func wander(delta):
	wander_timer -= delta
	sprite.speed_scale = 1.0

	if wander_timer <= 0:
		if is_fluttering:
			start_idle()
		else:
			start_flutter()

	if is_fluttering:
		var difference = wander_target - global_position

		if difference.length() > 3:
			global_position += difference.normalized() * min(
				wander_speed * delta,
				difference.length()
			)

			sprite.flip_h = difference.x < 0

		if sprite.animation != "Fly":
			sprite.play("Fly")
	else:
		if sprite.animation != "Idle":
			sprite.play("Idle")


func start_idle():
	is_fluttering = false
	wander_timer = idle_duration * rand_range(0.7, 1.4)
	sprite.play("Idle")


func start_flutter():
	is_fluttering = true
	wander_timer = flutter_duration * rand_range(0.7, 1.4)

	wander_target = home_position + Vector2(
		rand_range(-wander_radius, wander_radius),
		rand_range(-wander_radius, wander_radius)
	)

	sprite.play("Fly")


func start_attack():
	is_attacking = true
	damage_dealt = false

	sprite.speed_scale = attack_animation_speed
	sprite.play("Attack Windup")
	sprite.frame = 0

	SfxPlayer.play_sfx(preload("res://Sounds/bat.mp3"), -10.0)


func _on_animation_finished():
	if is_dead:
		if sprite.animation == "Death":
			queue_free()
		return

	if sprite.animation == "Attack Windup":
		sprite.speed_scale = attack_animation_speed
		sprite.play("Attack")
		sprite.frame = 0

	elif sprite.animation == "Attack":
		try_damage_player()

		is_attacking = false
		attack_timer = attack_cooldown

		sprite.speed_scale = 1.0
		sprite.play("Idle")


func try_damage_player():
	if damage_dealt:
		return

	if not is_instance_valid(player):
		return

	var distance = global_position.distance_to(get_target_position())

	if distance <= attack_range + 20:
		if player.has_method("take_damage"):
			player.take_damage(attack_damage)
			damage_dealt = true


func take_damage(amount):
	if is_dead:
		return

	die()


func die():
	if is_dead:
		return

	is_dead = true
	is_attacking = false

	# COUNT THIS ENEMY EXACTLY ONCE
	Globals.enemies_defeated += 1

	sprite.speed_scale = 1.0
	sprite.play("Death")
	sprite.frame = 0
