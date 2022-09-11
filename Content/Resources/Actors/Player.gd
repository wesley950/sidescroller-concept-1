class_name Player
extends KinematicBody2D

const GRAVITY = 150.0
const GRAVITY_WALL = 15.0
const JUMP_SPEED = 50.0

onready var anim_player := $"AnimationPlayer"

onready var footstep_snd_emitter := $"Footstep Sound Emitter"
onready var jump_snd_emitter := $"Jump Sound Emitter"
onready var fall_snd_emitter := $"Fall Sound Emitter"

onready var stomp_detector := $"Stomp Detector"
onready var left_wall_detector := $"Left Wall Detector"
onready var right_wall_detector := $"Right Wall Detector"

var speed := Vector2(80, 100)

var _velocity := Vector2()
var last_direction := Vector2()
var was_on_air := false # not is_on_floor() on the last frame
var wall_jump_x_dir := 0
var current_gravity := GRAVITY

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
		_velocity.y *= 0.8
	
	if not is_on_floor():
		if Input.is_action_just_pressed("jump"):
			if left_wall_detector.is_colliding():
				direction.y = -1
				wall_jump_x_dir = 1
			elif right_wall_detector.is_colliding():
				direction.y = -1
				wall_jump_x_dir = -1
			else:
				wall_jump_x_dir = 0
	else:
		wall_jump_x_dir = 0
	
	# in case the player wants to cancel the wall sliding
	if direction.x != 0 and (not left_wall_detector.is_colliding() or not right_wall_detector.is_colliding()):
		wall_jump_x_dir = direction.x
	
	if wall_jump_x_dir == 0:
		_velocity.x = direction.x * speed.x
		$"Graphics/Player".flip_h = direction.x < 0
	else:
		_velocity.x = wall_jump_x_dir * speed.x
		$"Graphics/Player".flip_h = wall_jump_x_dir < 0
		
	if direction.y != 0: 
		_velocity.y = direction.y * speed.y
	
	_velocity = move_and_slide(_velocity, Vector2.UP)
	
	if (left_wall_detector.is_colliding() or right_wall_detector.is_colliding()) and _velocity.y > 0:
		current_gravity = GRAVITY_WALL
	else:
		current_gravity = GRAVITY
		
	_velocity.y += current_gravity * delta
	
	if _velocity.x != 0 and is_on_floor():
		anim_player.play("Walk")
	else:
		anim_player.play("Idle")
	
	if last_direction.y == 0 and direction.y != 0:
		jump_snd_emitter.play()
	
	if was_on_air and is_on_floor():
		fall_snd_emitter.play()
	
	# always update this lastly!
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
