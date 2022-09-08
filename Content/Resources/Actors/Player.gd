class_name Player
extends KinematicBody2D

const GRAVITY = 150.0
const JUMP_SPEED = 50.0

onready var anim_player := $"AnimationPlayer"

onready var footstep_snd_emitter := $"Footstep Sound Emitter"
onready var jump_snd_emitter := $"Jump Sound Emitter"
onready var fall_snd_emitter := $"Fall Sound Emitter"

onready var stomp_detector := $"Stomp Detector"

var speed := Vector2(80, 100)

var _velocity := Vector2()
var last_direction := Vector2()
var was_on_air := false # not is_on_floor() on the last frame

var health := 20.0
var points := 0

func _ready():
	GlobalSignals.call_deferred("emit_signal", "player_health_changed", health)
	GlobalSignals.call_deferred("emit_signal", "player_points_changed", points)

func _physics_process(delta):
	var direction = get_direction()
	
	if stomp_detector.is_colliding():
		var stomped_obj = stomp_detector.get_collider()
		if stomped_obj.has_method("handle_stomping"):
			var directon_to_enemy = global_position.direction_to(stomped_obj.global_position)
			var dot_dte_vel = directon_to_enemy.dot(_velocity)
			
			if dot_dte_vel > 0:
				var handled = stomped_obj.call("handle_stomping", self)
				if handled:
					# jump after stomping
					direction.y = -1
					jump_snd_emitter.play()
	
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


func handle_death():
	queue_free()

# TODO: refactor damage/enter system
func handle_entering(body: CollisionObject2D):
	if body is DiamondProp:
		points += 1
		GlobalSignals.emit_signal("player_points_changed", points)
		return true
	return false

func handle_receive_damage(damager: Object):
	var damage = damager.call("get_damage_caused")
	var direction = damager.global_position.direction_to(global_position)
	var _vel = move_and_slide(direction * 500) # push
	health -= damage
	GlobalSignals.emit_signal("player_health_changed", health)
	
	if health <= 0:
		handle_death()
