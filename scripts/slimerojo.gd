extends CharacterBody2D

const SPEED = 60
const GRAVITY = 1000
const JUMP_FORCE = -100
const MAX_FALL_SPEED = 400
const JUMP_ACCELERATION = 100  # Aceleración extra durante el salto

var direction = 1
var health = 2
var is_hit = false
var is_dead = false
var is_jumping = false  # Se usa para evitar múltiples saltos

@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_2d: Area2D = $Area2D
@onready var hit_timer: Timer = $hit_timer
@onready var die_timer: Timer = $die_timer
@onready var game: Node2D = $".."
@warning_ignore("unused_signal")
signal slime_dead

func _ready() -> void:
	# Configurar colisiones para ignorar otros enemigos
	collision_layer = 2
	collision_mask &= ~2  # Ignorar otros enemigos
	#señal para detectar enemigos con elhammer
	
	# Asegurarse de que los raycasts ignoren al jugador
	ray_cast_right.collision_mask &= ~2
	ray_cast_left.collision_mask &= ~2
	
	# Conectar señales
	area_2d.connect("body_entered", Callable(self, "_on_player_detected"))
	hit_timer.wait_time = 0.5
	die_timer.wait_time = 0.5

func _physics_process(delta: float) -> void:
	if not is_hit and not is_dead:
		# Detectar colisiones con paredes
		if ray_cast_right.is_colliding():
			direction = -1
			animated_sprite.flip_h = true
		elif ray_cast_left.is_colliding():
			direction = 1
			animated_sprite.flip_h = false

		# Movimiento horizontal si no está saltando
		if not is_jumping:
			velocity.x = direction * SPEED

		# Aplicar gravedad
		if not is_on_floor():
			velocity.y += GRAVITY * delta
			velocity.y = min(velocity.y, MAX_FALL_SPEED)
		else:
			velocity.y = 0
			is_jumping = false  # Restablecer estado al tocar el suelo

		# Mover al slime
		move_and_slide()

		if not is_jumping:
			animated_sprite.play("default")  # Animación de caminar

# Detectar al jugador en el área
func _on_player_detected(body: Node) -> void:
	if body.is_in_group("Player") and not is_jumping:
		jump_towards_player(body.global_position)

# Saltar agresivamente hacia el jugador con aceleración
func jump_towards_player(player_position: Vector2) -> void:
	is_jumping = true
	animated_sprite.play("jump")

	# Calcular la dirección hacia el jugador
	var jump_direction = (player_position - global_position).normalized()
	
	# Ajuste de la dirección del salto
	if jump_direction.x > 0:
		animated_sprite.flip_h = false  # Saltar hacia la derecha
	else:
		animated_sprite.flip_h = true  # Saltar hacia la izquierda
	velocity.y = JUMP_FORCE  # Aplicar fuerza de salto hacia arriba
	velocity.x = jump_direction.x * (SPEED + JUMP_ACCELERATION)  # Saltar con aceleración

	move_and_slide()

# Al colisionar con el jugador
func _on_area_2d_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		if body.is_dashing():
			apply_damage(1)  # El jugador debería poder hacerle daño durante el dash
		else:
			body.take_damage(1)  # El slime hace daño al jugador al tocarlo

# Aplicar daño al slime
func apply_damage(damage: int) -> void:
	if not is_hit and not is_dead:
		health -= damage
		if health > 0:
			is_hit = true
			animated_sprite.play("get_hit")
			hit_timer.start()
		else:
			die()

# Manejar la muerte
func die() -> void:
	if not is_dead:
		is_dead = true
		emit_signal("slime_dead")
		animated_sprite.play("dying")
		die_timer.start()  # Esperar antes de eliminar el slime

# Restablecer estado después de un golpe
func _on_hit_timer_timeout() -> void:
	is_hit = false

# Eliminar slime después de morir
func _on_die_timer_timeout() -> void:
	queue_free()  # Eliminar el slime de la escena
