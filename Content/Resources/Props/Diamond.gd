class_name DiamondProp
extends Area2D

export (Array, AudioStream) var pickup_sounds

func _ready():
	var timer = get_tree().create_timer(randf() * 2, false)
	var _err = timer.connect("timeout", self, "handle_loop_anim")
	
	var _err2 = connect("body_entered", self, "on_body_entered")
	

func handle_loop_anim():
	$"AnimationPlayer".play("Loop")


func handle_pickup():
	if pickup_sounds.size():
		var rnd_snd_idx = randi() % pickup_sounds.size()
		var rnd_snd = pickup_sounds[rnd_snd_idx]
		if rnd_snd:
			var asp_2d = AudioStreamPlayer2D.new()
			get_parent().add_child(asp_2d)
			asp_2d.stream = rnd_snd
			asp_2d.pitch_scale += float(randi() % 11) / 10.0
			asp_2d.play()
			asp_2d.connect("finished", asp_2d, "queue_free")


func destroy():
	queue_free()


func on_body_entered(body: Object):
	if not body.has_method("handle_entering"):
		return
	
	var handled = body.call("handle_entering", self)
	if handled:
		handle_pickup()
		destroy()
