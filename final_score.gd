extends Node

@onready var score_label = $CanvasLayer/Scores/CenterContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/ScoreLabel
@onready var opponent_score = $CanvasLayer/Scores/CenterContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/OpponentScore
@onready var difficulty_label = $CanvasLayer/Scores/CenterContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/DifficultyLabel
@onready var life_count_label = $CanvasLayer/Scores/CenterContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/LifeCountLabel
@onready var mob_count_label = $CanvasLayer/Scores/CenterContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/MobCountLabel
@onready var total_rounds = $CanvasLayer/Scores/CenterContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/TotalRounds
@onready var total_throws = $CanvasLayer/Scores/CenterContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/TotalThrows
@onready var total_catches = $CanvasLayer/Scores/CenterContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/TotalCatches
@onready var total_blocks = $CanvasLayer/Scores/CenterContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/TotalBlocks
@onready var player_name = $CanvasLayer/EnterName/CenterContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/LineEdit
@onready var high_score_list = $CanvasLayer/HighScores/CenterContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/ItemList

func _ready():
	$Background.hide()
	$CanvasLayer.hide()

func display():
	score_label.text = 'Final Score: ' + String.num(PlayerData.score)
	opponent_score.text = "Opponent Score: " + String.num(PlayerData.opponent_score)
	difficulty_label.text = "Difficulty: " + String.num(PlayerData.difficulty)
	life_count_label.text = "Life Count: " + String.num(PlayerData.life_count)
	mob_count_label.text = "Mob Count: " + String.num(PlayerData.mob_count)
	total_rounds.text = "Total Rounds: " + String.num(PlayerData.total_rounds)
	total_throws.text = "Total Throws: " + String.num(PlayerData.total_throws)
	total_blocks.text = "Total Blocks: " + String.num(PlayerData.total_blocks)
	total_catches.text = "Total Catches: " + String.num(PlayerData.total_catches)
	$Background.show()
	$CanvasLayer.show()
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)
	$AudioStreamPlayer.play()
	
func _on_high_score_button_pressed():
	$CanvasLayer/Scores.hide()
	$CanvasLayer/HighScores.show()

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://menu.tscn")

func _on_enter_button_pressed():
	var read_file = FileAccess.open("res://high_scores.txt", FileAccess.READ)
	var stats_array = [{}]
	
	var json = JSON.new()
	if read_file:
		var response = json.parse(read_file.get_as_text())
		if response == OK:
			var data_received = json.data
			#print(data_received)
			if typeof(data_received) == TYPE_ARRAY:
				stats_array = data_received
			else:
				print("Unexpected data")
		else:
			print("JSON Parse Error: ", json.get_error_message(),  " at line ", json.get_error_line())
		read_file.close()
	
	var new_record = {
		"name": player_name.text,
		"time": String.num(PlayerData.game_time),
		"score": String.num(PlayerData.score),
		"opp_score": String.num(PlayerData.opponent_score),
		"difficulty": String.num(PlayerData.difficulty),
		"max_life": String.num(PlayerData.max_life_count),
		"max_mob_count": String.num(PlayerData.max_mob_count),
		"rounds": String.num(PlayerData.total_rounds),
		"throws": String.num(PlayerData.total_throws),
		"blocks": String.num(PlayerData.total_blocks),
		"catches": String.num(PlayerData.total_catches)
	}
	
	stats_array.append(new_record)
	stats_array.sort_custom(sort_by_score)

	var write_file = FileAccess.open("res://high_scores.txt", FileAccess.WRITE)
	write_file.store_string(JSON.stringify(stats_array))
	write_file.close()

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
	$CanvasLayer/Scores.show()
	$CanvasLayer/EnterName.hide()
	
func _on_high_scores_back_button_pressed():
	$CanvasLayer/Scores.show()
	$CanvasLayer/HighScores.hide()

func sort_by_score(a, b):
	print(a["score"])
	return int(a["score"]) > int(b["score"])
