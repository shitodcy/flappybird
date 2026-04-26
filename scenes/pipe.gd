extends Area2D

signal hit 
signal scored

func _on_body_entered(body):
	hit.emit()
	print("Nabrak Pipa")
	
func _on_score_area_body_entered(body):
	scored.emit()
	print("Score +1") 
