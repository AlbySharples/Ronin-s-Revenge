extends CanvasLayer

onready var health_bar = $Control/HealthBar
onready var timer_label = $Control/TimerLabel
onready var shuriken_label = $Control/Shuriken

func _ready():
	health_bar.min_value = 0
	health_bar.max_value = Globals.max_health
	health_bar.percent_visible = false

	update_hud()


func _process(delta):
	# LIVE STOPWATCH
	Globals.elapsed_time += delta

	update_hud()


func update_hud():
	# HEALTH
	health_bar.max_value = Globals.max_health
	health_bar.value = Globals.health

	# STOPWATCH
	var total_seconds = int(Globals.elapsed_time)
	var minutes = int(total_seconds / 60)
	var seconds = total_seconds % 60

	timer_label.text = "%02d:%02d" % [minutes, seconds]

	# SHURIKENS
	shuriken_label.text = "x%d" % Globals.shurikens
