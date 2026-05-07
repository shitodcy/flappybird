extends Node

@export var pipe_scene : PackedScene

var game_running : bool
var game_over : bool
var scroll : float = 0.0
var score
const SCROLL_SPEED : float = 200.0
var screen_size : Vector2i
var ground_height : int
var pipes : Array
const PIPE_DELAY : int = 500
const PIPE_RANGE : int = 200

# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_window().size
	ground_height = $Ground.get_node("Sprite2D").texture.get_height()
	new_game()

func new_game():
	game_running = false
	game_over = false
	score = 0
	scroll = 0
	$ScoreLabel.text = "SCORE: " + str(score)
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
					print("Pipa dihapus")
			else:
				# Jika pipa sudah hilang tapi masih ada di list
				pipes.remove_at(i)


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
	
func check_top():
	if $Bird.position.y < 0:
		$Bird.falling = true
		stop_game()

func stop_game():
	$PipeTimer.stop()
	$GameOver.show()
	$Bird.flying = false
	game_running = false
	game_over = true

func bird_hit():
	$Bird.falling = true
	stop_game()
	
func _on_ground_hit():
	$Bird.falling = false
	stop_game()

func _on_game_over_restart():
	new_game()
