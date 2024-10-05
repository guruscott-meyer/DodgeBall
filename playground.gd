extends Node3D

var movement = {}
var graveyard = [{}]

var countdown = 4

var tutorial_text1 = ["Welcome to Dodge Ball","Use the mouse to look around"]
var tutorial_text2 = ["Good!","Now use the keys W A S and D to move around"]
var tutorial_text3 = ["That's Right!","Get used to using them together. Take your time"]
var tutorial_text4 = ["","When you're finished, pick up the blocker. Use the right mouse button"]
var tutorial_text5 = ["","Now pick up the stinger"]
var tutorial_text6 = ["","Use the scroll wheel to switch between them"]
var tutorial_text7 = ["Good!","When you're ready, use the left mouse button to throw"]
var tutorial_text8 = ["Notice how the blocker flew slower than the stinger?","Try it out!"]
var tutorial_text9 = ["Meet your opponent","Try not to get hit!"]
var tutorial_text10 = ["Try catching a ball!","Both hands must be empty to catch"]
var tutorial_text11 = ["Try blocking!","With a ball in your hand, use the right mouse button to block"]
var tutorial_text12 = ["Try ducking!","Use the space bar to duck. You can duck stingers."]
var tutorial_text13 = ["Good!","ESC to quit. Now let's play dodgeball!"]

func _ready():
	PlayerData.life_count = PlayerData.max_life_count
	PlayerData.mob_count = PlayerData.max_mob_count
	PlayerData.total_rounds = 0
	$PlayerBase.ranged_attack.connect(_on_player_base_ranged_attack)
	$PlayerBase.mob_score.connect(_on_player_base_mob_score)
	$PlayerBase.picked_up_ball.connect(_on_player_base_picked_up_ball)
	PlayerData.update_ui.connect(_on_update_ui)
	PlayerData.player_death.connect(_on_player_death)
	PlayerData.all_mobs_dead.connect(_on_all_mobs_dead)
	
	_on_update_ui()
	#_on_spawn_loose_ball("ball_blocker", Vector3(-4, 0.5, 0), Vector3.ZERO)
	#_on_spawn_loose_ball("ball_stinger", Vector3(-2.5, 0.5, 0), Vector3.ZERO)
	#_on_spawn_loose_ball("ball_blocker", Vector3(-1, 0.5, 0), Vector3.ZERO)
	#_on_spawn_loose_ball("ball_blocker", Vector3(1, 0.5, 0), Vector3.ZERO)
	#_on_spawn_loose_ball("ball_stinger", Vector3(2.5, 0.5, 0), Vector3.ZERO)
	#_on_spawn_loose_ball("ball_blocker", Vector3(4, 0.5, 0), Vector3.ZERO)
	
	#_on_spawn_mob("res://basic_mob_badgirl.tscn", "Ground/Path3D4/PathFollow3D")
	#_on_spawn_mob("res://basic_mob_goodgirl.tscn", "Ground/Path3D3/PathFollow3D")
	#_on_spawn_mob("res://basic_mob_goofball.tscn", "Ground/Path3D1/PathFollow3D")
	#_on_spawn_mob("res://basic_mob_badgirl.tscn", "Ground/Path3D2/PathFollow3D")
	#_on_spawn_mob("res://basic_mob_goodgirl.tscn", "Ground/Path3D5/PathFollow3D")
	
	#$Ground/Path3D1/PathFollow3D.progress_ratio = 0
	#$Ground/Path3D2/PathFollow3D.progress_ratio = 0
	#$Ground/Path3D3/PathFollow3D.progress_ratio = 0
	#$Ground/Path3D4/PathFollow3D.progress_ratio = 0
	#$Ground/Path3D5/PathFollow3D.progress_ratio = 0
	
func _physics_process(delta):
	for move in movement:
		if movement[move]:
			get_node(move).progress += PlayerData.difficulty * delta * 2
	
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
	movement[spawn_location] = true
	# Spawn the mob by adding it to the Main scene.
	get_node(spawn_location).add_child(mob)
	mob.set_owner(self)
	mob.set_direction_and_speed()
	#print("Spawned: " + spawn_type + " " + mob.name)
	
