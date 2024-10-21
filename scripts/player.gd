#@tool

extends CharacterBody2D

@export var speed = 60 #100
@export var interaction_distance = 17 #17
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar = $HealthBar/DamageBar
@onready var raycast = $RayCast2D
@onready var damage_timer: Timer = $Damage_Timer

#var push_force = 100
var lastDirection = "idle_front" #(down)
var direction_before_emote = "idle_front"
var facing_direction = Vector2(0, -1)  #(down)
const MAX_HEALTH = 3
var health = MAX_HEALTH
var can_take_damage = true #Damage delay
var during_emote = false
var running_skill = false
var skills_on_theme = load("res://themes/skill_icon_on.tres")
var skills_off_theme = load("res://themes/skill_icon_off.tres")

@onready var kp_panel: Panel = $kp_container/kp_panel
@onready var kp_label: Label = $kp_container/kp_panel/MarginContainer/Label
@onready var saveModal = $pausable/Home/zone_home/use/bed/save_modal

func _ready() -> void:
	#get_node("%running_skill")		# USE AS UNIQUE NAME
	GlobalVariables.knowledge_points = 10 # DEBUG / from save or -zero-
	kp_label.text = str(GlobalVariables.knowledge_points) + "kp"
	
	set_collision_mask_value(3, true)
	set_health_bar()
	raycast.enabled = true
	damage_timer.wait_time = 3  # Set the timer for a 3-second delay
	damage_timer.one_shot = true  # Make sure the timer only runs once per damage event
	

func _process(delta) -> void:

	if Input.is_action_just_pressed("running_skill"):
		if running_skill:
			running_skill = false
			get_node("%running_skill").theme = skills_off_theme
			speed = 60
		else:
			running_skill = true
			get_node("%running_skill").theme = skills_on_theme
			speed = 90
	kp_label.text = str(GlobalVariables.knowledge_points) + "kp"
	
	# Get the input direction: left(-1,0) right(1,0) up(0,1) down(0,-1)
	
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction.length() != 0 and during_emote == true:
		during_emote = false
		animated_sprite.disconnect("animation_finished", _end_emote)

	#position += direction * speed * delta ########## before added velocity
	velocity = direction * speed
	move_and_slide()
	if !can_take_damage and health > 0:
		if animated_sprite.frame % 2 == 1:
			animated_sprite.visible = false
		else:
			animated_sprite.visible = true
	
	# Update facing direction based on movement
	if direction.x > 0:
		facing_direction = Vector2(1, 0)  # Facing right
		if running_skill:
			animated_sprite.play("run_right")
		else:
			animated_sprite.play("walk_right")
		lastDirection = "idle_right"
	elif direction.x < 0:
		facing_direction = Vector2(-1, 0)  # Facing left
		if running_skill:
			animated_sprite.play("run_left")
		else:
			animated_sprite.play("walk_left")
		lastDirection = "idle_left"
	elif direction.y > 0:
		facing_direction = Vector2(0, 1)  # Facing down
		if running_skill:
			animated_sprite.play("run_front")
		else:
			animated_sprite.play("walk_front")
		lastDirection = "idle_front"
	elif direction.y < 0:
		facing_direction = Vector2(0, -1)  # Facing up
		if running_skill:
			animated_sprite.play("run_back")
		else:
			animated_sprite.play("walk_back")
		lastDirection = "idle_back"
	direction_before_emote = lastDirection
	if direction.length() == 0 and not during_emote:
		animated_sprite.play(lastDirection)
			
	# Handle interaction
	if Input.is_action_just_pressed("interact"):
		interact_with_object(direction)
		#damage()#DEBUG
	if Input.is_action_just_pressed("emote_one"):
		during_emote = true
		animated_sprite.connect("animation_finished", _end_emote)
		animated_sprite.play("emote_one")
		
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is RigidBody2D and c.get_collider().is_in_group("enemy"):
			damage()

func _end_emote() -> void:
	animated_sprite.disconnect("animation_finished", _end_emote)
	during_emote = false
	lastDirection = direction_before_emote


func damage():
	if can_take_damage:
		can_take_damage = false
		set_collision_mask_value(3, false)
		#health -=1; DEBUG
		
		set_health_bar()	
		if health > 0:
			#print("Play damage sound")
			damage_timer.start()
		if health == 0:
			print("Play game over sound")
			
		print("Damage taken") #DEBUG	
		
func heal(): 								# not used yet!!!!!!!!!!!!!!!!!@!#$!$!$!$!@#$!@#@!#!@#!@
	if health < MAX_HEALTH:
		health += 1
		set_health_bar()		
		print("The cheese heals you") #DEBUG	
	else: #DEBUG
		print("You're already full") #DEBUG	
		
func _on_damage_timer_timeout() -> void:
	set_collision_mask_value(3, true)
	can_take_damage = true  # Re-enable damage after 3 seconds
	animated_sprite.visible = true

func set_health_bar():
	$HealthBar.init(health)	

func interact_with_object(direction:Vector2) -> void:
	
	raycast.target_position = raycast.position + facing_direction * interaction_distance
	raycast.force_raycast_update()
	animated_sprite.connect("animation_finished", _end_emote)
	during_emote = true
	if lastDirection == "idle_right":
		animated_sprite.play("interact_right")
	elif lastDirection == "idle_left":
		animated_sprite.play("interact_left")
	elif lastDirection == "idle_front":
		animated_sprite.play("interact_front")
	elif lastDirection == "idle_back":
		animated_sprite.play("interact_back")
	#queue_redraw() #DEBUG
	
	
func _draw() -> void: #DEBUG
	if during_emote:
		draw_line(raycast.position, raycast.target_position, Color(1, 0, 0))  # Red debug line
	

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		damage()
	if body.is_in_group("enemy") and body.has_method(""):
		pass
