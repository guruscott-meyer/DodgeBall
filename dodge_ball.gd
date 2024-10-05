extends Node3D

var sun_speed = -0.01

var current_scene

# Called when the node enters the scene tree for the first time.
func _ready():
	current_scene = load("res://main.tscn").instantiate()
	current_scene.start_timer.connect(_on_main_start_timer)
	current_scene.restart.connect(_on_main_restart)
	add_child(current_scene)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$LocalSun.rotate_z(sun_speed * delta)
	$LocalSun.rotate_x(sun_speed * delta)
	game_time_left()

func _on_main_start_timer():
	#print($GameTimer.is_stopped())
	if $GameTimer.is_stopped():
		$GameTimer.wait_time = PlayerData.game_time * 60
		#print($GameTimer.wait_time)
		$GameTimer.start()
		#print("Game Timer Started")
	
func _on_game_timer_timeout():
	#print("Game Timer timed out")
	current_scene.finish_game()

func _on_main_restart():
	remove_child(current_scene)
	current_scene = load("res://main.tscn").instantiate()
	current_scene.restart.connect(_on_main_restart)
	add_child(current_scene)
	
func game_time_left():
	var time_left = $GameTimer.time_left
	var minute = floor(time_left / 60)
	var second = int(time_left) % 60
	current_scene.count_down(minute, second)
