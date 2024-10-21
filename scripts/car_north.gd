extends RigidBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var damage_area: Area2D = $damage_area
@onready var player: CharacterBody2D


var initial_position: Vector2

func _ready() -> void:
	player = get_tree().get_nodes_in_group("player")[0]
	initial_position = global_position
	animated_sprite.flip_v = true
	animated_sprite.play("drive")
	linear_velocity = Vector2(0, -325)
	damage_area.connect("body_entered", _on_damage_area_body_entered)



func _process(delta: float) -> void:
	if global_position.y < initial_position.y - 700:
		global_position = initial_position
		linear_velocity = Vector2(0, -325)


func _on_damage_area_body_entered(body: Node2D) -> void:
	if body == player:
		if animated_sprite.get_animation() == "drive":
			animated_sprite.connect("animation_finished", _stop_alert)
			animated_sprite.play("alert")
		player.damage()


func _stop_alert() -> void:
	animated_sprite.disconnect("animation_finished", _stop_alert)
	animated_sprite.play("drive")


		
