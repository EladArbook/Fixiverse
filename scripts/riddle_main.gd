extends Node2D

@onready var cost_modal: HBoxContainer = $cost_modal
@onready var cost_container: HBoxContainer = $cost_modal/cost_panel/MarginContainer/cost_container
#@onready var show_parts_order_button: Button = $riddle_modal/MarginContainer/riddle_container/parts_panel/MarginContainer2/instructions_button
@onready var riddle_modal = $riddle_modal
@onready var riddle_container = $riddle_modal/MarginContainer/riddle_container
@onready var riddle_timer_label: Label = $riddle_modal/MarginContainer/riddle_container/timer_panel/MarginContainer/riddle_timer
@onready var riddle_timer_pannel: Panel = $riddle_modal/MarginContainer/riddle_container/timer_panel
@onready var parts_container: HBoxContainer = $riddle_modal/MarginContainer/riddle_container/parts_panel/MarginContainer/parts_container
@onready var parts_panel: Panel = $riddle_modal/MarginContainer/riddle_container/parts_panel
@onready var keys_container: HBoxContainer = $riddle_modal/MarginContainer/riddle_container/keys_panel/MarginContainer/keys_container
@onready var keys_label: Label = $riddle_modal/MarginContainer/riddle_container/keys_panel/MarginContainer2/keys_label
@onready var keys_panel: Panel = $riddle_modal/MarginContainer/riddle_container/keys_panel

@onready var key_riddle_keys: Array
@onready var part_riddle_keys: Array
@onready var num_of_keys: int #depends on stage def / player / power-ups

#general:
var player_kp_panel: Panel
var json_data
var during_part_riddle: bool
var during_key_riddle: bool #attach pause button to confirm modal - canceling main quest
#keys:
var riddle_timer: Timer
var lose_second_timer: Timer
var key_wrong_timer: Timer
var part_wrong_timer: Timer
var max_keys = 8
var key_letter: String
var letters: Array = []
var first_button_key: Button
var letters_index = 0
var stage_details
#parts:
var parts_index = 0
var part_get_focus = 0
var parts_left = 0


func _ready():
	player_kp_panel = get_tree().get_nodes_in_group("player")[0].get_node("%kp_panel")
	riddle_modal.visible = false
	cost_modal.visible = false
	parts_panel.visible = false
	keys_panel.visible = false
	
	_load_riddle_data()

func _process(delta: float) -> void:
	if riddle_timer and riddle_timer.is_stopped() == false:
		var time_left = riddle_timer.time_left
		riddle_timer_label.text = "%0.2f" % time_left


func show_cost_modal() -> void: # Executes by player's interaction function
	player_kp_panel.visible = false
	get_node("%own_kp_label").text = "Own: " + str(GlobalVariables.knowledge_points) +" KP"
	get_tree().paused = true
	cost_modal.visible = true
	cost_container.visible = true
	
	modulate.a = 1.1
	parts_panel.modulate.a = 0.0
	keys_panel.modulate.a = 0.0
	#riddle_modal.modulate.a = 0.0
	#kokok
	var confirm_button = Button.new()
	confirm_button.text = "Enter Challenge \n (cost " + str(stage_details.kp_cost) + "kp)"
	confirm_button.custom_minimum_size = Vector2(110, 110)
	confirm_button.theme = preload("res://themes/game_buttons.tres")
	cost_container.add_child(confirm_button)
	confirm_button.connect("pressed", _on_confirm_challenge)
	
	var cancel_button = Button.new()
	cancel_button.text = "Cancel"
	cancel_button.custom_minimum_size = Vector2(110, 110)
	cancel_button.theme = preload("res://themes/game_buttons.tres")
	cost_container.add_child(cancel_button)
	cancel_button.connect("pressed", _on_cancel_challenge)
	
	if GlobalVariables.knowledge_points >= stage_details.kp_cost:
		confirm_button.grab_focus()
	else:
		confirm_button.disabled = true
		confirm_button.focus_mode = 0
		cancel_button.grab_focus()


func _on_cancel_challenge() -> void:
	
	_disable_cost_container_buttons()
	var hide_riddle_modal_effect = create_tween()
	hide_riddle_modal_effect.tween_property(cost_modal, "modulate:a", 0.0, 0.5)
	hide_riddle_modal_effect.finished.connect(Callable(self, "_after_riddle_modal_fade_out").bind(hide_riddle_modal_effect))


