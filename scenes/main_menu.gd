extends Node

@onready var parallax_bg = $ParallaxBackground
@onready var foreground_parallax = $ForegroundParallax
@onready var settings_menu = $SettingsMenu

var scroll_speed : float = 240.0

func _ready():
	# Menyembunyikan menu pengaturan secara otomatis saat game baru dibuka
	if has_node("SettingsMenu"):
		settings_menu.hide()

func _process(delta):
	# Membuat background parallax terus berjalan di menu
	var movement = scroll_speed * delta
	parallax_bg.scroll_base_offset.x -= movement
	if has_node("ForegroundParallax"):
		$ForegroundParallax.scroll_base_offset.x -= movement

func _on_start_button_pressed():
	# Berpindah ke scene utama permainan
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_settings_button_pressed():
	# Memunculkan scene settings
	if has_node("SettingsMenu"):
		settings_menu.show()

func _on_exit_button_pressed():
	# Keluar dari aplikasi
	get_tree().quit()
