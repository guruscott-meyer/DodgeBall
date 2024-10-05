extends CharacterBody3D

signal ranged_attack
signal mob_score
signal picked_up_ball
signal player_look
signal player_move
signal ball_switch
signal ball_blocked
signal ball_caught
signal player_ducked
signal pause

@export var speed = 10.0
@export var gravity = 9.8
@export var mouse_sensitivity = 0.01
@export var inventory_count = 2

var ball_type = 0

var inventory = Array([])
var inventory_active_index = 0
var inventory_active_item = ""

var new_ball: Node

var selected_balls = []

var in_neutral_zone = false
var blocking = false
var game_started = false

var last_collision

func _ready():
	#print($Pivot.global_position.y)
	#print("origin: " + String.num($Pivot/ModelPivot/BallModel.global_position.y))
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CAPTURED)
	$BallPickupArea/CollisionShape3D.shape.radius = 3.5 - (PlayerData.difficulty * 0.5)

func _physics_process(delta):
	var target_velocity = Vector3.ZERO
	
	var input_direction = Vector3.ZERO
	input_direction.x = Input.get_action_strength("move_left") - Input.get_action_strength("move_right")
	input_direction.z = Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	input_direction = PlayerData.my_normalize(input_direction)
	
	var movement_direction = Vector3.ZERO
	
	if input_direction != Vector3.ZERO:
		movement_direction = input_direction.rotated(Vector3.UP, $Pivot.rotation.y)
		player_move.emit()
		
	if not blocking:
		target_velocity = movement_direction * speed
	else:
		target_velocity = Vector3.ZERO

	# Vertical Velocity
	if not is_on_floor(): # If in the air, fall towards the floor. Literally gravity
		target_velocity.y -= gravity * delta
	# Jumping.
	if Input.is_action_just_pressed("dodge"):
		duck()
		
	# Iterate through all collisions that occurred this frame
	for index in range(get_slide_collision_count()):
		# We get one of the collisions with the player
		var collision = get_slide_collision(index)

		# If the collision is with ground
		if collision.get_collider() == null:
			continue
			
		if collision.get_collider().is_in_group("VisitorCourt"):
			#print("Collided with visitor court")
			$ErrorAudioStreamPlayer.play()
		elif collision.get_collider().is_in_group("ThrownBall") and collision.get_collider() != last_collision:
			if not blocking:
				$OofAudioStreamPlayer3D.play()
				mob_score.emit()
			else:
				#print("Ball blocked")
				ball_blocked.emit()
			last_collision = collision.get_collider()
			
	velocity = target_velocity
	move_and_slide()
	PlayerData.position = global_position
	PlayerData.facing = $Pivot/CameraFacing.global_position - $Pivot/CameraYaw/CameraPitch/CameraSpringArm3D/PlayerCamera.global_position
	
func _input(event):
	if event is InputEventMouseMotion:
		var camera_rotation = event.relative * mouse_sensitivity
		$Pivot.rotate(Vector3.DOWN, camera_rotation.x)
		$Pivot/CameraYaw/CameraPitch.rotate(Vector3.RIGHT, camera_rotation.y)
		player_look.emit()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and not inventory.is_empty():
			if not in_neutral_zone and not blocking:
				ranged_attack.emit(inventory.pop_at(inventory_active_index))
				inventory_active_index = 0
				switch_balls()
			else:
				$ErrorAudioStreamPlayer.play()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if not inventory.is_empty() and selected_balls.is_empty():
				block()
			else:
				pick_up_ball()
	elif event is InputEventMouseButton and (event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		ball_switch.emit()
		switch_balls()

func pick_up_ball():
	if not game_started:
		$ErrorAudioStreamPlayer.play()
	elif not selected_balls.is_empty() and not is_inventory_full():
		#print(selected_balls)
		var new_ball_type = selected_balls[0].ball_type
		if selected_balls[0].thrown_ball and selected_balls[0].ball_team == "Mob":
			$ApplauseAudioStreamPlayer.play()
			#print("Ball caught")
			ball_caught.emit()
			PlayerData.restore_damage()
			if selected_balls[0].ball_owner and weakref(selected_balls[0].ball_owner).get_ref():
				selected_balls[0].ball_owner.die("")
		#print(new_ball_type)
		selected_balls[0].die()
		selected_balls.pop_at(0)
		#print("picked up ball: " + new_ball_type)
		new_ball = load("res://" + new_ball_type + ".tscn").instantiate()
		inventory.push_front(new_ball_type)
		picked_up_ball.emit(inventory.size())
		#print(inventory)
		$Pivot/ModelPivot/BallModel/BallStingerModel.set_visible(false)
		$Pivot/ModelPivot/BallModel/BallBlockerModel.set_visible(false)
		get_node("Pivot/ModelPivot/BallModel/" + new_ball_type.capitalize().replace(" ", "") + "Model").set_visible(true)
		#print("New ball added to scene")
		inventory_active_index = 0
		inventory_active_item = inventory[inventory_active_index]

func duck():
	player_ducked.emit()
	$CollisionShape3D.shape.height = .7
	$Pivot/CameraYaw.position.y = .7
	$DodgeTimer.start( 0.5 )
	speed = speed + speed / 2
	
func _on_dodge_timer_timeout():
	$CollisionShape3D.shape.height = 1.5
	$Pivot/CameraYaw.position.y = 1.5
	speed = speed - speed / 3

func is_inventory_full():
	#print(inventory.size())
	#print(inventory.size() >= inventory_count)
	return not inventory.size() < inventory_count
	
func switch_balls():
	if inventory.size() > 1:
		inventory_active_index = (inventory_active_index + 1) % inventory_count
		#print(inventory_active_index)
		inventory_active_item = inventory[inventory_active_index]
	elif inventory.size() == 1:
		inventory_active_index = 0
		inventory_active_item = inventory[inventory_active_index]
	else:
		inventory_active_index = 0
		inventory_active_item = ""
	
	$Pivot/ModelPivot/BallModel/BallBlockerModel.set_visible(false)
	$Pivot/ModelPivot/BallModel/BallStingerModel.set_visible(false)
	if inventory_active_item != "":
		get_node("Pivot/ModelPivot/BallModel/" + inventory_active_item.capitalize().replace(" ", "") + "Model").set_visible(true)
		
func block():
	var ball_in_hand = inventory_active_item.capitalize().replace(" ", "")
	#print(ball_in_hand)
	get_node("Pivot/ModelPivot/BallModel/" + ball_in_hand + "Model/BlockingRegion").disabled = false
	$Pivot/ModelPivot/BallModel.position.y = 1.2
	blocking = true
	$BlockTimer.start(0.5)

func _on_block_timer_timeout():
	$Pivot/ModelPivot/BallModel/BallBlockerModel/BlockingRegion.disabled = true
	$Pivot/ModelPivot/BallModel/BallStingerModel/BlockingRegion.disabled = true
	$Pivot/ModelPivot/BallModel.position.y = 1
	blocking = false
		
func _on_ball_pickup_area_body_entered(body):
	#print("ball entered area: " + body.get_name())
	if not is_inventory_full() and body.ball_type != null and not body.ball_team == "Player":
		if not body.thrown_ball:
			body.highlight(true)
			selected_balls.append(body)
		elif inventory.is_empty():
			body.highlight(true)
			selected_balls.append(body)
		
func _on_ball_pickup_area_body_exited(body):
	#print("ball left area: " + body.get_name())
	if body.ball_type != null:
		body.highlight(false)
		selected_balls.erase(body)
	#print(selected_balls)

func _on_ball_model_ball_blocked():
	ball_blocked.emit()
