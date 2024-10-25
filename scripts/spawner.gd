extends Node2D  # El nodo principal del nivel

@onready var wave_count: Label = $"../CanvasLayer/UI/WaveCount"
@export var slime_rojo_scene: PackedScene  # La escena del slime rojo
@export var slime_scene: PackedScene  # La escena del slime verde
@export var fruit_scene: PackedScene  # La escena de la fruta
@export var initial_wave_count: int = 2  # Número de slimes en la primera oleada
@export var wave_delay: float = 3.5  # Tiempo entre oleadas en segundos
@export var spawn_area_min: Vector2  # Coordenadas mínimas del área de spawn (esquina inferior izquierda)
@export var spawn_area_max: Vector2  # Coordenadas máximas del área de spawn (esquina superior derecha)
@export var max_attempts: int = 10  # Número máximo de intentos para encontrar un punto válido sin colisión
@export var slime_radius: float = 16.0  # Radio aproximado de los slimes para chequeo de colisión
@warning_ignore("unused_signal") #ignorar la señal no usada por ahora
signal slime_dead
var current_wave: int = 1  # Oleada actual
var slimes_in_wave: int  # Número de slimes en la oleada actual
var is_wave_active: bool = false  # Para saber si hay una oleada activa
var slimes_alive: int = 0  # Número de slimes vivos en la oleada actual
var timer: Timer  # Temporizador para manejar el spawn entre oleadas

func _ready() -> void:
	if spawn_area_min == spawn_area_max:
		push_error("El área de spawn no está correctamente definida. Configura spawn_area_min y spawn_area_max en el editor.")
		return

	# Inicializar el temporizador para manejar las oleadas
	timer = Timer.new()
	add_child(timer)
	timer.connect("timeout", Callable(self, "_start_wave"))
	timer.start(wave_delay)

func _start_wave() -> void:
	if not is_wave_active:
		slimes_in_wave = initial_wave_count + current_wave  # Progresión de a +1
		slimes_alive = slimes_in_wave  # Inicializar el número de slimes vivos
		spawn_slimes()  # Llama a la función sin argumentos
		wave_count.update_wave_counter()
		current_wave += 1
		is_wave_active = true

func spawn_slimes() -> void:
	for i in range(slimes_in_wave):
		var spawn_position: Vector2 = find_valid_spawn_position()
		
		if spawn_position != Vector2.ZERO:
			var slime_instance: CharacterBody2D
			if randi() % 2 == 0:
				slime_instance = slime_scene.instantiate()  # Instancia de slime verde
			else:
				slime_instance = slime_rojo_scene.instantiate()  # Instancia de slime rojo

			slime_instance.position = spawn_position
			get_tree().current_scene.add_child(slime_instance)
			slime_instance.connect("slime_dead", Callable(self, "_on_slime_died"))
		else:
			push_warning("No se encontró un punto válido para el spawn del slime.")
			

func find_valid_spawn_position() -> Vector2:
	var space_state = get_world_2d().direct_space_state
	var attempts = 0
	var shape = CircleShape2D.new()
	shape.radius = slime_radius
	
	while attempts < max_attempts:
		var random_x = randf_range(spawn_area_min.x, spawn_area_max.x)
		var random_y = randf_range(spawn_area_min.y, spawn_area_max.y)
		var candidate_position = Vector2(random_x, random_y)
		
		var shape_params = PhysicsShapeQueryParameters2D.new()
		shape_params.shape = shape
		shape_params.transform.origin = candidate_position
		shape_params.collision_mask = 1
		
		var result = space_state.intersect_shape(shape_params)
		
		if result.size() == 0:
			return candidate_position
		
		attempts += 1

	return Vector2.ZERO

func _on_slime_died() -> void:
	slimes_alive -= 1
	if slimes_alive <= 0:
		is_wave_active = false
		timer.start(wave_delay)

		# Instanciar la fruta cuando termine la oleada
		spawn_fruit()

# Función para spawnear la fruta
func spawn_fruit() -> void:
	var fruit_position: Vector2 = find_valid_spawn_position()
	
	if fruit_position != Vector2.ZERO:
		var fruit_instance = fruit_scene.instantiate()
		fruit_instance.position = fruit_position
		#diferir adición de fruta a la escena
		call_deferred("add_child_deferred", fruit_instance)
		#get_tree().current_scene.add_child(fruit_instance)
	else:
		push_warning("No se encontró un punto válido para el spawn de la fruta.")
func add_child_deferred(node: Node) -> void:
	get_tree().current_scene.add_child(node)
