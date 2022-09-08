extends KinematicBody2D

const GRAVITY = 150.0
const JUMP_SPEED = 50.0

onready var anim_player := $"AnimationPlayer"

onready var footstep_snd_emitter := $"Footstep Sound Emitter"
onready var jump_snd_emitter := $"Jump Sound Emitter"
onready var fall_snd_emitter := $"Fall Sound Emitter"

var speed := Vector2(80, 100)

var _velocity := Vector2()
var last_direction := Vector2()
var was_on_air := false # not is_on_floor() on the last frame

func _physics_process(delta):
	var direction = get_direction()
	
	var jump_interrupted := Input.is_action_just_released("jump") and _velocity.y < 0.0
	
	if jump_interrupted:
		_velocity.y *= 0.3
	
	_velocity.x = direction.x * speed.x
	if direction.y != 0: 
		_velocity.y = direction.y * speed.y
		
	$"Graphics/Player".flip_h = direction.x < 0
		
	_velocity = move_and_slide(_velocity, Vector2.UP)
	_velocity.y += GRAVITY * delta
	
	if _velocity.x != 0 and is_on_floor():
		anim_player.play("Walk")
	else:
		anim_player.play("Idle")
	
	if last_direction.y == 0 and direction.y != 0:
		jump_snd_emitter.play()
	
	if was_on_air and is_on_floor():
		fall_snd_emitter.play()
	
	last_direction = direction
	was_on_air = not is_on_floor()

func get_direction():
	return Vector2(Input.get_axis("move_left", "move_right"), -1 if Input.is_action_just_pressed("jump") and is_on_floor() else 0)


func handle_entering(body: CollisionObject2D):
	return body is DiamondProp
