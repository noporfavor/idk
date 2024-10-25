extends CharacterBody2D 

const HAMMER_SCENE_PATH = "res://scenes/hammer.tscn"
var hammer_instance: Sprite2D
const SPEED = 200.0
const JUMP_VELOCITY = -350.0
const DASH_SPEED = 350.0
const DASH_FORCE = 500
const MAX_HEALTH = 50
const PLAYER_HAND = Vector2(5, -5)
var health = MAX_HEALTH
var dashing = false
var can_dash = true
var is_taking_damage = false
var is_dead = false  # Variable para controlar el estado de muerte del jugador
var is_attacking = false # Variable para controlar si el player está atacando
# WEAS RARAS XDDD
var attack_charge_time = 0.0
var max_charge_time = 2.0
var is_attack_charged = false # pormientras XD
var is_charging_attack = false
var charge_time = 0.0
const MAX_CHARGE_TIME = 3.0

@onready var canvas_layer: CanvasLayer = $"../CanvasLayer"
@onready var ui: Control = $"../CanvasLayer/UI"
@onready var life: Control = $"../CanvasLayer/UI/Life"
@onready var coraz_n: TextureRect = $"../CanvasLayer/UI/Life/Corazón"
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var dash_timer: Timer = $dash_timer
@onready var dash_cooldown: Timer = $dash_cooldown
@onready var hit_timer: Timer = $hit_timer  # Temporizador para la animación de "hit"
@onready var death_timer: Timer = $death_timer  # Temporizador para el efecto de muerte
@onready var attack_timer: Timer = $attack_timer
@onready var charge_timer: Timer = $charge_timer

func _ready() -> void:
	var hammer_scene = preload(HAMMER_SCENE_PATH)
	#Instanciar el martillo
	hammer_instance = hammer_scene.instantiate()
	#Agregar martillo al player
	add_child(hammer_instance)
	#Ajustar posición del martillo
	hammer_instance.position = Vector2(PLAYER_HAND)
	#martillo siempre vertical de comienzo
	hammer_instance.rotation_degrees = 0
	var hammer_collider = hammer_instance.get_node("hammer_area/hammer_collider")
	hammer_collider.disabled = true #colider martillo comienza no activo
	# Ajustar temporizadores
	dash_timer.wait_time = 0.3  # (ajustar esto según la duración de la animación de dash_roll)
	hit_timer.wait_time = 0.4   # Tiempo suficiente para reproducir la animación de "hit"
	death_timer.wait_time = 2.0  # Tiempo para la animación de muerte
	attack_timer.wait_time = 0.2 # duraciónm ataque
	
	charge_timer.wait_time = 0.1
	charge_timer.one_shot = false
	
	# Conectar señal de golpe
	if not hammer_instance.is_connected("enemy_hit", Callable(self, "_on_enemy_hit")):
		hammer_instance.connect("enemy_hit", Callable(self, "_on_enemy_hit"))
	# Conectar señales del hit_timer y death_timer
	if not hit_timer.is_connected("timeout", Callable(self, "_on_hit_timer_timeout")):
		hit_timer.connect("timeout", Callable(self, "_on_hit_timer_timeout"))
	if not death_timer.is_connected("timeout", Callable(self, "_on_death_timer_timeout")):
		death_timer.connect("timeout", Callable(self, "_on_death_timer_timeout"))

	# Conectar señales de los otros temporizadores (dash_timer, dash_cooldown)
	if not dash_timer.is_connected("timeout", Callable(self, "_on_dash_timer_timeout")):
		dash_timer.connect("timeout", Callable(self, "_on_dash_timer_timeout"))
	if not dash_cooldown.is_connected("timeout", Callable(self, "_on_dash_cooldown_timeout")):
		dash_cooldown.connect("timeout", Callable(self, "_on_dash_cooldown_timeout"))
# Conectar el temporizador de ataque
	if not attack_timer.is_connected("timeout", Callable(self, "_on_attack_timer_timeout")):
		attack_timer.connect("timeout", Callable(self, "_on_attack_timer_timeout"))
#func _process(_delta):

