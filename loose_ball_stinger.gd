extends RigidBody3D

signal spawn

var ball_type = "ball_stinger"
var ball_team = ""
var ball_owner = null
var thrown_ball = false

var selected = false

func initialize(vector):
	apply_central_impulse(vector)

func _init():
	contact_monitor = true
	max_contacts_reported = 3
	
func _integrate_forces(_status):
	pass

func highlight(is_selected):
	selected = is_selected
	if is_selected:
		$Highlight.set_visible(true)
	else:
		$Highlight.set_visible(false)

func _on_body_entered(_node):
	$AudioStreamPlayer3D.play()

func die():
	queue_free()
