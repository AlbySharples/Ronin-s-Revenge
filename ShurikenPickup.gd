
extends Area2D

export var shuriken_amount = 3
export var float_height = 6.0
export var float_speed = 3.0

onready var sprite = $Sprite

var starting_y = 0.0
var float_timer = 0.0
var collected = false


func _ready():
	starting_y = sprite.position.y

	connect("body_entered", self, "_on_body_entered")


func _process(delta):
	float_timer += delta * float_speed
	sprite.position.y = starting_y + sin(float_timer) * float_height


func _on_body_entered(body):
	if collected:
		return

	if not body.is_in_group("player"):
		return

	collected = true

	Globals.shurikens = min(
		Globals.shurikens + shuriken_amount,
		Globals.max_shurikens
	)

	SfxPlayer.play_sfx(preload("res://Sounds/shuriken_pickup.mp3"))

	print("Shurikens collected! Total: ", Globals.shurikens)

	queue_free()
