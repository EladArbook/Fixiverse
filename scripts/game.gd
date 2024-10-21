extends Node2D





func _ready() -> void:
	pass
	
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		toggle_pause()


func toggle_pause():
	print("pause just pressed")
	var tree = get_tree()
	if get_tree().paused:
		get_tree().paused = false
		#if(saveModal):
		#	saveModal.hide()
	else:
		get_tree().paused = true
