extends Node

@export var pipe_scene : PackedScene

var game_running : bool
var game_over : bool
var scroll : float = 0.0
var score : int
var high_score : int = 0
var SCROLL_SPEED : float = 240.0
var screen_size : Vector2i
var ground_height : int
var pipes : Array
const PIPE_DELAY : int = 500
const PIPE_RANGE : int = 200
const SAVE_PATH = "user://highscore.save"

# Referensi Node
@onready var camera = $Camera2D
@onready var bgm = $BGM # Pastikan node bernama "BGM" sudah ditambahkan di main.tscn
@onready var settings_menu = $SettingsMenu # Pastikan scene settings.tscn sudah di-instantiate dengan nama ini

var shake_intensity : float = 0.0
var shake_duration : float = 0.0

func trigger_shake(intensity: float, duration: float):
	shake_intensity = intensity
	shake_duration = duration

func _ready():
	screen_size = get_window().size
	ground_height = 164 
	
	# Sembunyikan menu pengaturan saat awal game dibuka
	if has_node("SettingsMenu"):
		settings_menu.hide()
		
	load_high_score()
	new_game()

func new_game():
	game_running = false
	game_over = false
	score = 0
	scroll = 0
	SCROLL_SPEED = 240.0 
	
	# Memutar BGM
	if has_node("BGM"):
		bgm.play()
		
	$ScoreLabel.text = "SCORE: " + str(score)
	update_high_score_label()
	$GameOver.hide()
	get_tree().call_group("pipes", "queue_free")
	pipes.clear()
	generate_pipes()
	$Bird.reset()
	
func _input(event):
	# Memastikan event adalah penekanan tombol keyboard
	if event is InputEventKey and event.pressed:
		
		# --- SHORTCUT BUKA SETTINGS (Tombol 'S') ---
		if event.keycode == KEY_S:
			# Hanya bisa dibuka jika menu belum terbuka
			if settings_menu != null and not settings_menu.visible:
				_on_settings_button_pressed() # Memanggil fungsi tombol settings (otomatis pause)
				
		# --- SHORTCUT TUTUP SETTINGS (Tombol 'Esc') ---
		elif event.keycode == KEY_ESCAPE:
			# Hanya bisa ditutup jika menu sedang terbuka
			if settings_menu != null and settings_menu.visible:
				settings_menu.hide()
				# Game tetap dalam keadaan pause (menunggu spasi)
				
		# --- LOMPAT & UNPAUSE (Tombol 'Spasi') ---
		elif event.keycode == KEY_SPACE:
			
			# 1. Cegah spasi melakukan apa pun jika menu pengaturan sedang terbuka
			if settings_menu != null and settings_menu.visible:
				return
				
			# 2. Logika Unpause (Melanjutkan game jika sedang dipause)
			if get_tree().paused:
				get_tree().paused = false
				return # Return di sini agar burung tidak ikut lompat di frame yang sama saat unpause
				
			# 3. Logika Utama Flappy Bird (Hanya berjalan jika game tidak over)
			if game_over == false:
				if game_running == false:
					start_game()
				else:
					if $Bird.flying:
						$Bird.flap()
						check_top()

func start_game():
	game_running = true
	$Bird.flying = true
	$Bird.flap()
	$PipeTimer.start()

func _process(delta):
	# Jika mesin game sedang pause, jangan jalankan pergerakan pipa/background
	if get_tree().paused:
		return

	if game_running:
		var movement = SCROLL_SPEED * delta 
		
		# Pergerakan Parallax
		$ParallaxBackground.scroll_base_offset.x -= movement
		$ForegroundParallax.scroll_base_offset.x -= movement
		
		# Pergerakan Pipa
		for i in range(pipes.size() - 1, -1, -1):
			var pipe = pipes[i]
			if is_instance_valid(pipe):
				pipe.position.x -= movement
				if pipe.position.x < -100: 
					pipe.queue_free()   
					pipes.remove_at(i)  
			else:
				pipes.remove_at(i)

	# Logika Shake tetap berjalan (opsional)
	if shake_duration > 0:
		shake_duration -= delta
		camera.offset = Vector2(
			randf_range(-shake_intensity, shake_intensity), 
			randf_range(-shake_intensity, shake_intensity)
		)
	else:
		camera.offset = Vector2.ZERO

func _on_pipe_timer_timeout():
	generate_pipes()

func generate_pipes():
	var pipe = pipe_scene.instantiate()
	pipe.position.x = screen_size.x + PIPE_DELAY
	pipe.position.y = (screen_size.y - ground_height) /2 + randi_range(-PIPE_RANGE, PIPE_RANGE)
	pipe.hit.connect(bird_hit)
	pipe.scored.connect(scored)
	add_child(pipe)
	pipes.append(pipe)
	
func scored():
	score += 1
	$ScoreLabel.text = "SCORE: " + str(score)
	$ScoreSound.play() 
	
	if score >= 50 and score <= 100:
		SCROLL_SPEED += 2.0 
	elif score > 100:
		SCROLL_SPEED += 3.0 
	
func check_top():
	if $Bird.position.y < 0:
		$Bird.falling = true
		stop_game()
		
func save_high_score():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_var(high_score)

func load_high_score():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		high_score = file.get_var()

func update_high_score_label():
	if has_node("HighScoreLabel"):
		$HighScoreLabel.text = "HIGH SCORE: " + str(high_score)

func stop_game():
	$PipeTimer.stop()
	
	# Menghentikan BGM saat burung mati
	if has_node("BGM"):
		bgm.stop()
		
	# 1. CEK DAN SIMPAN HIGHSCORE DULU SEBELUM DIKIRIM
	if score > high_score:
		high_score = score
		save_high_score()
		# Opsional: update_high_score_label() jika kamu ingin teks di belakang ikut berubah
		
	# 2. SETELAH DISIMPAN, BARU KIRIM DATANYA KE PAPAN GAME OVER
	if has_node("GameOver"):
		$GameOver.set_scores(score, high_score)
		$GameOver.show()
		
	$Bird.flying = false
	game_running = false
	game_over = true

func bird_hit():
	$HitSound.play() 
	trigger_shake(5.0, 0.2)
	$Bird.falling = true
	stop_game()
	
func _on_ground_hit():
	$HitSound.play() 
	trigger_shake(5.0, 0.2)
	$Bird.falling = false
	stop_game()

func _on_game_over_restart():
	new_game()

func _on_settings_button_pressed():
	if settings_menu != null:
		# Jika game sedang berjalan, aktifkan mode pause pada engine
		if game_running:
			get_tree().paused = true
		settings_menu.show()
	else:
		print("Peringatan: Node SettingsMenu tidak ditemukan!") 
