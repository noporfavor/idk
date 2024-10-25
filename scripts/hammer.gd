extends Sprite2D

signal enemy_hit
@onready var hammer_area: Area2D = $hammer_area
@export var damage_amount: int = 1
var hit_stop_duration = 0.1
var is_hit_stopping = false
var has_hit_enemy = false

func _on_hammer_area_body_entered(body: Node2D) -> void:
	if has_hit_enemy:
		return
	if body.is_in_group("slimes"):
		body.apply_damage(damage_amount)
		hit_stop()
		has_hit_enemy = true
		emit_signal("enemy_hit")
	elif body.is_in_group("ground"):
		var player = get_parent()
		player.velocity.y = -300.0

func hit_stop() -> void:
	if not is_hit_stopping:
		is_hit_stopping = true
		get_tree().paused = true
		await get_tree().create_timer(hit_stop_duration).timeout
		get_tree().paused = false
		is_hit_stopping = false
