extends Node3D

signal start_timer
signal restart

var movement = {}
var graveyard = [{}]

var countdown = 4

var mobs = ["badgirl", "goodgirl", "goofball"]

func _ready():
	$PlayerBase.ranged_attack.connect(_on_player_base_ranged_attack)
	$PlayerBase.mob_score.connect(_on_player_base_mob_score)
	$PlayerBase.picked_up_ball.connect(_on_player_base_picked_up_ball)
	PlayerData.update_ui.connect(_on_update_ui)
	PlayerData.player_death.connect(_on_player_death)
	PlayerData.all_mobs_dead.connect(_on_all_mobs_dead)
	_on_spawn_loose_ball("ball_blocker", Vector3(-4, 0.5, 0), Vector3.ZERO)
	_on_spawn_loose_ball("ball_stinger", Vector3(-2.5, 0.5, 0), Vector3.ZERO)
	_on_spawn_loose_ball("ball_blocker", Vector3(-1, 0.5, 0), Vector3.ZERO)
	_on_spawn_loose_ball("ball_blocker", Vector3(1, 0.5, 0), Vector3.ZERO)
	_on_spawn_loose_ball("ball_stinger", Vector3(2.5, 0.5, 0), Vector3.ZERO)
	_on_spawn_loose_ball("ball_blocker", Vector3(4, 0.5, 0), Vector3.ZERO)
	
	for lineup in range(1, PlayerData.mob_count + 1):
		var new_mob = mobs[randi_range(0,2)]
		_on_spawn_mob("res://basic_mob_" + new_mob + ".tscn", "Ground/Path3D" + String.num(lineup) + "/PathFollow3D")
		get_node("Ground/Path3D" + String.num(lineup) + "/PathFollow3D").progress_ratio = 0
	
func _on_start_timer_timeout():
	countdown -= 1
	if countdown == 3:
		$BeepAudioStreamPlayer.play()
		$UserInterface/CountdownLabel.text = String.num(countdown)
		$StartTimer.wait_time = 1
		$StartTimer.start()
	elif countdown == 0:
		$UserInterface/CountdownLabel.text = "START!"
		$StartTimer.start()
		$AirhornAudioStreamPlayer.play()
		for i in range(1, PlayerData.max_mob_count + 1):
			get_node("Ground/Path3D" + String.num(i) + "/PathFollow3D").get_child(0).set_direction_and_speed()
		$PlayerBase.game_started = true
		start_timer.emit()
	elif countdown == -1:
		$UserInterface/CountdownLabel.text = ""
	else:
		$BeepAudioStreamPlayer.play()
		$UserInterface/CountdownLabel.text = String.num(countdown)
		$StartTimer.start()
	_on_update_ui()
	
func _physics_process(delta):
	if not movement.is_empty():
		for movement_track in movement:
			if movement[movement_track]:
				get_node(movement_track).progress += PlayerData.difficulty * delta * 2
	
func _on_player_base_ranged_attack(bullet_type):
	var bullet = load("res://" + bullet_type + ".tscn").instantiate()
	var bullet_direction = $PlayerBase/Pivot/CameraFacing.global_position - $PlayerBase/Pivot/CameraYaw/CameraPitch/CameraSpringArm3D/PlayerCamera.global_position 
	bullet_direction.y = 0
	#print(bullet_direction)
	#print($PlayerBase/Pivot/ModelPivot/CastingOrigin.global_position)
	var type = bullet_type.capitalize().replace(" ", "")
	bullet.transform.origin = get_node("PlayerBase/Pivot/ModelPivot/BallModel/" + type + "Model/" + type + "ThrowOrigin").global_position
	bullet.initialize(bullet_direction, "Player", null)
	bullet.spawn_loose_ball.connect(_on_spawn_loose_ball)
	add_child(bullet)
	$UserInterface/ExtraBall.visible = false
	bullet.set_owner(self)
	PlayerData.total_throws = PlayerData.total_throws + 1
	
func _on_basic_mob_ranged_attack(bullet_type, mob):
	var bullet_direction = -mob.last_player_direction 
	bullet_direction.y = 0
	var bullet = load("res://" + bullet_type + ".tscn").instantiate()
	bullet.transform.origin = mob.get_node("ModelPivot/BallModel").global_position
	bullet.initialize(bullet_direction, "Mob", mob)
	bullet.spawn_loose_ball.connect(_on_spawn_loose_ball)
	add_child(bullet)
	bullet.set_owner(self)
	
func _on_spawn_loose_ball(spawn_type, spawn_location, spawn_vector):
	#print("Spawning: " + spawn_type)
	var mob = load("res://loose_" + spawn_type + ".tscn").instantiate()
	mob.transform.origin = spawn_location
	mob.initialize(spawn_vector)
	# Spawn the mob by adding it to the Main scene.
	add_child(mob)
	mob.set_owner(self)
