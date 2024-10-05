extends CharacterBody3D

signal ball_blocked

var in_neutral_zone

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _physics_process(_delta):
	var collision = move_and_collide(Vector3.ZERO)
	if collision:
		if collision.get_collider().is_in_group("ThrownBall"):
			ball_blocked.emit()
