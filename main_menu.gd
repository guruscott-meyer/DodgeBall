extends Node

@onready var main = $CanvasLayer/Main
@onready var settings = $CanvasLayer/Settings
@onready var run_options = $CanvasLayer/RunOptions
@onready var high_scores = $CanvasLayer/HighScores
@onready var difficulty_slider = $CanvasLayer/Settings/CenterContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/DifficultySlider
@onready var life_count_slider = $CanvasLayer/Settings/CenterContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/LifeCountSlider
@onready var mob_count_slider = $CanvasLayer/Settings/CenterContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/MobCountSlider
@onready var high_score_list = $CanvasLayer/HighScores/CenterContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/ItemList

func _on_button_play_pressed():
	PlayerData.difficulty = difficulty_slider.value
	PlayerData.max_life_count = life_count_slider.value
	PlayerData.max_mob_count = mob_count_slider.value
	main.visible = false
	run_options.visible = true
	
func _on_button_settings_pressed():
	main.visible = false
	settings.visible = true
	
func _on_button_quit_pressed():
	get_tree().quit()
	
func _on_button_settings_back_pressed():
	main.visible = true
	settings.visible = false

func _on_difficulty_slider_drag_ended(value_changed):
	if value_changed:
		PlayerData.difficulty = difficulty_slider.value

func _on_life_count_slider_drag_ended(value_changed):
	if value_changed:
		PlayerData.max_life_count = life_count_slider.value

func _on_mob_count_slider_drag_ended(value_changed):
	if value_changed:
		PlayerData.max_mob_count = mob_count_slider.value

func _on_button_short_game_pressed():
	PlayerData.initialize()
	PlayerData.game_time = 5
	get_tree().change_scene_to_file("res://dodge_ball.tscn")

func _on_button_med_game_pressed():
	PlayerData.initialize()
	PlayerData.game_time = 15
	get_tree().change_scene_to_file("res://dodge_ball.tscn")

func _on_button_long_game_pressed():
	PlayerData.initialize()
	PlayerData.game_time = 40
	get_tree().change_scene_to_file("res://dodge_ball.tscn")

func _on_button_tutorial_pressed():
	get_tree().change_scene_to_file("res://tutorial.tscn")

func _on_button_back_pressed():
	main.visible = true
	run_options.visible = false

func _on_button_scores_pressed():
	var read_file = FileAccess.open("res://high_scores.txt", FileAccess.READ)
	var stats_array = []
	setup_high_score_list()
	
	var json = JSON.new()
	if read_file:
		var response = json.parse(read_file.get_as_text())
		if response == OK:
			var data_received = json.data
			#print(data_received)
			if typeof(data_received) == TYPE_ARRAY:
				#print(data_received) # Prints array
				stats_array = data_received
			else:
				print("Unexpected data")
		else:
			print("JSON Parse Error: ", json.get_error_message(),  " at line ", json.get_error_line())
		read_file.close()
	
	stats_array.sort_custom(sort_by_score)

	var write_file = FileAccess.open("res://high_scores.txt", FileAccess.WRITE)
	write_file.store_string(JSON.stringify(stats_array))
	write_file.close()
	
	if not stats_array.is_empty():
		for high_score_stat in stats_array:
			high_score_list.add_item(high_score_stat["name"])
			high_score_list.add_item(high_score_stat["time"])
			high_score_list.add_item(high_score_stat["score"])
			high_score_list.add_item(high_score_stat["opp_score"])
			high_score_list.add_item(high_score_stat["difficulty"])
			high_score_list.add_item(high_score_stat["max_life"])
			high_score_list.add_item(high_score_stat["max_mob_count"])
			high_score_list.add_item(high_score_stat["rounds"])
			high_score_list.add_item(high_score_stat["throws"])
			high_score_list.add_item(high_score_stat["blocks"])
			high_score_list.add_item(high_score_stat["catches"])
	#print(high_scores)
	#file.store_csv_line(high_scores)
	$CanvasLayer/HighScores.show()
	$CanvasLayer/Main.hide()

func sort_by_score(a, b):
	return int(a["score"]) > int(b["score"])

func _on_high_scores_back_button_pressed():
	main.visible = true
	high_scores.visible = false
	
func setup_high_score_list():
	high_score_list.clear()
	high_score_list.add_item("Name", null, false)
	high_score_list.add_item("Time", null, false)
	high_score_list.add_item("Score", null, false)
	high_score_list.add_item("Opp Sc", null, false)
	high_score_list.add_item("Diff", null, false)
	high_score_list.add_item("Life", null, false)
	high_score_list.add_item("Mobs", null, false)
	high_score_list.add_item("Rounds", null, false)
	high_score_list.add_item("Throws", null, false)
	high_score_list.add_item("Blocks", null, false)
	high_score_list.add_item("Catches", null, false)
