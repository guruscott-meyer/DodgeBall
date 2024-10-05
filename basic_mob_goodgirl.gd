extends CharacterBody3D

signal dead
signal spawn_loose_ball
signal ranged_attack
signal spawn_mob
signal respawn_mob
signal spawn_body
signal set_mode
signal movement_start
signal movement_stop

enum Mode {
	TAUNT = 0,
	COLLECT = 1,
	DODGE = 2,
	THROW = 3
}

@export var INITIAL_MODE = Mode.DODGE
var CURRENT_MODE = Mode.DODGE

var min_speed = .5
var max_speed = 1

var fall_acceleration = 9.8

var last_player_direction = Vector3.ZERO
var last_player_facing = Vector3.ZERO

@export var mouse_sensitivity = 0.01
@export var inventory_count = 1

var inventory = Array([])
var inventory_active_index = 0
var inventory_active_item = ""

var new_ball: Node

var selected_balls = []

var in_neutral_zone = false
var hold_fire = false
var catching = false

var last_collision
var spawn_location
var mob_name = "tammy"

func initialize(path_name):
	CURRENT_MODE = INITIAL_MODE
	velocity = Vector3.ZERO
	spawn_location = path_name
	
func _process(_delta):
	last_player_direction = $ModelPivot/BallModel.global_position - PlayerData.position
	last_player_facing = PlayerData.position - global_position
			
func die(bullet_type):
	#print("Dying")
	$PlayerFailAudioStreamPlayer.play()
	clear_all_animations()
	movement_stop.emit(spawn_location)
	if bullet_type == "blocker":
		$ModelPivot/BlockerShot/AnimationPlayer.request_ready()
		$ModelPivot/BlockerShot/AnimationPlayer.play("mixamo_com")
		$ModelPivot/BlockerShot.visible = true
	elif bullet_type == "stinger":
		$ModelPivot/StingerShot/AnimationPlayer.request_ready()
		$ModelPivot/StingerShot/AnimationPlayer.play("mixamo_com")
		$ModelPivot/StingerShot.visible = true
	else:
		$ModelPivot/Disappointed/AnimationPlayer.request_ready()
		$ModelPivot/Disappointed/AnimationPlayer.play("mixamo_com")
		$ModelPivot/Disappointed.visible = true
	
func _on_death_animation_timeout():
	dead.emit(spawn_location, "goodgirl")
	drop_everything()
	queue_free()
	
func _on_dodge_animation_timeout():
	$ShoeSqueakAudioStreamPlayer3D.play()
	CURRENT_MODE = randi_range(Mode.TAUNT, Mode.THROW) as Mode
	$CollisionShape3D.shape.height = 1.5
	set_mode.emit()
	
func _on_taunt_animation_timeout():
	catching = false
	CURRENT_MODE = Mode.DODGE
	set_mode.emit()
	
func _on_throw_animation_timeout():
	ranged_attack.emit(inventory.pop_at(inventory_active_index), self)
	switch_balls()
	CURRENT_MODE = Mode.DODGE
	set_mode.emit()

