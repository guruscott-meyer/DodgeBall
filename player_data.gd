extends Node

signal player_death
signal all_mobs_dead
signal update_ui

var difficulty
var max_life_count
var max_mob_count
var total_rounds
var total_throws
var total_catches
var total_blocks

var position = Vector3.ZERO
var facing = Vector3.FORWARD

var score
var opponent_score
var life_count
var mob_count

var game_time = 1

func initialize():
	life_count = max_life_count
	mob_count = max_mob_count
	total_rounds = 0
	total_throws = 0
	total_blocks = 0
	total_catches = 0
	score = 0
	opponent_score = 0

func take_damage():
	life_count -= 1
	if life_count == 0:
		opponent_score += 1
		player_death.emit()	
	if life_count < 0:
		life_count = 0
	update_ui.emit()
		
func restore_damage():
	if life_count < max_life_count:
		life_count += 1
	update_ui.emit()
		
func kill_mob():
	mob_count -= 1
	if mob_count <= 0:
		score += 1
		all_mobs_dead.emit()
	update_ui.emit()
	
func restore_mob():
	mob_count += 1
	update_ui.emit()
		
func _reset():
	score = 0
	opponent_score = 0
	life_count = max_life_count
	mob_count = max_mob_count
	total_rounds = 0
	update_ui.emit()
	
func next_round():
	life_count = max_life_count
	mob_count = max_mob_count
	total_rounds += 1
	update_ui.emit()
	
func my_normalize(vector3):
	var temp_vector2 = Vector2.ZERO
	temp_vector2.x = vector3.x
	temp_vector2.y = vector3.z
	temp_vector2 = temp_vector2.normalized()
	var temp_vector3 = Vector3.ZERO
	temp_vector3.x = temp_vector2.x
	temp_vector3.z = temp_vector2.y
	return temp_vector3
	
#func save_high_scores(player_id):
	#var high_scores = PackedStringArray([])
	#high_scores.append(player_id)
	#high_scores.append(String.num(score))
	#high_scores.append(String.num(opponent_score))
	#high_scores.append(String.num(difficulty))
	#high_scores.append(String.num(max_life_count))
	#high_scores.append(String.num(max_mob_count))
	#high_scores.append(String.num(total_rounds))
	#high_scores.append(String.num(total_throws))
	#high_scores.append(String.num(total_blocks))
	#high_scores.append(String.num(total_catches))
	#var file = FileAccess.open("user://high_scores.csv", FileAccess.WRITE)
	#file.store_csv_line(high_scores)

#func load_high_scores_by_line():
	#var file = FileAccess.open("user://high_scores.csv", FileAccess.READ)
	#print(file)
	#if file:
		#while file.get_position() < file.get_length():
			#var high_scores = file.get_csv_line()
			#print(high_scores)
			#return high_scores
	#else:
		#return null
