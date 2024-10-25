extends Area2D

@onready var player = null  # Variable para almacenar la referencia al jugador
@onready var canvas_layer: CanvasLayer = $"../CanvasLayer"
@onready var ui: Control = $"../CanvasLayer/UI"
@onready var life: Control = $"../CanvasLayer/UI/Life"
@onready var coraz_n: TextureRect = $"../CanvasLayer/UI/Life/Corazón"
#@onready var player: CharacterBody2D = $"."

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):  # Verificar si el cuerpo que entró es el jugador
		player = body  # Almacenar la referencia al jugador
		player.add_health(1)  # Llamar a la función para aumentar la salud
		player.update_health_ui()
		queue_free()  # Hacer que el área desaparezca
