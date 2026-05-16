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

# Health system
var health : int = 3
var max_health : int = 3
var is_immune : bool = false
const IMMUNITY_DURATION : float = 1.5
const HEALTH_ICON_SIZE : Vector2 = Vector2(32, 32)

@onready var camera = $Camera2D
@onready var bgm = $BGM
@onready var settings_menu = $SettingsMenu
@onready var health_container = $HealthContainer
@onready var immunity_timer = $ImmunityTimer
@onready var health_icon_template = $HealthContainer/HealthIconTemplate

var shake_intensity : float = 0.0
var shake_duration : float = 0.0

func trigger_shake(intensity: float, duration: float):
	shake_intensity = intensity
	shake_duration = duration

func _ready():
	screen_size = get_window().size
	ground_height = 164 
	
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
	health = max_health
	is_immune = false
	immunity_timer.stop()
	
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
	$Bird.set_immune_visual(false)
	update_health_ui()
	
func _input(event):
	if event is InputEventKey and event.pressed:

		if event.keycode == KEY_S:
			if settings_menu != null and not settings_menu.visible:
				_on_settings_button_pressed()

		elif event.keycode == KEY_ESCAPE:
			if settings_menu != null and settings_menu.visible:
				settings_menu.hide()

		elif event.keycode == KEY_SPACE:
			
			if settings_menu != null and settings_menu.visible:
				return
				
			# Logika Unpause
			if get_tree().paused:
				get_tree().paused = false
				return
				
			# Logika Utama
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

	# Logika Shake tetap berjalan
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
	
	if game_over == true:
		return
		
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
		
	if score > high_score:
		high_score = score
		save_high_score()

	if has_node("GameOver"):
		$GameOver.set_scores(score, high_score)
		$GameOver.show()
		
	$Bird.flying = false
	game_running = false
	game_over = true

func bird_hit():
	
	if game_over == true:
		return
	
	if is_immune:
		return
		
	health -= 1
	update_health_ui()
	
	$HitSound.play() 
	trigger_shake(5.0, 0.2)
	
	if health <= 0:
		$Bird.falling = true
		stop_game()
	else:
		# Reset posisi burung ke tengah setelah terkena
		$Bird.position = Vector2($Bird.START_POS.x, screen_size.y / 2 - 50)
		$Bird.velocity = Vector2.ZERO
		$Bird.falling = false
		
		# Mulai immunity window
		is_immune = true
		$Bird.set_immune_visual(true)
		immunity_timer.start(IMMUNITY_DURATION)
	
func _on_ground_hit():
	
	if game_over == true:
		return
	
	$HitSound.play() 
	trigger_shake(5.0, 0.2)
	$Bird.falling = false
	stop_game()

func _on_immunity_timer_timeout():
	is_immune = false
	$Bird.set_immune_visual(false)

func update_health_ui():
	health_icon_template.hide()
	for child in health_container.get_children():
		if child != health_icon_template:
			child.queue_free()
	
	for i in range(health):
		var icon = health_icon_template.duplicate()
		icon.visible = true
		icon.modulate = Color.WHITE
		health_container.add_child(icon)
	
	health_container.move_child(health_icon_template, 0)

func _on_game_over_restart():
	new_game()

func _on_settings_button_pressed():
	if settings_menu != null:
		if game_running:
			get_tree().paused = true
		settings_menu.show()
