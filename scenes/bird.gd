extends CharacterBody2D

const GRAVITY : int = 800
const MAX_VEL : int = 600      
const FLAP_SPEED : int = -260
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
			var target_rotation = deg_to_rad(velocity.y * 0.05)
			set_rotation(deg_to_rad(velocity.y * 0.02))
			$AnimatedSprite2D.play()
		elif falling:
			set_rotation(PI/2)
			$AnimatedSprite2D.stop()
		move_and_collide(velocity * delta)
	else:
		$AnimatedSprite2D.stop()
			
func flap():
	velocity.y = FLAP_SPEED
	
	if velocity.y < FLAP_SPEED:
		velocity.y = FLAP_SPEED
