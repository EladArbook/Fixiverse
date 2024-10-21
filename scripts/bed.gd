extends StaticBody2D

@onready var save_modal = $save_modal

func on_interact():
	save_modal.show_modal()
	#save_modal.visible = true
	#get_tree().paused = true
	

	
	
	
	#await get_tree().create_timer(3.0).timeout
	#get_tree().paused = false
	#save_window.visible = false
