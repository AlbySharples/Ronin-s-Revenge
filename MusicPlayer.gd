
extends Node

onready var music = $AudioStreamPlayer

func play_music(track, start_time = 0.0):
	if music.stream == track and music.playing:
		return

	music.stop()
	music.stream = track
	music.volume_db = -5.0
	music.play(start_time)


func stop_music():
	music.stop()
