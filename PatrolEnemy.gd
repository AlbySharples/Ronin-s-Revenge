
extends KinematicBody2D

export var patrol_distance = 250.0
export var patrol_speed = 45.0
export var chase_speed = 110.0
export var detection_range = 450.0
export var attack_range = 120.0
export var sword_damage = 10
export var max_health = 3
export var gravity = 950.0

export var attack_cooldown = 0.8
export var sword_hit_frame = 3
export var hurt_recovery_time = 0.2

onready var sprite = $AnimatedSprite
onready var sword_hitbox = $SwordHitbox

var velocity = Vector2.ZERO
var player = null

var start_x = 0.0
var patrol_direction = 1
var health = 0

var is_attacking = false
var is_hurt = false
var is_dead = false
var has_hit_player = false

var attack_timer = 0.0
var hurt_timer = 0.0

var hitbox_start_x = 0.0


func _ready():
	randomize()

	start_x = global_position.x
	health = max_health
	add_to_group("Enemies")

	hitbox_start_x = abs(sword_hitbox.position.x)

	sprite.play("idle")

	if not sprite.is_connected("animation_finished", self, "_on_animation_finished"):
		sprite.connect("animation_finished", self, "_on_animation_finished")

	if not sprite.is_connected("frame_changed", self, "_on_frame_changed"):
		sprite.connect("frame_changed", self, "_on_frame_changed")

	find_player()
	update_facing(patrol_direction)


func find_player():
	var players = get_tree().get_nodes_in_group("player")

	if players.size() > 0:
		player = players[0]
	else:
		player = null


func _physics_process(delta):
	if is_dead:
		return

	if not is_instance_valid(player):
		find_player()

	attack_timer = max(0.0, attack_timer - delta)

	velocity.y += gravity * delta
	velocity.x = 0

	if is_hurt:
		hurt_timer -= delta

		if hurt_timer <= 0:
			is_hurt = false
			attack_timer = 0.0
			sprite.play("idle")
		else:
			apply_movement()
			return

	if is_attacking:
		apply_movement()
		return

	var chasing = false

	if is_instance_valid(player):
		var difference = player.global_position - global_position
		var distance_x = abs(difference.x)

		if distance_x <= detection_range:
			chasing = true

			update_facing(sign(difference.x))

			if distance_x <= attack_range:
				if attack_timer <= 0:
					start_attack()
			else:
				velocity.x = sign(difference.x) * chase_speed

	if not chasing:
		patrol()

	apply_movement()

	if not is_attacking and not is_hurt:
		if abs(velocity.x) > 1:
			if sprite.animation != "Move":
				sprite.play("Move")
		else:
			if sprite.animation != "idle":
				sprite.play("idle")


func apply_movement():
	var snap = Vector2.DOWN * 20

	if velocity.y < 0:
		snap = Vector2.ZERO

	velocity = move_and_slide_with_snap(
		velocity,
		snap,
		Vector2.UP
	)


func patrol():
	if global_position.x >= start_x + patrol_distance:
		patrol_direction = -1

	elif global_position.x <= start_x - patrol_distance:
		patrol_direction = 1

	velocity.x = patrol_direction * patrol_speed
	update_facing(patrol_direction)


func update_facing(direction):
	if direction == 0:
		return

	sprite.flip_h = direction < 0
	sword_hitbox.position.x = hitbox_start_x * sign(direction)
	sword_hitbox.scale.x = sign(direction)


func start_attack():
	is_attacking = true
	has_hit_player = false
	velocity.x = 0
	attack_timer = attack_cooldown

	var attack_name = "Attack1"

	if randi() % 2 == 1:
		attack_name = "Attack2"

	sprite.play(attack_name)
	sprite.frame = 0

	SfxPlayer.play_sfx(preload("res://Sounds/enemy_sword.mp3"))


func _on_frame_changed():
	if not is_attacking or has_hit_player or is_dead:
		return

	if sprite.animation != "Attack1" and sprite.animation != "Attack2":
		return

	if sprite.frame == sword_hit_frame:
		try_hit_player()


func try_hit_player():
	for body in sword_hitbox.get_overlapping_bodies():
		if body.is_in_group("player"):
			if body.has_method("take_damage"):
				body.take_damage(sword_damage)
				has_hit_player = true
				print("Enemy sword connected! Damage: ", sword_damage)
				return


func take_damage(amount):
	if is_dead or is_hurt:
		return

	health -= amount
	is_attacking = false
	velocity.x = 0

	if health <= 0:
		die()
	else:
		is_hurt = true
		hurt_timer = hurt_recovery_time
		sprite.play("TakeHit")
		sprite.frame = 0


func die():
	if is_dead:
		return

	is_dead = true
	is_attacking = false
	velocity.x = 0

	Globals.enemies_defeated += 1

	sprite.play("Death")
	sprite.frame = 0


func _on_animation_finished():
	if sprite.animation == "Death":
		queue_free()

	elif sprite.animation == "TakeHit":
		is_hurt = false
		attack_timer = 0.0
		sprite.play("idle")

	elif sprite.animation == "Attack1" or sprite.animation == "Attack2":
		is_attacking = false
		sprite.play("idle")