func set_direction_and_speed():
	if PlayerData.facing.dot(last_player_facing) > 0:
		print("Quit looking at me!")
		#print(PlayerData.facing.dot(last_player_facing))
		CURRENT_MODE = Mode.DODGE
	clear_all_animations()
	if CURRENT_MODE == Mode.TAUNT:
		#$MeshInstance3D.get_mesh().get_material().albedo_color = Color("purple")
		#print("Taunting")
		#velocity = Vector3.ZERO
		if inventory.is_empty():
			catching = true
			movement_stop.emit(spawn_location)
			$ModelPivot/Clapping/AnimationPlayer.request_ready()
			$ModelPivot/Clapping/AnimationPlayer.play("mixamo_com")
			$ModelPivot/Clapping.visible = true
		else:
			CURRENT_MODE = Mode.DODGE
			movement_stop.emit(spawn_location)
			$ModelPivot/Taunting/AnimationPlayer.request_ready()
			$ModelPivot/Taunting/AnimationPlayer.play("mixamo_com")
			$ModelPivot/Taunting.set_visible(true)
	elif CURRENT_MODE == Mode.COLLECT:
		#$MeshInstance3D.get_mesh().get_material().albedo_color = Color("green")
		#print("Collecting")
		if is_inventory_full():
			CURRENT_MODE = Mode.THROW
			$ShoeSqueakAudioStreamPlayer3D.play()
			movement_start.emit(spawn_location)
			$ModelPivot/Forward/AnimationPlayer.request_ready()
			$ModelPivot/Forward/AnimationPlayer.play("mixamo_com")
			$ModelPivot/Forward.set_visible(true)
		elif selected_balls.is_empty():
			CURRENT_MODE = Mode.DODGE
			movement_start.emit(spawn_location)
			$ShoeSqueakAudioStreamPlayer3D.play()
			$ModelPivot/Forward/AnimationPlayer.request_ready()
			$ModelPivot/Forward/AnimationPlayer.play("mixamo_com")
			$ModelPivot/Forward.set_visible(true)
		else:
			#print("Picking up ball")
			$ShoeSqueakAudioStreamPlayer3D.play()
			CURRENT_MODE = Mode.THROW
			pick_up_ball()
	elif CURRENT_MODE == Mode.DODGE:
		
		$CollisionShape3D.shape.height = .75
		movement_start.emit(spawn_location)
		$ModelPivot/Rolling/AnimationPlayer.request_ready()
		$ModelPivot/Rolling/AnimationPlayer.play("mixamo_com")
		$ModelPivot/Rolling.set_visible(true)
	elif CURRENT_MODE == Mode.THROW:
		#$MeshInstance3D.get_mesh().get_material().albedo_color = Color("red")
		#print("Throwing")
		if inventory.is_empty():
			switch_balls()
			CURRENT_MODE = Mode.COLLECT
			movement_stop.emit(spawn_location)
			$ModelPivot/Taunting/AnimationPlayer.request_ready()
			$ModelPivot/Taunting/AnimationPlayer.play("mixamo_com")
			$ModelPivot/Taunting.set_visible(true)
		elif can_throw():
			movement_stop.emit(spawn_location)
			$ModelPivot/Throwing/AnimationPlayer.request_ready()
			$ModelPivot/Throwing/AnimationPlayer.play("mixamo_com")
			$ModelPivot/Throwing.set_visible(true)
		else:
			CURRENT_MODE = Mode.DODGE
			movement_stop.emit(spawn_location)
			$ModelPivot/Taunting/AnimationPlayer.request_ready()
			$ModelPivot/Taunting/AnimationPlayer.play("mixamo_com")
			$ModelPivot/Taunting.set_visible(true)
	$ModelPivot.look_at( -last_player_direction)
	
func pick_up_ball():
	if not selected_balls.is_empty() and not is_inventory_full():
		clear_all_animations()
		if selected_balls[0].thrown_ball:
			if selected_balls[0].ball_type == "ball_blocker":
				movement_stop.emit(spawn_location)
				$ModelPivot/CatchingBlocker/AnimationPlayer.request_ready()
				$ModelPivot/CatchingBlocker/AnimationPlayer.play("mixamo_com")
				$ModelPivot/CatchingBlocker.set_visible(true)
			elif selected_balls[0].ball_type == "ball_stinger":
				movement_stop.emit(spawn_location)
				$ModelPivot/CatchingStinger/AnimationPlayer.request_ready()
				$ModelPivot/CatchingStinger/AnimationPlayer.play("mixamo_com")
				$ModelPivot/CatchingStinger.set_visible(true)
			$ApplauseAudioStreamPlayer.play()
			if(PlayerData.mob_count < PlayerData.max_mob_count):
				respawn_mob.emit()
				PlayerData.restore_mob()
				PlayerData.take_damage()
		else:
			#velocity = Vector3.FORWARD * 4.48
			movement_start.emit(spawn_location)
			$ModelPivot/PickingUp/AnimationPlayer.request_ready()
			$ModelPivot/PickingUp/AnimationPlayer.play("mixamo_com")
			$ModelPivot/PickingUp.set_visible(true)
		var new_ball_type = selected_balls[0].ball_type
		selected_balls[0].die()
		selected_balls.pop_at(0)
		#print("picked up ball: " + new_ball_type)
		new_ball = load("res://" + new_ball_type + ".tscn").instantiate()
		inventory.append(new_ball_type)
		switch_balls()
		set_mode.emit()
	
