
extends KinematicBody2D

export(PackedScene) var shuriken_scene

export var throw_cooldown = 2.0
export var throw_release_frame = 3
export var max_health = 3

onready var sprite = $AnimatedSprite
onready var spawn_point = $ShurikenSpawn

var health = 0
var throw_timer = 0.0
var is_hurt = false
var is_dead = false
var is_throwing = false
var shuriken_released = false

export(PackedScene) var shuriken_pickup_scene

func _ready():
	health = max_health
	add_to_group("Enemies")

	# Stay facing left.
	sprite.flip_h = true
	spawn_point.position.x = -abs(spawn_point.position.x)

	sprite.play("idle")

	if not sprite.is_connected("frame_changed", self, "_on_frame_changed"):
		sprite.connect("frame_changed", self, "_on_frame_changed")

	if not sprite.is_connected("animation_finished", self, "_on_animation_finished"):
		sprite.connect("animation_finished", self, "_on_animation_finished")


func _physics_process(delta):
	if is_dead or is_hurt:
		return

	throw_timer -= delta

	if throw_timer <= 0:
		start_throw()


func start_throw():
	# Restart the throw animation every cooldown.
	throw_timer = throw_cooldown
	is_throwing = true
	shuriken_released = false

	sprite.play("Throw")
	sprite.frame = 0


func _on_frame_changed():
	if is_dead or is_hurt or not is_throwing:
		return

	if sprite.animation == "Throw":
		if sprite.frame == throw_release_frame and not shuriken_released:
			release_shuriken()


func release_shuriken():
	shuriken_released = true

	if shuriken_scene == null:
		print("ERROR: EnemyShuriken scene not assigned!")
		return

	var shuriken = shuriken_scene.instance()
	get_tree().current_scene.add_child(shuriken)

	shuriken.global_position = spawn_point.global_position
	shuriken.direction = -1


func take_damage(amount):
	if is_dead or is_hurt:
		return

	health -= amount
	is_throwing = false
	shuriken_released = true

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
	is_throwing = false
	shuriken_released = true

	Globals.enemies_defeated += 1

	if shuriken_pickup_scene != null:
		var pickup = shuriken_pickup_scene.instance()
		get_tree().current_scene.add_child(pickup)
		pickup.global_position = global_position

	sprite.play("Death")
	sprite.frame = 0


func _on_animation_finished():
	if sprite.animation == "Death":
		queue_free()

	elif sprite.animation == "TakeHit":
		is_hurt = false
		sprite.play("idle")

	elif sprite.animation == "Throw":
		is_throwing = false
		sprite.play("idle")
