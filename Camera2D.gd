
extends Camera2D

export(NodePath) var player_path
export(NodePath) var background_path

onready var player = get_node(player_path)
onready var background = get_node(background_path)

var shift_threshold = 200
var left_threshold = 200
var scroll_speed = 300

var target_x = 0.0


func _ready():
	var background_rect = background.get_rect()

	var top_left = background.to_global(background_rect.position)
	var bottom_right = background.to_global(
		background_rect.position + background_rect.size
	)

	limit_left = int(min(top_left.x, bottom_right.x))
	limit_right = int(max(top_left.x, bottom_right.x))
	limit_top = int(min(top_left.y, bottom_right.y))
	limit_bottom = int(max(top_left.y, bottom_right.y))

	global_position = player.global_position
	target_x = global_position.x


func _process(delta):
	if not is_instance_valid(player):
		return

	var screen_center_x = get_camera_screen_center().x
	var player_x = player.global_position.x

	if player_x > screen_center_x + shift_threshold:
		target_x = player_x - shift_threshold

	elif player_x < screen_center_x - left_threshold:
		target_x = player_x + left_threshold

	global_position.x = lerp(
		global_position.x,
		target_x,
		min(1.0, 8.0 * delta)
	)


func _on_BoxxIntroTrigger_body_entered(body):
	pass
