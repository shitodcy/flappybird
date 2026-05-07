extends CanvasLayer

signal restart


func _on_restart_button_pressed():
	print("Permainan dimulai")
	restart.emit()
