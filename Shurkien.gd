
extends Area2D

export var speed = 800
export var damage = 1
export var lifetime = 2.0

var direction = 1
var time_alive = 0.0
var has_hit = false

onready var sprite = $AnimatedSprite


func _ready():
	add_to_group("shurikens")

	sprite.play("Spin", direction == -1)

	if not is_connected("body_entered", self, "_on_body_entered"):
		connect("body_entered", self, "_on_body_entered")


func _physics_process(delta):
	position.x += speed * direction * delta

	time_alive += delta

	if time_alive >= lifetime:
		queue_free()


func _on_body_entered(body):
	if has_hit:
		return

	if body.is_in_group("player"):
		return

	if body.is_in_group("Enemies"):
		has_hit = true

		if body.has_method("take_damage"):
			body.take_damage(damage)

		queue_free()

	elif body is StaticBody2D or body is TileMap:
		has_hit = true
		queue_free()