func is_inventory_full():
	return inventory.size() >= inventory_count
	
func can_throw():
	#return not hold_fire and not in_neutral_zone
	return true
	
func switch_balls():
	if inventory.size() > 1:
		inventory_active_index = (inventory_active_index + 1) % inventory_count
		inventory_active_item = inventory[inventory_active_index]
	elif inventory.size() == 1:
		inventory_active_index = 0
		inventory_active_item = inventory[0]
	elif inventory.is_empty():
		inventory_active_index = 0
		inventory_active_item = ""
	#print(inventory_active_item)
	$ModelPivot/BallModel/BallBlocker.set_visible(false)
	$ModelPivot/BallModel/BallStinger.set_visible(false)
	#print(inventory_active_item.capitalize().replace(" ", ""))
	get_node("ModelPivot/BallModel/" + inventory_active_item.capitalize().replace(" ", "")).set_visible(true)
		
		
func clear_all_animations():
	$ModelPivot/BlockerShot.set_visible(false)
	$ModelPivot/BlockerShot/AnimationPlayer.stop()
	$ModelPivot/CatchingBlocker.set_visible(false)
	$ModelPivot/CatchingBlocker/AnimationPlayer.stop()
	$ModelPivot/CatchingStinger.set_visible(false)
	$ModelPivot/CatchingStinger/AnimationPlayer.stop()
	$ModelPivot/Clapping.set_visible(false)
	$ModelPivot/Clapping/AnimationPlayer.stop()
	$ModelPivot/Forward.set_visible(false)
	$ModelPivot/Forward/AnimationPlayer.stop()
	$ModelPivot/PickingUp.set_visible(false)
	$ModelPivot/PickingUp/AnimationPlayer.stop()
	$ModelPivot/Throwing.set_visible(false)
	$ModelPivot/Throwing/AnimationPlayer.stop()
	$ModelPivot/Taunting.set_visible(false)
	$ModelPivot/Taunting/AnimationPlayer.stop()
	$ModelPivot/Rolling.set_visible(false)
	$ModelPivot/Rolling/AnimationPlayer.stop()
	$ModelPivot/Victory.set_visible(false)
	$ModelPivot/Victory/AnimationPlayer.stop()
	$ModelPivot/StingerShot.set_visible(false)
	$ModelPivot/StingerShot/AnimationPlayer.stop()
	$ModelPivot/Disappointed.set_visible(false)
	$ModelPivot/Disappointed/AnimationPlayer.stop()
		
func drop_everything():
	for item in inventory:
		spawn_loose_ball.emit(item, global_position, Vector3.DOWN)
		
func _on_ball_pickup_area_body_entered(body):
	if body.ball_type != null:
		#print(body.ball_type)
		selected_balls.append(body)
		#print(selected_balls)
	if body.ball_team != "Mob" and catching and inventory.is_empty():
		pick_up_ball()
		
func _on_ball_pickup_area_body_exited(body):
	if body.ball_type != null:
		selected_balls.pop_at(selected_balls.find(body))
	
func victory_dance():
	clear_all_animations()
	movement_stop.emit(spawn_location)
	$ModelPivot/Victory/AnimationPlayer.request_ready()
	$ModelPivot/Victory/AnimationPlayer.play("mixamo_com")
	$ModelPivot/Victory.set_visible(true)