func _physics_process(delta: float) -> void:
	# Añadir gravedad
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Evitar todo movimiento si está muerto o recibiendo daño
	if is_taking_damage or is_dead:
		return
	# manejar ataque
	if is_attacking:
		if animated_sprite.flip_h:
			#rotar martillo a la izquierda
			hammer_instance.rotation_degrees = lerp(hammer_instance.rotation_degrees, -105.0, 27.0 * delta)
		else:
			#rotar martillo 120 o más grados
			hammer_instance.rotation_degrees = lerp(hammer_instance.rotation_degrees, 105.0, 27.0 * delta)

	# Manejar el salto
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Movimiento con input 
	var direction := Input.get_axis("move_left", "move_right")
	
	# Voltear el sprite según la dirección
	if direction > 0:
		animated_sprite.flip_h = false
		hammer_instance.position.x = abs(hammer_instance.position.x) #martillo a la derecha
		hammer_instance.flip_h = false # //
	elif direction < 0:
		animated_sprite.flip_h = true
		hammer_instance.position.x = -abs(hammer_instance.position.x) #martillo a la izquierda
		hammer_instance.flip_h = true # //
	
	# Control del input del dash
	if Input.is_action_just_pressed("dash") and can_dash:
		hammer_instance.position = Vector2(0, -5)
		var dash_duration = 0.2
		var rotation_speed = 720 * direction
		var dash_tween = create_tween()
		dash_tween.tween_property(hammer_instance,"rotation_degrees", hammer_instance.rotation_degrees + rotation_speed, dash_duration)
		start_dash(direction)
		await dash_tween.finished
		_reset_martillo()

	# Reproducir animaciones
	if not is_taking_damage and not is_dead:  # Controlar todas las animaciones excepto si está en hit o muerto
		# Control del ataque
		if Input.is_action_pressed("attack"):
			if not is_charging_attack and not is_attacking:
				is_charging_attack = true
				charge_time = 0.0
			#elif is_attacking:
				#is_charging_attack = false
				#start_attack()#######################################
				#attack_timer.wait_time = 0.2###AGUANTA UN RATO XD####
			#start_attack()
			#attack_charge_time = 0.0
			#charge_timer.start()
		if is_charging_attack:
			charge_time += delta
			if int(charge_time * 10) % 2 == 0:
				hammer_instance.modulate = Color (1, 1, 1)
			else:
				hammer_instance.modulate = Color (1, 0, 0)
			if charge_time >= MAX_CHARGE_TIME:
				is_charging_attack = false
				is_attacking = true
				execute_attack(true)
		if Input.is_action_just_released("attack") and is_charging_attack:
			is_charging_attack = false
			is_attacking = true
			execute_attack(true)
		#charge_timer.stop()
		#hammer_instance.modulate = Color (1, 1, 1)
		if is_attacking:
			if animated_sprite.animation != "attack":
				animated_sprite.play("attack", true)
				animated_sprite.set_speed_scale(1.6)
		elif dashing:
			# Asegurar que la animación de dash_roll tenga prioridad
			if animated_sprite.animation != "dash_roll":
				animated_sprite.play("dash_roll", true)
		else:
			# Si no está en dash, reproducir las animaciones normales
			if is_on_floor():
				if direction == 0:
					animated_sprite.play("idle")
				else:
					animated_sprite.play("run")
			else:
				animated_sprite.play("jump")
	# velocidad de movimiento normal 
	if direction !=0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	# Aumentar salud al presionar la tecla "H"
	if Input.is_action_just_pressed("health_up"):
		add_health(1)
		update_health_ui()
func execute_attack(is_charged: bool) -> void:
	if is_charged:
		hammer_instance.scale = Vector2(1.5, 1.5)
		hammer_instance.modulate = Color(1, 1, 1, 1)
		start_attack()
		return

func _reset_martillo():
	hammer_instance.position = Vector2(PLAYER_HAND)
	hammer_instance.rotation_degrees = 0
func start_attack() -> void:
	is_attacking = true
	is_attack_charged = false
	var hammer_collider = hammer_instance.get_node("hammer_area/hammer_collider")
	hammer_collider.disabled = false  # Activar el collider
	hammer_instance.rotation_degrees = -20  # Comienza la rotación en -60 grados
	attack_timer.start()
	animated_sprite.play("attack")
	#attack_timer.start()  # Iniciar el temporizador del ataque
func _on_enemy_hit() -> void:
	hit_timer.start()