func _after_riddle_modal_fade_out(hide_riddle_modal_effect: Tween) -> void:
	
	hide_riddle_modal_effect.finished.disconnect(Callable(self, "_after_riddle_modal_fade_out").bind(hide_riddle_modal_effect))
	cost_modal.visible = false
	cost_modal.modulate.a = 1.0
	visible = false
	_remove_cost_container_buttons()
	get_tree().paused = false
	player_kp_panel.visible = true


func _remove_cost_container_buttons() -> void:
	var button_remove
	while cost_container.get_child_count() > 0:
		button_remove = cost_container.get_child(0)
		cost_container.remove_child(button_remove)
		


func _disable_cost_container_buttons() -> void:
	var button_disable
	for i in range(cost_container.get_child_count()):
		button_disable = cost_container.get_child(i)
		button_disable.disabled = true

func _on_confirm_challenge() -> void:
	GlobalVariables.knowledge_points -= stage_details.kp_cost
	_disable_cost_container_buttons()
	var hide_cost_modal_effect = create_tween()
	hide_cost_modal_effect.tween_property(cost_modal, "modulate:a", 0.0, 3.0)
	hide_cost_modal_effect.finished.connect(Callable(self, "_after_cost_modal_fade_out").bind(hide_cost_modal_effect))


func _after_cost_modal_fade_out(hide_cost_modal_effect: Tween) -> void:
	
	hide_cost_modal_effect.finished.disconnect(_after_cost_modal_fade_out)		
	cost_modal.visible = false
	_remove_cost_container_buttons()
	_start_part_riddle()


func _on_riddle_time_out()	-> void:
	riddle_timer.stop()
	riddle_timer.disconnect("timeout", _on_riddle_time_out)
	print("Time's up") #DEBUG
	riddle_timer_label.text = "0:00"
	remove_child(riddle_timer)
	
	if during_key_riddle:
		during_key_riddle = false
		keys_panel.visible = true
	if during_part_riddle:
		during_part_riddle = false
		parts_panel.visible = true


func _start_part_riddle() -> void:
	
	parts_panel.visible = true
	parts_container.visible = true
	
	riddle_modal.modulate.a = 0.0
	riddle_modal.visible = true
	var show_riddle_modal_effect = create_tween()
	show_riddle_modal_effect.tween_property(riddle_modal, "modulate:a", 1.0, 1.0) # 5 ?
	show_riddle_modal_effect.finished.connect(_after_riddle_modal_fade_in)	
	

func _after_riddle_modal_fade_in() -> void:
	
	var part_order = []
	
	for i in (stage_details.parts_amount as int):
		var next_button = Button.new()
		next_button.text = ""
		next_button.custom_minimum_size = Vector2(40, 40) #was 36,36 before panel
		var icon_address = "res://assets/items/Fixable/" + stage_details.item_name+ str(i) + ".png"
		next_button.set_button_icon(load(icon_address))
		next_button.set_meta("order_key", i)
		next_button.disabled = true
		next_button.modulate.a = 0.0
		next_button.connect("pressed", Callable(self, "_on_part_button_pressed").bind(next_button))
		next_button.theme = preload("res://themes/main_riddle_part.tres")
		part_order.append(next_button)

	var show_parts_panel_effect = create_tween()
	show_parts_panel_effect.tween_property(parts_panel, "modulate:a", 1.0, 1.5)
	show_parts_panel_effect.finished.connect(_after_parts_panel_fade_in)		
	part_order.shuffle()
	
	for part_button in part_order:
		parts_container.add_child(part_button)


func _after_part_disappear(button: Button) -> void:
	parts_container.remove_child(button)
	if parts_container.get_child_count() > 0:
		parts_container.get_child(0).grab_focus()
	else:
		var hide_parts_panel_effect = create_tween()
		hide_parts_panel_effect.tween_property(parts_panel, "modulate:a", 0.0, 1.0)
		hide_parts_panel_effect.finished.connect(_after_parts_panel_fade_out)


func _after_parts_panel_fade_out() -> void: #_end_part_riddle()
	print("pause timer for 2 sec")
	during_part_riddle = false
	#parts_panel.visible = false
	_start_key_riddle()


func _after_parts_panel_fade_in() -> void: # Timer starts
	#riddle_timer_label.text = "11:11" #continue here
	for i in range(parts_container.get_child_count()):
		var show_parts_effect = create_tween()
		var part_button = parts_container.get_child(i)
		show_parts_effect.tween_property(part_button, "modulate:a", 1.0, 1.0)
		show_parts_effect.finished.connect(_start_timer)
		part_button.disabled = false
	parts_container.get_child(0).grab_focus() #first part focus
	print("Riddle loaded, start timer!")
	
	
