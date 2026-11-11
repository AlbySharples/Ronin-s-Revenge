
extends KinematicBody2D

export var patrol_distance = 200.0
export var patrol_speed = 90.0
export var chase_speed = 170.0
export var detection_range = 350.0

export var attack_range = 160.0
export var attack_damage = 15
export var attack_cooldown = 1.5
export var attack_hit_frame = 8

export var max_health = 3
export var gravity = 950.0

onready var sprite = $AnimatedSprite

var velocity = Vector2.ZERO
var player = null

var start_position = Vector2.ZERO
var patrol_direction = 1
var facing_direction = 1

var health = 0
var attack_timer = 0.0

var is_attacking = false
var is_hurt = false
var is_dead = false
var damage_dealt = false


func _ready():
	add_to_group("Enemies")

	start_position = global_position
	health = max_health

	sprite.play("Idle")

	if not sprite.is_connected("animation_finished", self, "_on_animation_finished"):
		sprite.connect("animation_finished", self, "_on_animation_finished")

	if not sprite.is_connected("frame_changed", self, "_on_frame_changed"):
		sprite.connect("frame_changed", self, "_on_frame_changed")

	find_player()


func find_player():
	var players = get_tree().get_nodes_in_group("player")

	if players.size() > 0:
		player = players[0]
	else:
		player = null


func _physics_process(delta):
	if is_dead:
		return

	attack_timer = max(0.0, attack_timer - delta)

	velocity.y += gravity * delta

	if not is_instance_valid(player):
		find_player()

	if is_attacking or is_hurt:
		velocity.x = 0
		velocity = move_and_slide(velocity, Vector2.UP)
		return

	if is_instance_valid(player):
		var difference = player.global_position - global_position
		var horizontal_distance = abs(difference.x)
		var vertical_distance = abs(difference.y)

		if horizontal_distance <= detection_range and vertical_distance <= 120:
			chase_player(difference, horizontal_distance)
		else:
			patrol()
	else:
		patrol()

	velocity = move_and_slide(velocity, Vector2.UP)


# ----------------------------------
# PATROL
# ----------------------------------

func patrol():
	if global_position.x >= start_position.x + patrol_distance:
		patrol_direction = -1

	elif global_position.x <= start_position.x - patrol_distance:
		patrol_direction = 1

	velocity.x = patrol_direction * patrol_speed

	set_facing(patrol_direction)
	play_animation("Walk")


# ----------------------------------
# CHASE AND ATTACK
# ----------------------------------

func chase_player(difference, horizontal_distance):
	var direction = 1 if difference.x > 0 else -1

	set_facing(direction)

	if horizontal_distance <= attack_range:
		velocity.x = 0

		if attack_timer <= 0:
			start_attack()
		else:
			play_animation("Idle")

	else:
		velocity.x = direction * chase_speed
		play_animation("Walk")


func start_attack():
	is_attacking = true
	damage_dealt = false
	velocity.x = 0

	sprite.play("Attack")
	sprite.frame = 0

	SfxPlayer.play_sfx(preload("res://Sounds/yellow_attack.mp3"), -10.0)


func _on_frame_changed():
	if is_dead:
		return

	if is_attacking and sprite.animation == "Attack":
		if sprite.frame >= attack_hit_frame and not damage_dealt:
			try_damage_player()


func try_damage_player():
	damage_dealt = true

	if not is_instance_valid(player):
		return

	var difference = player.global_position - global_position

	var horizontal_distance = abs(difference.x)
	var vertical_distance = abs(difference.y)

	var player_direction = 1 if difference.x > 0 else -1

	if player_direction != facing_direction:
		return

	if horizontal_distance > attack_range:
		return

	if vertical_distance > 120:
		return

	if player.has_method("take_damage"):
		player.take_damage(attack_damage)


# ----------------------------------
# DAMAGE AND DEATH
# ----------------------------------

func take_damage(amount):
	if is_dead:
		return

	health -= amount

	if health <= 0:
		die()
		return

	is_hurt = true
	is_attacking = false
	velocity.x = 0

	sprite.play("TakeHit")
	sprite.frame = 0


func die():
	if is_dead:
		return

	is_dead = true
	is_attacking = false
	is_hurt = false

	velocity = Vector2.ZERO

	# COUNT THIS ENEMY EXACTLY ONCE
	Globals.enemies_defeated += 1

	sprite.play("Death")
	sprite.frame = 0


# ----------------------------------
# ANIMATION EVENTS
# ----------------------------------

func _on_animation_finished():
	if sprite.animation == "Death":
		queue_free()
		return

	if is_dead:
		return

	if sprite.animation == "Attack":
		is_attacking = false
		attack_timer = attack_cooldown
		play_animation("Idle")

	elif sprite.animation == "TakeHit":
		is_hurt = false
		play_animation("Idle")


func play_animation(animation_name):
	if sprite.animation != animation_name:
		sprite.play(animation_name)


func set_facing(direction):
	facing_direction = direction
	sprite.flip_h = direction < 0
