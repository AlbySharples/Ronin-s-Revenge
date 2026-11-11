
extends Sprite

export var fade_in_duration = 0.5
export var display_duration = 2.0
export var fade_out_duration = 0.5

onready var tween = Tween.new()


func _ready():
	add_child(tween)

	modulate.a = 0.0

	tween.interpolate_property(
		self, "modulate:a",
		0.0, 1.0,
		fade_in_duration,
		Tween.TRANS_SINE,
		Tween.EASE_IN_OUT
	)

	tween.interpolate_property(
		self, "modulate:a",
		1.0, 0.0,
		fade_out_duration,
		Tween.TRANS_SINE,
		Tween.EASE_IN_OUT,
		fade_in_duration + display_duration
	)

	tween.start()
