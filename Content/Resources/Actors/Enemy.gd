extends KinematicBody2D

export (AudioStream) var death_sfx

onready var anim_player := $"AnimationPlayer"

onready var ground_detector_left := $"Ground Detector Left"
onready var ground_detector_right := $"Ground Detector Right"

onready var footstep_snd_emitter := $"Footstep Sound Emitter"

const SPEED = 50.0
const GRAVITY = 100.0

var direction := 1
var _velocity := Vector2()

func _physics_process(delta):
	if not ground_detector_right.is_colliding() and not ground_detector_left.is_colliding():
		direction = 0
	elif not ground_detector_right.is_colliding():
		direction = -1
	elif not ground_detector_left.is_colliding():
		direction = 1
	
	$"Sprite".flip_h = direction == -1
	
	_velocity.x = direction * SPEED
	_velocity.y += GRAVITY * delta
	_velocity = move_and_slide(_velocity, Vector2.UP)
	
	if _velocity.x != 0 and is_on_floor():
		anim_player.play("Walk")
	else:
		anim_player.play("Idle")

func handle_death():
	var sfx = AudioStreamPlayer2D.new()
	get_parent().add_child(sfx)
	sfx.set_as_toplevel(true)
	sfx.stream = death_sfx
	sfx.play()
	sfx.connect("finished", sfx, "queue_free")


func handle_stomping(stomper):
	var handled = stomper is Player
	handle_death()
	queue_free()
	return handled
