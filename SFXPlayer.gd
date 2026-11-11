
extends Node


func play_sfx(sound: AudioStream, volume_db := 0.0):
	var player = AudioStreamPlayer.new()

	player.pause_mode = Node.PAUSE_MODE_PROCESS

	add_child(player)

	player.bus = "Master"
	player.stream = sound
	player.volume_db = volume_db

	player.connect("finished", player, "queue_free")

	player.play()
