extends StaticBody2D

@onready var riddle: Node2D = $riddle_Main

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	riddle.visible = false
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func on_interact():
	print("Clock")
	riddle.visible = true
	riddle.show_cost_modal()
