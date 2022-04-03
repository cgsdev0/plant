extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var events = get_node("/root/Events")

export var uncuttable = false
export var target_height = 0.23
export var target_radius = 0.025
export var growth_span = 10.0
export var radius_ratio = 2
export var radius_ease = 1.5
export var height_ease = 0.4

var generation = 5

var mature = false

var start_radius
var start_height
var growth = 0
var ind = 0
var spawned_by
var diseased = false

var rng = RandomNumberGenerator.new()

var origin = Vector3(0,0,0)

var health
var starting_health

var leaf_count = 0

var friend_count = 0
var rand_twist
	
func unlock():
	if generation == 5 && ind == 0:
		return
	if is_instance_valid(spawned_by) && spawned_by.has_method("gen_friend"):
		spawned_by.gen_friend(ind, true)
	var body = RigidBody.new()
	var offset = Vector3(0, 0, 0)
	var transformation = self.get_global_transform()
	body.set_script(preload("res://scripts/BranchDeleter.gd"))
	events.emit_signal("unlock_branch", body)
	body.set_global_transform(transformation)

	for child in get_children():
		remove_child(child)
		body.add_child(child)
		child.translation -= offset
		
	var thing = body.get_global_transform().origin - body.pot_ref.get_global_transform().origin
	thing.y = 0
	var unit = thing.normalized()
	if unit == Vector3.ZERO:
		var kid = body.get_child(0)
		unit = kid.get_global_transform().translated(Vector3(0, kid.height / 2, 0)).origin
		unit.y = 0
		unit = unit.normalized()
	if unit == Vector3.ZERO:
		unit = Vector3.FORWARD.rotated(Vector3.UP, rng.randf_range(0, 2 * PI))
	body.apply_impulse(Vector3(0, 1, 0), unit * rng.randf_range(1, 2.4))
	print(unit)
	
	set_script(null)
	queue_free()

# Called when the node enters the scene tree for the first time.

var final_color: Color
func _ready():

	health = float(max(1, generation - 2))
	if generation == 5:
		health += 3.6
	starting_health = health
	final_color = Color(0.39, 0.27, 0.14)
	origin = translation
	rng.randomize()
	rand_twist = rng.randf_range(0, PI)
	growth_span += rng.randf_range(-6.0, 4.0)
	target_height *= pow(generation, 1.3)
	target_radius *= pow(generation, 1.3)
	make_unique()
	
var material: SpatialMaterial = null
var start_color: Color

func make_unique():
	material = $Render.material.duplicate()
	$Render.material = material
	$Render/Occluder.material = material
	start_color = material.albedo_color

func gen_friend(i, delay):

	if delay:
		if health <= 0:
			friend_count -= 1
			return
		health -= 0.5
		yield(get_tree().create_timer(1.0 + 0.6 * (starting_health - health)), "timeout")
	else:
		friend_count += 1
	var friend = preload("res://stem.tscn").instance()
	friend.set_script(self.get_script())
	friend.generation = generation - 1
	friend.ind = i
	friend.spawned_by = self
	self.add_child(friend)
	friend.health = min((health / starting_health) * friend.starting_health, friend.health)
	if i > 0 || generation == 2:
		friend.translation.y += target_height * rng.randf_range(0.3 + i / 10.0, 0.4 + i / 10.0)
		friend.rotate_x(rng.randf_range(PI / 9, PI / 3))
		
		var y_split = (float(i) / float(max(1, generation - 2)) * PI * 2 + rand_twist)
		y_split += rng.randf_range(-PI / 4, PI / 4)
		while y_split > 2 * PI:
			y_split -= 2 * PI
		friend.rotate_y(y_split)
	else:
		pass
		friend.rotate_x(rng.randf_range(0, PI / 10))
		friend.rotate_y(rng.randf_range(0, 2 * PI))
		friend.translation.y += target_height * 0.95

func spawn_friends():
	if generation < 3:
		return
	for i in range(generation - 1):
		gen_friend(i, false)
		


		# create joint