func _on_mob_dead(spawn_location, _mob_name):
	_on_spawn_mob("res://basic_mob_badgirl.tscn", spawn_location)
	#$Ground/Path3D1/PathFollow3D.get_child(0).set_direction_and_speed()
	#PlayerData.kill_mob()
	
func _on_respawn_mob():
	var mob_data = graveyard.pop_at(1)
	_on_spawn_mob("res://basic_mob_" + mob_data.mob_name + ".tscn", mob_data.mob_location)
	
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
	pass
	#$UserInterface/PlayerScoreLabel.text = "Home: " + String.num(PlayerData.score)
	#$UserInterface/OpponentScoreLabel.text = "Away: " + String.num(PlayerData.opponent_score)
	#$UserInterface/HealthLabel.text = String.num(PlayerData.life_count)
	#$UserInterface/MobLabel.text = "Mobs: " + String.num(PlayerData.mob_count)

func _on_end_timer_timeout():
	PlayerData.next_round()
	get_tree().reload_current_scene()
	
func _on_basic_mob_movement_start(spawn_location):
	movement[spawn_location] = true
	
func _on_basic_mob_movement_stop(spawn_location):
	movement[spawn_location] = false

func _on_tutorial_timer_timeout():
	$BeepAudioStreamPlayer.play()
	$UserInterface/TrainingTextLabel2.text = tutorial_text1[0]
	$UserInterface/TrainingTextLabel3.text = tutorial_text1[1]
	$TutorialTimer.timeout.disconnect(_on_tutorial_timer_timeout)
	$PlayerBase.player_look.connect(_on_player_look_tutorial)

func _on_player_look_tutorial():
	$BeepAudioStreamPlayer.play()
	$UserInterface/TrainingTextLabel2.text = tutorial_text2[0]
	$UserInterface/TrainingTextLabel3.text = tutorial_text2[1]
	$PlayerBase.player_look.disconnect(_on_player_look_tutorial)
	$PlayerBase.player_move.connect(_on_player_move_tutorial)
	
func _on_player_move_tutorial():
	$BeepAudioStreamPlayer.play()
	$UserInterface/TrainingTextLabel2.text = tutorial_text3[0]
	$UserInterface/TrainingTextLabel3.text = tutorial_text3[1]
	$PlayerBase.player_move.disconnect(_on_player_move_tutorial)
	$TutorialTimer.timeout.connect(_on_tutorial_timer2_timeout)
	$TutorialTimer.start()
	
func _on_tutorial_timer2_timeout():
	$BeepAudioStreamPlayer.play()
	$UserInterface/TrainingTextLabel2.text = tutorial_text4[0]
	$UserInterface/TrainingTextLabel3.text = tutorial_text4[1]
	$TutorialTimer.timeout.disconnect(_on_tutorial_timer2_timeout)
	_on_spawn_loose_ball("ball_blocker", Vector3(1, 0.5, 0), Vector3.ZERO)
	$PlayerBase.picked_up_ball.connect(_on_ball_pickup_blocker_tutorial)
	$PlayerBase.game_started = true
	
func _on_ball_pickup_blocker_tutorial(_aize):
	$BeepAudioStreamPlayer.play()
	$UserInterface/TrainingTextLabel2.text = tutorial_text5[0]
	$UserInterface/TrainingTextLabel3.text = tutorial_text5[1]
	$PlayerBase.picked_up_ball.disconnect(_on_ball_pickup_blocker_tutorial)
	_on_spawn_loose_ball("ball_stinger", Vector3(1, 0.5, 0), Vector3.ZERO)
	$PlayerBase.picked_up_ball.connect(_on_ball_pickup_stinger_tutorial)
	