#
func _on_spawn_mob(spawn_type, spawn_location):
	#print("Spawning: " + spawn_type)
	var mob = load(spawn_type).instantiate()
	mob.initialize(spawn_location)
	mob.movement_start.connect(_on_basic_mob_movement_start)
	mob.movement_stop.connect(_on_basic_mob_movement_stop)
	mob.ranged_attack.connect(_on_basic_mob_ranged_attack)
	mob.spawn_loose_ball.connect(_on_spawn_loose_ball)
	mob.spawn_mob.connect(_on_spawn_mob)
	mob.respawn_mob.connect(_on_respawn_mob)
	mob.dead.connect(_on_mob_dead)
	movement[spawn_location] = false
	# Spawn the mob by adding it to the Main scene.
	get_node(spawn_location).add_child(mob)
	mob.set_owner(self)
	#print("Spawned: " + spawn_type + " " + mob.name)
	
func _on_mob_dead(spawn_location, mob_name):
	graveyard.append({ "mob_location": spawn_location, "mob_name": mob_name })
	#print(graveyard)
	PlayerData.kill_mob()
	
func _on_respawn_mob():
	var mob_data = graveyard.pop_at(1)
	_on_spawn_mob("res://basic_mob_" + mob_data.mob_name + ".tscn", mob_data.mob_location)
	get_node(mob_data.mob_location).get_child(0).set_direction_and_speed()
	
func _on_player_base_mob_score():
	PlayerData.take_damage()
	
#Updates the HUD
func _on_player_base_picked_up_ball(inventory_size):
	if inventory_size > 1:
		$UserInterface/ExtraBall.visible = true
	else:
		$UserInterface/ExtraBall.visible = false
	
#func _on_mob_timer_timeout():
	#var mob_spawn_location = $SpawnPath/SpawnLocation
	#mob_spawn_location.progress_ratio = randf()
	#_on_spawn("res://basic_mob.tscn", mob_spawn_location.position)
	
func _on_neutral_zone_body_entered(body):
	if body.is_in_group("Player"):
		#print("Player entered neutral zone body")
		body.in_neutral_zone = true
	
func _on_neutral_zone_body_exited(body):
	if body.is_in_group("Player"):
		#print("Player exited neutral zone body")
		body.in_neutral_zone = false

func _on_neutral_zone_body_shape_entered(_body_rid, body, _body_shape_index, _local_shape_index):
	if body.is_in_group("Player"):
		#print("Player entered neutral zone body shape")
		body.in_neutral_zone = true
		
func _on_neutral_zone_body_shape_exited(_body_rid, body, _body_shape_index, _local_shape_index):
	if body.is_in_group("Player"):
		#print("Player exited neutral zone body shape")
		body.in_neutral_zone = false
		
func _on_player_death():
	$AirhornAudioStreamPlayer.play()
	for mob_number in range(1, 6):
		if get_node("Ground/Path3D" + String.num(mob_number) + "/PathFollow3D").has_node("BasicMob"):
			get_node("Ground/Path3D" + String.num(mob_number) + "/PathFollow3D").get_child(0).victory_dance()
	$EndTimer.start()
	
func _on_all_mobs_dead():
	$AirhornAudioStreamPlayer.play()
	$EndTimer.start()

func _on_update_ui():
	$UserInterface/PlayerScoreLabel.text = "Home: " + String.num(PlayerData.score)
	$UserInterface/OpponentScoreLabel.text = "Away: " + String.num(PlayerData.opponent_score)
	$UserInterface/HealthLabel.text = String.num(PlayerData.life_count)
	$UserInterface/MobLabel.text = "Mobs: " + String.num(PlayerData.mob_count)

func _on_end_timer_timeout():
	#if not movement.is_empty():
		#for movement_track in movement:
			#if movement[movement_track]:
				#get_node(movement_track).get_child(0).die("")
	PlayerData.next_round()
	restart.emit()
	
func _on_basic_mob_movement_start(spawn_location):
	movement[spawn_location] = true
	
func _on_basic_mob_movement_stop(spawn_location):
	movement[spawn_location] = false
	
func finish_game():
	#print("Game finished")
	$FinalScore/FinalScore.display()
	get_tree().paused = true
	
func count_down(minute, second):
	$UserInterface/TimerLabel.text = "%02d:%02d" % [minute, second]
	
func _on_player_base_ball_blocked():
	PlayerData.total_blocks = PlayerData.total_blocks + 1
	
func _on_player_base_ball_caught():
	PlayerData.total_catches = PlayerData.total_catches + 1
