extends CanvasLayer

onready var health_display := $"Health Display"

func _ready():
	GlobalSignals.connect("player_health_changed", self, "handle_player_health_change")

func handle_player_health_change(new_health):
	if new_health < 0:
		new_health = 0
	
	health_display.text = "Health: %d" % [new_health]
