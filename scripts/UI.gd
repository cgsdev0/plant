extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var events = get_node("/root/Events")
var should_draw = false
var mouse_start

# Called when the node enters the scene tree for the first time.
func _ready():
	events.connect("cut_start", self, "on_cut_start")
	events.connect("cut_stop", self, "on_cut_stop")

func on_cut_stop():
	should_draw = false
	update()
	
func on_cut_start(start):
	should_draw = true
	mouse_start = start
	update()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if should_draw:
		update()
			
func _draw():
	if should_draw:
		draw_line(mouse_start, get_global_mouse_position(), Color.red, 4)
