extends CharacterBody3D

signal spawn_loose_ball

var speed = 10 + PlayerData.difficulty

var selected = false

var ball_type = "ball_blocker"
var thrown_ball = true

var ball_team: String
var ball_owner

func _get(property):
	if property == "ball_type":
		return ball_type

func initialize(direction, team_owner, mob):
	#print("Blocker initialized")
	velocity = PlayerData.my_normalize(direction) * speed
	ball_team = team_owner
	ball_owner = mob
	
func _physics_process(delta):
	#velocity.y -= fall_acceleration
	#print(position.y, " ", global_position.y)
	
	var collision = move_and_collide(velocity * delta)
	
	if collision and collision.get_collider() != null:
		$AudioStreamPlayer3D.play()
		if collision.get_collider().is_in_group("Court") or collision.get_collider().is_in_group("ThrownBall"):
			var vector = velocity.bounce(collision.get_normal())
			spawn_loose_ball.emit("ball_blocker", global_position, vector)
			die()
		elif collision.get_collider().is_in_group("Mob"):
			if ball_owner == null:
				collision.get_collider().die("blocker")
			else:
				var vector = velocity.bounce(collision.get_normal())
				spawn_loose_ball.emit("ball_blocker", global_position, vector)
				die()				
			
		velocity = velocity.bounce(collision.get_normal())
	
func highlight(is_selected):
	selected = is_selected
	if is_selected:
		$Highlight.set_visible(true)
	else:
		$Highlight.set_visible(false)
	
func die():
	queue_free()