func _on_ball_pickup_stinger_tutorial(_size):
	$BeepAudioStreamPlayer.play()
	$UserInterface/TrainingTextLabel2.text = tutorial_text6[0]
	$UserInterface/TrainingTextLabel3.text = tutorial_text6[1]
	$PlayerBase.picked_up_ball.disconnect(_on_ball_pickup_stinger_tutorial)
	$PlayerBase.ball_switch.connect(_on_player_base_ball_switch_tutorial)
	
func _on_player_base_ball_switch_tutorial():
	$BeepAudioStreamPlayer.play()
	$UserInterface/TrainingTextLabel2.text = tutorial_text7[0]
	$UserInterface/TrainingTextLabel3.text = tutorial_text7[1]
	$PlayerBase.ball_switch.disconnect(_on_player_base_ball_switch_tutorial)
	$PlayerBase.ranged_attack.connect(_on_player_base_ranged_attack_tutorial)
	
func _on_player_base_ranged_attack_tutorial(_type):
	$BeepAudioStreamPlayer.play()
	$UserInterface/TrainingTextLabel2.text = tutorial_text8[0]
	$UserInterface/TrainingTextLabel3.text = tutorial_text8[1]
	$TutorialTimer.timeout.connect(_on_tutorial_timer3_timeout)
	$TutorialTimer.start()
	$PlayerBase.ranged_attack.disconnect(_on_player_base_ranged_attack_tutorial)
		
func _on_tutorial_timer3_timeout():
	$BeepAudioStreamPlayer.play()
	$UserInterface/TrainingTextLabel2.text = tutorial_text9[0]
	$UserInterface/TrainingTextLabel3.text = tutorial_text9[1]
	_on_spawn_loose_ball("ball_blocker", Vector3(-2, 0.5, 0), Vector3.ZERO)
	_on_spawn_loose_ball("ball_stinger", Vector3(0, 0.5, 0), Vector3.ZERO)
	_on_spawn_loose_ball("ball_blocker", Vector3(2, 0.5, 0), Vector3.ZERO)
	
	_on_spawn_mob("res://basic_mob_badgirl.tscn", "Ground/Path3D1/PathFollow3D")
	$Ground/Path3D1/PathFollow3D.get_child(0).set_direction_and_speed()
	$TutorialTimer.timeout.disconnect(_on_tutorial_timer3_timeout)
	$TutorialTimer.wait_time = 15
	$TutorialTimer.timeout.connect(_on_tutorial_timer4_timeout)
	$TutorialTimer.start()
	
func _on_tutorial_timer4_timeout():
	$BeepAudioStreamPlayer.play()
	$UserInterface/TrainingTextLabel2.text = tutorial_text10[0]
	$UserInterface/TrainingTextLabel3.text = tutorial_text10[1]
	$TutorialTimer.timeout.disconnect(_on_tutorial_timer4_timeout)
	$PlayerBase.ball_caught.connect(_on_player_base_ball_caught_tutorial)
	
func _on_player_base_ball_blocked_tutorial():
	$BeepAudioStreamPlayer.play()
	$UserInterface/TrainingTextLabel2.text = tutorial_text12[0]
	$UserInterface/TrainingTextLabel3.text = tutorial_text12[1]
	$PlayerBase.ball_blocked.disconnect(_on_player_base_ball_blocked_tutorial)
	$PlayerBase.player_ducked.connect(_on_player_base_ducked_tutorial)
	
func _on_player_base_ball_caught_tutorial():
	$BeepAudioStreamPlayer.play()
	$UserInterface/TrainingTextLabel2.text = tutorial_text11[0]
	$UserInterface/TrainingTextLabel3.text = tutorial_text11[1]
	$PlayerBase.ball_caught.disconnect(_on_player_base_ball_caught_tutorial)
	$PlayerBase.ball_blocked.connect(_on_player_base_ball_blocked_tutorial)
	
func _on_player_base_ducked_tutorial():
	$BeepAudioStreamPlayer.play()
	$UserInterface/TrainingTextLabel2.text = tutorial_text13[0]
	$UserInterface/TrainingTextLabel3.text = tutorial_text13[1]
	$PlayerBase.player_ducked.disconnect(_on_player_base_ducked_tutorial)
