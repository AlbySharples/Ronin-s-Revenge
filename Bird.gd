extends Area2D

export var fly_speed = 250.0
export var damage = 10
export var direction = -1
export var lifetime = 8.0

onready var sprite = $AnimatedSprite

var life_timer = 0.0


func _ready():
	sprite.play("Fly")
	sprite.flip_h = direction == 1

	if not is_connected("body_entered", self, "_on_body_entered"):
		connect("body_entered", self, "_on_body_entered")


func _physics_process(delta):
	global_position.x += direction * fly_speed * delta

	life_timer += delta

	if life_timer >= lifetime:
		queue_free()


func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
