extends CharacterBody2D  # Cambio Node2D por CharacterBody2D

const SPEED = 60
const GRAVITY = 1000  # La fuerza de la gravedad
const MAX_FALL_SPEED = 400  # Velocidad máxima de caída
var direction = 1
var health = 2  # El enemigo tiene 2 puntos de vida
var is_hit = false  # Variable para manejar si el enemigo está siendo golpeado
var is_dead = false  # Variable para manejar si el enemigo ha muerto


@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_2d: Area2D = $AnimatedSprite2D/Area2D
@onready var hit_timer: Timer = $hit_timer
@onready var die_timer: Timer = $die_timer
@onready var game: Node2D = $".."
@warning_ignore("unused_signal")
signal slime_dead
func _ready() -> void:
	# Configurar las colisiones para ignorar otros enemigos
	collision_layer = 2  # Establece la capa 2 para los enemigos
	collision_mask &= ~2  # Evita que detecten la capa 2 (otros enemigos)
	if not area_2d.is_connected("body_entered", Callable(self, "_on_area_2d_body_entered")):
		area_2d.connect("body_entered", Callable(self, "_on_area_2d_body_entered"))
	hit_timer.wait_time = 0.5 # Tiempo para reproducir la animación get_hit
	die_timer.wait_time = 0.5 # Tiempo para reproducir la animación die

func _physics_process(delta: float) -> void:  # Cambia _process por _physics_process para que funcione con la física
	if not is_hit and not is_dead:  # Solo se mueve si no está siendo golpeado y no está muerto
		if ray_cast_right.is_colliding():
			direction = -1
			animated_sprite.flip_h = true
		elif ray_cast_left.is_colliding():
			direction = 1
			animated_sprite.flip_h = false
		
		# Movimiento horizontal
		velocity.x = direction * SPEED

		# Aplicar gravedad
		if not is_on_floor():  # Si no está en el suelo, aplicar gravedad
			velocity.y += GRAVITY * delta
			velocity.y = min(velocity.y, MAX_FALL_SPEED)  # Limitar la velocidad de caída
		else:
			velocity.y = 0  # Restablecer la velocidad vertical si está en el suelo

		# Mover al enemigo
		move_and_slide()

		animated_sprite.play("default")  # Reproducir animación de caminar

func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):  # Verifica que el cuerpo sea el jugador
		if body.is_dashing():
			apply_damage(1)
		else:
			body.take_damage(1)

func apply_damage(damage: int) -> void:
	if not is_hit and not is_dead:  # Permitir daño solo si no está en estado "get_hit" y no está muerto
		health -= damage
		if health > 0:
			is_hit = true  # Marcar que el enemigo ha sido golpeado
			animated_sprite.play("get_hit")  # Reproducir animación de recibir daño
			hit_timer.start()  # Iniciar temporizador para restaurar movimiento tras animación
		else:
			die()

func _on_hit_timer_timeout() -> void:
	is_hit = false  # Restaurar el estado de golpe
	if health > 0:
		animated_sprite.play("default")  # Volver a la animación de caminar

func die() -> void:
	if not is_dead:
		is_dead = true  # Marcar que el enemigo ha muerto
		emit_signal("slime_dead")
		animated_sprite.play("dying")  # Reproducir animación de muerte
		await get_tree().create_timer(0.5).timeout  # Esperar 0.5 segundos para que se reproduzca la animación
		queue_free()  # Eliminar el enemigo del juego
