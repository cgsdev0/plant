extends Sprite3D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export var max_size = 0.01
export var growth_span = 5.0
export var life_color: Color
export var death_color: Color
export var disease_color: Color
export var healthy_death_color_gradient: Gradient
var healthy_death_color

var growth = 0

var predropped = false
var dropped = false
var diseased = false
onready var events = get_node("/root/Events")

var rng = RandomNumberGenerator.new()
var spawned_by
var rng_lifespan
var rng_colorize
# Called when the node enters the scene tree for the first time.
func _ready():
	if diseased:
		modulate = disease_color
		texture = preload("res://assets/diseased.png")
	rng.randomize()
	rng_lifespan = rng.randf_range(0, 20) + 40
	if diseased:
		rng_lifespan /= 10
		max_size *= 1.4
	rng_colorize = rng.randf_range(-5, 5) + 12
	healthy_death_color = healthy_death_color_gradient.interpolate(rng.randf_range(0, 1))
	pass # Replace with function body.


var z_vel = 1
var z_accel = 2.0
var x_vel = 2
var x_accel = -2.0
func _process(delta):
	growth += delta
	var health_percent = 1
	if is_instance_valid(spawned_by) && spawned_by.get_script():
		health_percent = spawned_by.health / spawned_by.starting_health
		pixel_size = lerp(0, max(pixel_size, lerp(max_size / 3, max_size, health_percent)), clamp(growth / growth_span, 0, 1))
		if !predropped && !diseased:
			modulate = life_color.linear_interpolate(
				healthy_death_color, clamp((growth - 20) / (rng_colorize), 0, 1)).linear_interpolate(
					death_color, 1 - health_percent
				)
	if dropped:
		get_parent().translation.y -= delta
		get_parent().translation.z += delta * z_vel
		get_parent().translation.x -= delta * x_vel
		z_vel += z_accel * delta
		x_vel += x_accel * delta
		if get_parent().translation.y < -15:
			get_parent().queue_free()
	if (growth > (rng_lifespan) * (health_percent / 2 + 0.5)) && !predropped:
		predropped = true
		yield(get_tree().create_timer(3.0), "timeout")
		$AnimationPlayer.play("PreDrop")
		yield(get_tree().create_timer(2.0), "timeout")
		dropped = true
		$AnimationPlayer.play("Fall1")
		events.emit_signal("drop_leaf", get_parent())
		if is_instance_valid(spawned_by) && spawned_by.get_script() && spawned_by.has_method("lose_leaf"):
			spawned_by.lose_leaf(diseased)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
