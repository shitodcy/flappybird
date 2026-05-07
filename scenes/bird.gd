extends CharacterBody2D

const GRAVITY : int = 1000
const MAX_VEL : int = 600
const FLAP_SPEED : int = -400
var flying : bool = false
var falling : bool = false
const START_POS = Vector2(100, 400)

func _ready():
	reset()
	
func reset():
	falling = false
	flying = false
	position = START_POS
	set_rotation(0)

func _physics_process(delta):
	if flying or falling:
		velocity.y += GRAVITY * delta
		
		if velocity.y > MAX_VEL:
			velocity.y = MAX_VEL
		if flying:
			# Menghitung target rotasi berdasarkan kecepatan jatuh
			var target_rotation = deg_to_rad(velocity.y * 0.05)
			
			# Mengubah rotasi perlahan (0.1 adalah beban beratnya, makin kecil makin lambat)
			rotation = lerp_angle(rotation, target_rotation, 0.1)
			
			$AnimatedSprite2D.play()
		elif falling:
			set_rotation(PI/2)
			$AnimatedSprite2D.stop()
		move_and_collide(velocity * delta)
	else:
		$AnimatedSprite2D.stop()
			
func flap():
	# Menambah kecepatan ke atas
	velocity.y += FLAP_SPEED 
	
	# Batas agar tidak melesat terlalu cepat ke atas
	if velocity.y < FLAP_SPEED:
		velocity.y = FLAP_SPEED