func _start_timer() -> void:
	if not riddle_timer:
		riddle_timer = Timer.new()
	riddle_timer.wait_time = 10.0
	riddle_timer.connect("timeout", _on_riddle_time_out)
	add_child(riddle_timer)
	riddle_timer.start()
	during_part_riddle = true


func _start_key_riddle() -> void:
	
	keys_panel.modulate.a = 0.0
	var key_theme = preload("res://themes/main_riddle_letter.tres")
	_generate_random_keys(num_of_keys)
	keys_label.text = "Keys left: " + str(letters.size())
	for key in letters: #creating key buttons
		var new_key_button = Button.new()
		new_key_button.set_theme(key_theme)
		new_key_button.text = key
		new_key_button.custom_minimum_size = Vector2(40, 40) #was 36,36 before panel
		new_key_button.disabled = true
		new_key_button.visible = false
		keys_container.add_child(new_key_button)
		
	keys_panel.visible = true
	var show_keys_panel_effect = create_tween()
	show_keys_panel_effect.tween_property(keys_panel, "modulate:a", 1.0, 1.0)
	show_keys_panel_effect.finished.connect(_on_start_key_riddle)
	
	var minimum_keys = min(letters.size(), 8)
	for i in minimum_keys:
		keys_container.get_child(i).visible = true
		
		#first letter
	if letters.size() > 0:
		key_letter = letters[0]
		first_button_key = keys_container.get_child(0)
		first_button_key.disabled = false
		
	during_key_riddle = true


func _on_start_key_riddle() -> void:
	riddle_timer.paused = false
	print("Starting keys riddle")


func _end_key_riddle() -> void:
	during_key_riddle = false
	var hide_keys_panel_effect = create_tween()
	hide_keys_panel_effect.tween_property(riddle_container, "modulate:a", 0.0, 1)
	hide_keys_panel_effect.finished.connect(_on_finish_key_riddle)


func _on_finish_key_riddle() -> void:
	var hide_timer_effect = create_tween()
	#hide_timer_effect.tween_property(riddle_container, "modulate:a", 0.0, 1)
	#hide_timer_effect.finished.connect(_on_riddle_disappear)

	
func _on_riddle_disappear() -> void:
	print("pass")


func _load_riddle_data() -> void:
	#Load riddle data
	var file = FileAccess.open("res://texts/riddles_data.json", FileAccess.READ)
	if file:
		var json_parser = JSON.new()
		var parse_result = json_parser.parse(file.get_as_text())
		
		if parse_result == OK:
			var json_data = json_parser.data
			if json_data.size() > 0:
				
				if json_data.has("key_riddle_keys"):
					key_riddle_keys = json_data.key_riddle_keys
				else:
					print("Didn't load key riddle keys")
				if json_data.has("stage_details") and json_data.stage_details.has("stage1"):
					stage_details = json_data.stage_details.stage1
					print("END EDITING RIDDLE: ",stage_details)
					num_of_keys = stage_details.keys_amount
				else:
					print("Didn't load stage info")
					
			else:
				print("JSON data loaded with an issue")
		else:
				print("JSON data file load issue")
	
		file.close()
		
	else:
		print("Failed to open JSON file.")


func _generate_random_keys(x: int) -> void:
	var letters_set: Array = ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "A", "S", "D", "F", "G", "H", "J", "K", "L"]
	letters.clear()
	for i in range(x):
		var random_index = randi() % letters_set.size()
		letters.append(letters_set[random_index])


func _right_key() -> void:
	keys_label.text = "Keys left: " + str(letters.size() - letters_index)
	letters_index += 1
	keys_label.text = "Keys left: " + str(letters.size() - letters_index)
	if keys_container.get_child_count() > 1:		# get next key
		first_button_key = keys_container.get_child(1) 
		first_button_key.disabled = false
		first_button_key.grab_focus()
		if letters_index < letters.size(): #Just in case
			key_letter = letters[letters_index]
	else: #DEBUG
		print("No more keys... END TIMER")
		print("Riddle solved!")
		player_kp_panel.visible = true
		GlobalVariables.knowledge_points += stage_details.kp_reward
		riddle_timer.stop()
	_remove_prev_key()


func _remove_prev_key() -> void: #removing previous key
	first_button_key = keys_container.get_child(0)
	var hide_key_effect = create_tween()
	hide_key_effect.tween_property(first_button_key, "modulate:a", 0.0, 0.1)
	hide_key_effect.finished.connect(_on_key_disappear)


