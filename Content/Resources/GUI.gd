extends CanvasLayer

onready var health_display := $"Health Display"
onready var points_display := $"Points Count Display"
func _ready():
	var _err = GlobalSignals.connect("player_health_changed", self, "handle_player_health_change")
	var _err2 = GlobalSignals.connect("player_points_changed", self, "handle_player_points_change")

func handle_player_health_change(new_health):
	if new_health < 0:
		new_health = 0
	
	health_display.value = new_health

func handle_player_points_change(new_value):
	points_display.text = " x%d" % [new_value]
