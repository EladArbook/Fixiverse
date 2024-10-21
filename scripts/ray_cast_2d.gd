extends RayCast2D

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("interact"):

		if is_colliding():
			var collider = get_collider()
			
			if collider: #DEBUG
				print("colliding with: ", collider.name) #DEBUG
				
			if collider is StaticBody2D and collider.has_method("on_interact"):
				collider.call("on_interact")
				
			else: #DEBUG
				print("no static body or no method") #DEBUG
		else: #DEBUG
				print("Not colliding") #DEBUG
