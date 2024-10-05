extends Node

@onready var main = $CanvasLayer/Main
@onready var settings = $CanvasLayer/Settings
@onready var texture = $TextureRect
@onready var difficulty_slider = $CanvasLayer/Settings/CenterContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/DifficultySlider
@onready var life_count_slider = $CanvasLayer/Settings/CenterContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/LifeCountSlider
@onready var mob_count_slider = $CanvasLayer/Settings/CenterContainer/PanelContainer/MarginContainer/ScrollContainer/VBoxContainer/MobCountSlider
@onready var button_play = $CanvasLayer/Main/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonPlay
@onready var button_settings = $CanvasLayer/Main/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonSettings
@onready var button_quit = $CanvasLayer/Main/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonQuit


func _ready():
	get_tree().paused = false
	texture.visible = false
	main.visible = false

func _input(event):
	if event.is_action_pressed("pause"):
		if not texture.is_visible_in_tree():
			#self.show()
			texture.visible = true
			main.visible = true
			get_tree().paused = true
			DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)
		else:
			#self.hide()
			texture.visible = false
			main.visible = false
			get_tree().paused = false
			DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CAPTURED)
			
func _on_button_play_pressed():
	PlayerData.difficulty = difficulty_slider.value
	PlayerData.max_life_count = life_count_slider.value
	PlayerData.max_mob_count = mob_count_slider.value
	#$PauseMenu.hide()
	texture.visible = false
	main.visible = false
	get_tree().paused = false
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CAPTURED)
	
func _on_button_settings_pressed():
	difficulty_slider.value = PlayerData.difficulty
	life_count_slider.value = PlayerData.life_count
	mob_count_slider.value = PlayerData.mob_count
	main.visible = false
	settings.visible = true
	
func _on_button_quit_pressed():
	get_tree().change_scene_to_file("res://menu.tscn")

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
