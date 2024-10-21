extends ProgressBar




var health = 0 : set = _set_health

func _ready() -> void:
	_set_health(health)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _set_health(new_health):
	#var prev_health = health
	health = clamp(new_health, 0, max_value)
	#health = min(max_value, new_health)
	value = health
	

func init(_health):
	health = _health
	#max_value = health
	value = health
