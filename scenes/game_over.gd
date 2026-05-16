extends CanvasLayer

signal restart

@onready var score_value = $VBoxContainer/ScoreValue
@onready var high_score_value = $VBoxContainer/HighScoreValue

func set_scores(current_score: int, high_score_data: int):
	score_value.text = str(current_score)
	high_score_value.text = str(high_score_data)

func _on_restart_button_pressed():
	restart.emit()
	
func _on_exit_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
