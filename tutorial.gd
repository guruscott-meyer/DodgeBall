extends Node3D

var sun_speed = -0.01

var current_scene

# Called when the node enters the scene tree for the first time.
func _ready():
	current_scene = load("res://playground.tscn").instantiate()
	add_child(current_scene)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$LocalSun.rotate_z(sun_speed * delta)
	$LocalSun.rotate_x(sun_speed * delta)
