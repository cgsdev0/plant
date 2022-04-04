extends Spatial


onready var events = get_node("/root/Events")


func on_leaf_drop(leaf):
	var transformation = leaf.get_global_transform()
	leaf.get_parent().remove_child(leaf)
	add_child(leaf)
	leaf.set_global_transform(transformation)

func on_branch_drop(branch):
	branch.pot_ref = $PlantAndPot/Pot
	self.add_child(branch)
	$CutSound.play()
	
var defaultPianoVol
# Called when the node enters the scene tree for the first time.
func _ready():
	defaultPianoVol = $PianoLoop.volume_db
	events.connect("drop_leaf", self, "on_leaf_drop")
	events.connect("unlock_branch", self, "on_branch_drop")
	pass # Replace with function body.

func get_object_under_point(p: Vector2):
	var ray_from = $Camera.project_ray_origin(p)
	var ray_to = ray_from + $Camera.project_ray_normal(p) * 300
	var space_state = get_world().direct_space_state
	var selection = space_state.intersect_ray(ray_from, ray_to)
	return selection
	
func get_object_under_segment(start: Vector2, end: Vector2):
	var best_dist = 1000000
	var best_bet
	var safety_check_start = get_object_under_point(start)
	var safety_check_end = get_object_under_point(end)
	for i in range(100):
		var p = lerp(start, end, i / 100.0)
		var selection = get_object_under_point(p)
		if selection && selection.collider:
			if selection && selection.collider && selection.collider.get_owner() && selection.collider.get_owner().get("uncuttable"):
				continue
			if safety_check_end && safety_check_end.collider == selection.collider:
				continue
			if safety_check_start && safety_check_start.collider == selection.collider:
				continue
			var dist = $Camera.project_ray_origin(p).distance_to(selection.position)
			if dist < best_dist:
				best_dist = dist
				best_bet = selection
	return best_bet
	
var pot_clicked = false
var pot_start

var can_clicked = false
var end_state = false
var pend_state = false

var startable = true

func _process(_delta):
	if $PlantAndPot/Plant.get_child_count() == 0 || pend_state:
		return
	var base_stem = $PlantAndPot/Plant.get_child(0)
	if base_stem.health <= 0 && !end_state:
		end_state = true
		$Control/GameOver.modulate = Color.transparent
		$Control/GameOver.visible = true
		$Control/GameOver/AnimationPlayer.play("fadeIn")
		$PianoLoop/AnimationPlayer.play("fadeOut")
		yield(get_tree().create_timer(1.8), "timeout")
		$PianoLoop.stop()
		
var cut_start
func _input(event):
	if event is InputEventKey && event.scancode == KEY_ENTER && event.pressed && end_state:
		end_state = false
		pend_state = true
		$Control/GameOver/AnimationPlayer.play("fadeOut")
		$PlantAndPot/AnimationPlayer.play("Yeet")
		$TossSound.play()
		yield(get_tree().create_timer(1.0), "timeout")
		$CrashSound.play()
		for child in $PlantAndPot/Plant.get_children():
			$PlantAndPot/Plant.remove_child(child)
			child.queue_free()
		$Control/GameOver.visible = false
		pend_state = false
		yield(get_tree().create_timer(3.0), "timeout")
		startable = true
		return
	if event is InputEventMouseMotion && pot_clicked:
		var diff = get_viewport().get_mouse_position().x - pot_start
		pot_start = get_viewport().get_mouse_position().x
		$PlantAndPot.rotate_y(diff * 0.005)
	if event is InputEventMouseButton && !event.pressed && event.button_index == 1:
		if pot_clicked || can_clicked:
			can_clicked = false
			pot_clicked = false
			return
		events.emit_signal("cut_stop")
		var sel = get_object_under_segment(cut_start, get_viewport().get_mouse_position())
		if sel && sel.collider && sel.collider.get_owner() && sel.collider.get_owner().has_method("unlock"):
			sel.collider.get_owner().unlock()
	if event is InputEventMouseButton && event.pressed && event.button_index == 1:
		var sel = get_object_under_point(get_viewport().get_mouse_position())
		
		if sel && sel.collider && sel.collider.get_name() == "WateringCan":
			can_clicked = true
			if startable:
				startable = false
			else:
				return
			$WateringCan/AnimationPlayer.play("Water")
			$WateringCan/StartSound.play()
			yield(get_tree().create_timer(1.0), "timeout")
			$WateringCan/Control/Particles.emitting = true
			yield(get_tree().create_timer(2.0), "timeout")
			var starting_stem = preload("res://stem.tscn").instance()
			starting_stem.set_script(preload("res://scripts/StemGrowth.gd"))
			starting_stem.uncuttable = true
			$PlantAndPot/Plant.add_child(starting_stem)
			starting_stem.translation.y += 0.5
			yield(get_tree().create_timer(1.0), "timeout")
			$WateringCan/Control/Particles.emitting = false
			yield(get_tree().create_timer(3.0), "timeout")
			$PianoLoop.volume_db = defaultPianoVol
			$PianoLoop.play()
		elif sel && sel.collider && sel.collider.get_name() == "Pot":
			pot_clicked = true
			pot_start = get_viewport().get_mouse_position().x
		else:
			cut_start = get_viewport().get_mouse_position()
			events.emit_signal("cut_start", get_viewport().get_mouse_position())