func _on_key_disappear() -> void: #on tween finished
	keys_container.remove_child(keys_container.get_child(0))
	first_button_key = keys_container.get_child(0)
	_show_next_keys()
	print("add right/correct key sound") #up the tree, not here!
	if keys_container.get_child_count() == 0:
		_end_key_riddle()


func _show_next_keys() -> void:
	if keys_container.get_child_count() >= max_keys:
		keys_container.get_child(0).grab_focus()
		var amount_of_keys = min(keys_container.get_child_count(), 8)
		for i in (amount_of_keys):
			var button_key = keys_container.get_child(i)
			if button_key and not button_key.visible:
				button_key.modulate.a = 0.0
				button_key.visible = true
				var show_key_effect = create_tween()
				show_key_effect.tween_property(button_key, "modulate:a", 1.0, 0.3)


func _input(event) -> void:
	
	if event is InputEventKey and event.pressed and not event.echo:
		var key_pressed_code = event.physical_keycode

		

		
		if during_part_riddle: #and parts_left > 1:
			if key_pressed_code == 73:
				print("Show instructors")
			elif key_pressed_code != 4194319 or key_pressed_code != 4194321 or key_pressed_code != 38:
				if part_wrong_timer and not part_wrong_timer.is_stopped():
					part_wrong_timer.stop()
			
		elif during_key_riddle:
			
			if key_riddle_keys.has(key_pressed_code as float):
				if key_wrong_timer and not key_wrong_timer.is_stopped():
					key_wrong_timer.stop()
				if key_pressed_code == key_letter.to_utf8_buffer()[0]: #change to key_letter.physical_keycode
					_right_key()
				else:
					_wrong_key()
			else: #The key is not used in riddles
				return


func _on_part_button_pressed(button: Button) -> void:
	if during_part_riddle:
		if parts_container.get_child_count() <= 1:
			riddle_timer.paused = true
			print("Part riddle finished! Key riddle is loading... ")
			
		if during_part_riddle and parts_index == button.get_meta("order_key"):
			
			parts_index += 1
			var remove_part_button_effect = create_tween()
			remove_part_button_effect.tween_property(button, "modulate:a", 0.0, 0.1)
			remove_part_button_effect.finished.connect(Callable(self, "_after_part_disappear").bind(button))
	
			button.disabled = true
			button.focus_mode = 0
			
		else:
			
			button.modulate = Color(1,0,0,0.5)
			part_wrong_timer = Timer.new()
			add_child(part_wrong_timer)
			part_wrong_timer.wait_time = 0.1
			part_wrong_timer.connect("timeout", Callable(self, "_on_wrong_part_timeout").bind(button))
			part_wrong_timer.start()
			_time_lose_penalty()
			print("Wrong part! -time")


func _on_wrong_part_timeout(button) -> void:
	
	button.modulate = Color (1,1,1,1)
	part_wrong_timer.disconnect("timeout", _on_wrong_part_timeout)
	remove_child(part_wrong_timer)


func _time_lose_penalty() -> void:
	
	print("-time (", stage_details.wrong_penalty,")")
	var remaining_time = riddle_timer.time_left
	riddle_timer.stop()
	
	if remaining_time < stage_details.wrong_penalty:
		print("-time got you lose the riddle") #DEBUG
		remaining_time = 0
		riddle_timer_label.text = "0:00"
		_on_riddle_time_out()
		
	else:
		remaining_time -= stage_details.wrong_penalty
		riddle_timer.wait_time = remaining_time
		riddle_timer.start()


func _on_lose_second_timer_timeout() -> void:
	riddle_timer_pannel.modulate = Color (1,1,1,1)
	lose_second_timer.disconnect("timeout", _on_lose_second_timer_timeout)
	remove_child(riddle_timer_pannel)
	

func _wrong_key() -> void:
	first_button_key.modulate = Color(1,0,0,0.5)
	key_wrong_timer = Timer.new()
	add_child(key_wrong_timer)
	key_wrong_timer.wait_time = 0.1
	key_wrong_timer.connect("timeout", _on_wrong_key_timeout)
	key_wrong_timer.start()
	_time_lose_penalty()
	print("Wrong key!") #DEBUG


func _on_wrong_key_timeout() -> void:
	keys_container.get_child(0).modulate = Color (1,1,1,1)
	key_wrong_timer.disconnect("timeout", _on_wrong_key_timeout)
