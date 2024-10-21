extends RigidBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var danger_area: Area2D = $Area2D
@onready var cat_shape: CollisionShape2D = $CollisionShape2D
@onready var damage_area: Area2D = $damage_area
@onready var player: CharacterBody2D

var initial_position: Vector2
#var target_position: Vector2

func _ready() -> void:
	player = get_tree().get_nodes_in_group("player")[0]
	animated_sprite.flip_h = true
	#cat_shape.set_deferred("disabled", true)
	linear_velocity = Vector2(0, 0)
	initial_position = global_position
	animated_sprite.play("sleep")
	
	damage_area.connect("body_entered", _on_damage_area_body_entered)
	
	
func _process(delta: float) -> void:
	pass
	
	
func _on_damage_area_body_entered(body: Node2D) -> void:
	if body == player:
		player.damage()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if global_position.x == initial_position.x and animated_sprite.get_animation() == "sleep":
		if body.is_in_group("player"):
			engage()


func engage() -> void:
	animated_sprite.connect("animation_finished", _on_cat_waked_up)
	animated_sprite.play("wake_up")
	#cat_shape.set_deferred("disabled", false)


func _on_cat_waked_up() -> void:
	animated_sprite.disconnect("animation_finished", _on_cat_waked_up)
	animated_sprite.connect("animation_finished", _cat_stays_engaged)
	animated_sprite.play("engage")
	linear_velocity = Vector2(-150,0)
	
	
func _cat_stays_engaged() -> void:
	animated_sprite.disconnect("animation_finished", _cat_stays_engaged)
	animated_sprite.connect("animation_finished", _cat_goes_back)
	animated_sprite.play("stay_engaged")
	linear_velocity = Vector2(0,0)


func _cat_goes_back() -> void:
	animated_sprite.disconnect("animation_finished", _cat_goes_back)
	animated_sprite.flip_h = false
	linear_velocity = Vector2(20,0)
	animated_sprite.connect("animation_finished", _cat_sit_down)
	animated_sprite.play("walk")


func _cat_sit_down() -> void:
		animated_sprite.disconnect("animation_finished", _cat_sit_down)
		animated_sprite.flip_h = true
		linear_velocity = Vector2(0,0)
		global_position = initial_position
		animated_sprite.play("sit_down")
		animated_sprite.connect("animation_finished", _cat_lie_down)


func _cat_lie_down() -> void:
	animated_sprite.disconnect("animation_finished", _cat_lie_down)
	animated_sprite.connect("animation_finished", _cat_go_sleep)
	animated_sprite.play("lie_down")
	#cat_shape.set_deferred("disabled", true)


func _cat_go_sleep() -> void:
	animated_sprite.disconnect("animation_finished", _cat_go_sleep)
	animated_sprite.play("sleep")
	if danger_area.get_overlapping_bodies():
		for i in danger_area.get_overlapping_bodies():
			if i is CharacterBody2D and i.is_in_group("player"):
				engage()
	
	
	#attack_timer.start()
#func _on_timer_timeout() -> void:	
#	engage()
	