# Función para comenzar el dash
func start_dash(_direction: float) -> void:
	dashing = true
	can_dash = false
	# Iniciar el dash y reproducir la animación de dash_roll inmediatamente
	animated_sprite.play("dash_roll", true)  # El segundo argumento `true` asegura que la animación comience desde el inicio
	# Iniciar el temporizador del dash
	dash_timer.start()  # Inicia el temporizador del dash (ajustado a 0.8 segundos)
	dash_cooldown.start()  # Inicia el cooldown para poder dashar de nuevo

# Función que devuelve si el jugador está en dash
func is_dashing() -> bool:
	return dashing and animated_sprite.animation == "dash_roll"
# Detener el DASH cuando el temporizador se agote
func _on_dash_timer_timeout() -> void:
	dashing = false
	# Restablecer la animación una vez que el dash termine, siempre y cuando no esté recibiendo daño o esté muerto
	if not is_taking_damage and not is_dead:
		if is_on_floor():
			animated_sprite.play("idle")
		else:
			animated_sprite.play("jump")
# Restablecer la capacidad de dashear después del cooldown
func _on_dash_cooldown_timeout() -> void:
	can_dash = true
# Función para agregar salud al jugador
func add_health(amount: int) -> void:
	health = min(health + amount, MAX_HEALTH)
	print("Health increased: ", health)
# Función de knockback HACER UNA FUNCIÓN DE KNOCKBACK ! XD
# Función para recibir daño
func take_damage(amount: int) -> void:
	# Evitar recibir daño si ya está en el estado de "hit" o está muerto
	if is_taking_damage or is_dead:
		return
	health -= amount
	update_health_ui()
	if health <= 0:
		health = 0
		print("Player is dead!")
		die()  # Llamar a la función de muerte si la salud llega a 0
	else:
		# Reproducir animación de recibir daño y detener otras animaciones
		is_taking_damage = true
		animated_sprite.play("hit")
		hit_timer.start()  # Iniciar el temporizador para la animación de "hit"
		print("Player took damage, health: ", health)
# Función que desactiva el ataque
func _on_attack_timer_timeout() -> void:
	is_attacking = false
	var hammer_collider = hammer_instance.get_node("hammer_area/hammer_collider")
	hammer_collider.disabled = true  # Desactivar el collider
	hammer_instance.rotation_degrees = 0  # Resetear la rotación del martillo
	hammer_instance.scale = Vector2(1, 1) # Martillo vuelve a la normalidad xd
	hammer_instance.modulate = Color(1, 1, 1)
# Función que actualiza la UI de la vida del jugador
func update_health_ui() -> void:
	print("Updating health UI, current health: ", health)
	if health == 2:
		coraz_n.texture = preload("res://assets/sprites/heart_full.png")  # Corazón lleno
	elif health == 1:
		coraz_n.texture = preload("res://assets/sprites/heart_half.png")  # Corazón medio
	elif health <= 0:
		coraz_n.texture = preload("res://assets/sprites/heart_empty.png")  # Corazón vacío
# Función para manejar la muerte del jugador
func die() -> void:
	is_dead = true
	# Reproducir la animación de "death"
	animated_sprite.play("death")
	# Aplicar cámara lenta (reducir el time_scale de la escena)
	Engine.time_scale = 0.4
	# Iniciar temporizador para recargar la escena después de que la animación de muerte termine
	death_timer.start()
# Función que se llama cuando el temporizador de "hit" termina
func _on_hit_timer_timeout() -> void:
	hammer_instance.has_hit_enemy = false
	is_taking_damage = false
	# Restaurar la animación dependiendo del estado del jugador
	if not dashing and not is_dead:  # Si no está en dash ni está muerto, puede restaurar las animaciones normales
		if is_on_floor():
			animated_sprite.play("idle")
		else:
			animated_sprite.play("jump")
func _on_charge_timer_timeout() -> void:
	if hammer_instance.modulate == Color(1, 1, 1):
		hammer_instance.modulate = Color(1, 1, 1, 0.6)
	else:
		hammer_instance.modulate = Color(1, 1, 1)
# Función que se llama cuando el temporizador de "death" termina
func _on_death_timer_timeout() -> void:
	# Restaurar el time_scale a la normalidad
	Engine.time_scale = 1.0
	# Recargar la escena actual
	get_tree().reload_current_scene()
