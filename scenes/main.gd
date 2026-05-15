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

@onready var camera = $Camera2D # Mengambil referensi node Camera2D

var shake_intensity : float = 0.0
var shake_duration : float = 0.0

func trigger_shake(intensity: float, duration: float):
	shake_intensity = intensity
	shake_duration = duration

# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_window().size
	ground_height = $Ground.get_node("Sprite2D").texture.get_height()
	load_high_score()
	new_game()

func new_game():
	game_running = false
	game_over = false
	score = 0
	scroll = 0
	SCROLL_SPEED = 240.0 # <-- Tambahkan baris ini untuk mereset kecepatan
	$ScoreLabel.text = "SCORE: " + str(score)
	update_high_score_label()
	$GameOver.hide()
	get_tree().call_group("pipes", "queue_free")
	pipes.clear()
	generate_pipes()
	$Bird.reset()
	
func _input(event):
	if game_over == false:
		if event is InputEventKey:
			if event.pressed and event.keycode == KEY_SPACE:
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
	if game_running:
		var movement = SCROLL_SPEED * delta 
		
		scroll += movement
		
		# Reset scroll untuk loop background ground
		if scroll >= screen_size.x:
			scroll = 0
			
		# Pindahkan posisi ground
		$Ground.position.x = -scroll
		
		# Loop mundur (backwards) agar saat menghapus isi array, 
		# index-nya tidak berantakan.
		for i in range(pipes.size() - 1, -1, -1):
			var pipe = pipes[i]
			
			# Memastikan pipa masih ada sebelum digerakkan
			if is_instance_valid(pipe):
				pipe.position.x -= movement
				
				# Hapus pipa
				if pipe.position.x < -100: 
					pipe.queue_free()   # Hapus dari game
					pipes.remove_at(i)  # Hapus dari daftar Array
			else:
				# Jika pipa sudah hilang tapi masih ada di list
				pipes.remove_at(i)

	# --- LOGIKA SHAKE (Di luar if game_running agar tetap bergetar saat mati) ---
	if shake_duration > 0:
		shake_duration -= delta
		# Menggeser offset kamera secara acak berdasarkan intensitas
		camera.offset = Vector2(
			randf_range(-shake_intensity, shake_intensity), 
			randf_range(-shake_intensity, shake_intensity)
		)
	else:
		# Kembalikan offset ke 0,0 jika getaran selesai agar layar kembali normal
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
	$ScoreSound.play() # Memutar efek suara saat skor bertambah
	
	if score >= 50 and score <= 100:
		SCROLL_SPEED += 2.0 # Tambah kecepatan 1 poin per skor
	elif score > 100:
		SCROLL_SPEED += 3.0 # Tambah kecepatan 4 poin per skor
	
func check_top():
	if $Bird.position.y < 0:
		$Bird.falling = true
		stop_game()
		
func save_high_score():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_var(high_score)

# Fungsi untuk memuat high score dari file
func load_high_score():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		high_score = file.get_var()

# Fungsi untuk mengupdate UI High Score
func update_high_score_label():
	
	if has_node("HighScoreLabel"):
		$HighScoreLabel.text = "HIGH SCORE: " + str(high_score)

func stop_game():
	$PipeTimer.stop()
	if score > high_score:
		high_score = score
		save_high_score()
	$GameOver.show()
	$Bird.flying = false
	game_running = false
	game_over = true

func bird_hit():
	$HitSound.play() # Memutar suara tabrakan
	trigger_shake(5.0, 0.2)
	$Bird.falling = true
	stop_game()
	
func _on_ground_hit():
	$HitSound.play() # Memutar suara tabrakan saat kena tanah
	trigger_shake(5.0, 0.2)
	$Bird.falling = false
	stop_game()

func _on_game_over_restart():
	new_game()
