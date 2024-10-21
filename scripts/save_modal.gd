extends Control
	
signal confirmed(is_confirmed: bool)

@onready var header_label: Label = %Save_Label
@onready var confirm_button: Button = %save
@onready var cancel_button: Button = %cancel

var is_open: bool = false

var _should_unpause

func _ready():
	set_process_unhandled_key_input(false)
	if confirm_button:
		confirm_button.pressed.connect(_on_confirm_button_pressed)
	if cancel_button:
		cancel_button.pressed.connect(_on_cancel_button_pressed)
	set_process(true)
	hide()
	

func _process(delta: float) -> void:
	pass

func show_modal():
	get_tree().paused = true
	var is_confirmed = await prompt()
	_close_modal(is_confirmed)
#func _unhandled_key_input(event: InputEvent) -> void:
#	if event.is_action_pressed("pause"):
#		print("cancelllllllllll")
#		cancel()

func prompt(pause:bool = false) -> bool: 						#DELETE?
	_should_unpause = get_tree().paused == false and pause
	if _should_unpause:
		get_tree().paused = true
	show()
	is_open = true
	set_process_unhandled_key_input(true)			
	var is_confirmed = await confirmed
	return is_confirmed
	
	
#func close(is_confirmed:bool):
#	print(123)
#	if is_confirmed:
#		confirm()
#	else:
#		cancel()
#	get_tree().paused = false
	
	
func _on_confirm_button_pressed() -> void:
	confirm()


func _on_cancel_button_pressed() -> void:
	cancel()

func confirm() -> void:
	#_close_modal(true)
	print("SAVING GAME...")
	_close_modal(true)

	
func cancel():
	#_close_modal(false)
	print("Hold on")
	_close_modal(false)

func _close_modal(is_confirmed:bool) -> void:
	set_process_unhandled_key_input(false)
	hide()
	get_tree().paused = false
