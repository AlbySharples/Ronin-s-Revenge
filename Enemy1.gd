
extends KinematicBody2D

signal attack_started
signal defeated

export var walk_speed = 100
export var gravity = 950
export var attack_distance = 100
export var max_health = 1

# Turn this OFF for Enemy2
export var tutorial_melee_enemy = true

onready var sprite = $AnimatedSprite

var velocity = Vector2.ZERO
var player = null

var health = 1
var is_attacking = false
var attack_finished = false
var active = false
var is_hurt = false
var is_dead = false


func _ready():
	randomize()
	health = max_health

	add_to_group("Enemies")

	sprite.play("idle")

	if not sprite.is_connected("animation_finished", self, "_on_animation_finished"):
		sprite.connect("animation_finished", self, "_on_animation_finished")


func start_encounter(player_node):
	if is_dead or not tutorial_melee_enemy:
		return

	player = player_node
	active = true
	attack_finished = false
	is_attacking = false


func _physics_process(delta):
	if is_dead:
		return

	velocity.y += gravity * delta
	velocity.x = 0

	if active and is_instance_valid(player) and not attack_finished and not is_hurt:
		var distance = player.global_position.x - global_position.x

		if is_attacking:
			pass

		elif abs(distance) > attack_distance:
			velocity.x = sign(distance) * walk_speed
			sprite.flip_h = distance < 0

			if sprite.animation != "Move":
				sprite.play("Move")

		else:
			start_random_attack()

	elif not is_attacking and not is_hurt:
		if sprite.animation != "idle":
			sprite.play("idle")

	velocity = move_and_slide(velocity, Vector2.UP)


func start_random_attack():
	if is_attacking or attack_finished or is_dead or is_hurt:
		return

	is_attacking = true
	velocity.x = 0

	var attack_name = "Attack1"

	if randi() % 2 == 1:
		attack_name = "Attack2"

	sprite.play(attack_name)
	sprite.frame = 0

	SfxPlayer.play_sfx(preload("res://Sounds/enemy_sword.mp3"))

	emit_signal("attack_started")


func take_damage(amount):
	if is_dead or is_hurt:
		return

	health -= amount
	is_attacking = false
	active = false
	velocity.x = 0

	if health <= 0:
		die()
	else:
		is_hurt = true
		sprite.play("TakeHit")
		sprite.frame = 0


func die():
	if is_dead:
		return

	is_dead = true
	active = false
	is_attacking = false
	velocity.x = 0

	Globals.enemies_defeated += 1

	emit_signal("defeated")

	sprite.play("Death")
	sprite.frame = 0


func _on_animation_finished():
	if sprite.animation == "Death":
		queue_free()

	elif sprite.animation == "TakeHit":
		is_hurt = false
		sprite.play("idle")

	elif sprite.animation == "Attack1" or sprite.animation == "Attack2":
		is_attacking = false
		attack_finished = true
		active = false
		sprite.play("idle")
