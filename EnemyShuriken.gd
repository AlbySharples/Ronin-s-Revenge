extends Area2D

export var speed = 450.0
export var damage = 10
export var lifetime = 5.0

var direction = 1
var life_timer = 0.0

onready var sprite = $AnimatedSprite


func _ready():
	sprite.play("Spin")

	if not is_connected("body_entered", self, "_on_body_entered"):
		connect("body_entered", self, "_on_body_entered")


func _physics_process(delta):
	position.x += direction * speed * delta

	life_timer += delta

	if life_timer >= lifetime:
		queue_free()


func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)

		queue_free()

	elif body is StaticBody2D:
		queue_free()