#		var joint = Generic6DOFJoint.new()
#		joint.translation = friend.translation
#		get_parent().add_child(joint)
#		joint.set_param_x(Generic6DOFJoint.PARAM_LINEAR_LOWER_LIMIT, -20.0)
#		joint.set_param_x(Generic6DOFJoint.PARAM_LINEAR_UPPER_LIMIT, 20.0)
#		joint.set_param_z(Generic6DOFJoint.PARAM_LINEAR_LOWER_LIMIT, -20.0)
#		joint.set_param_z(Generic6DOFJoint.PARAM_LINEAR_UPPER_LIMIT, 20.0)
#		joint.set_flag_x(Generic6DOFJoint.FLAG_ENABLE_ANGULAR_SPRING, true)
#		joint.set_flag_z(Generic6DOFJoint.FLAG_ENABLE_ANGULAR_SPRING, true)
#		joint.set_param_x(Generic6DOFJoint.PARAM_ANGULAR_SPRING_STIFFNESS, 10)
#		joint.set_param_z(Generic6DOFJoint.PARAM_ANGULAR_SPRING_STIFFNESS, 10)
#		joint.set_param_x(Generic6DOFJoint.PARAM_ANGULAR_SPRING_DAMPING, 1)
#		joint.set_param_z(Generic6DOFJoint.PARAM_ANGULAR_SPRING_DAMPING, 1)
#		joint.set_node_a(self.get_path())
#		joint.set_node_b(friend.get_path())
		

		yield(get_tree().create_timer(growth_span), "timeout")
	
var wait = 0

func add_new_leaf():
	var new_leaf = preload("res://leaf_scene.tscn").instance()
	new_leaf.translation.y += rng.randf_range(0.2, clamp(growth / growth_span, 0, 1)) * target_height
	new_leaf.rotate_x(rng.randf_range(-PI / 6, PI / 6))
	new_leaf.rotate_z(rng.randf_range(-PI / 6, PI / 6))
	new_leaf.rotate_y(rng.randf_range(0, 2 * PI))
	new_leaf.get_node("Sprite3D").spawned_by = self
	if friend_count == 0:
		if events.disease_counter > 0:
			events.disease_counter = rng.randi_range(-40, -30)
			new_leaf.get_node("Sprite3D").diseased = true
		else:
			events.disease_counter += 1
	add_child(new_leaf)
	leaf_count += 1
	
func lose_leaf(disease: bool):
	leaf_count -= 1
	if disease:
		diseased = true
	elif friend_count > 0 && health > 0:
		if rng.randi_range(0, 10) > 3:
			add_new_leaf()
	elif friend_count == 0 && health > 0:
		add_new_leaf()
		
var prev_health = -1

func _process(delta):
	growth += delta
	wait += delta
	material.albedo_color = start_color.linear_interpolate(
		final_color, clamp((growth - growth_span / 2) / 15.0, 0, 1
		)).linear_interpolate(Color(0.3, 0.3, 0.3), (starting_health - health) / float(starting_health) / 1.5)
	if growth >= growth_span / 4 && growth < growth_span * 2 && wait >= 0 && health > 0:
		wait = - rng.randf_range(0.6, 0.9) * generation * 2.7
		add_new_leaf()
	if mature && health > 0 && diseased:
		health -= 0.25 * delta
	if mature && health <= 0 && diseased && is_instance_valid(spawned_by) && spawned_by.get_script():
		spawned_by.diseased = true
	if health != prev_health:
		prev_health = health
		for child in get_children():
			if child.get("health") && (child.health / child.starting_health) > (health / starting_health):
				child.health = min((health / starting_health) * child.starting_health, child.health)
	if health <= 0:
		health = 0
		growth += delta * 4
	if mature && growth >= growth_span:
		return
	if health > 0:
		$Render/Occluder.translation.y = lerp(0, target_height, ease(clamp(growth / growth_span, 0, 1), height_ease))
		$Render.radius = lerp(0.015, target_radius, ease(clamp(growth / growth_span / radius_ratio, 0, 1), radius_ease))
	if growth >= 3 * growth_span / 4 && !mature:
		mature = true
		spawn_friends()
		
	# mass += delta
	# scale.y = lerp(start_height, target_height, ease(clamp(growth / growth_span, 0, 1), height_ease))
	# $RigidBody.scale.x = lerp(start_radius, target_radius, ease(clamp(growth / growth_span / radius_ratio, 0, 1), radius_ease))
	pass
