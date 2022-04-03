extends TextureButton

func _pressed():
	OS.window_fullscreen = !OS.window_fullscreen
