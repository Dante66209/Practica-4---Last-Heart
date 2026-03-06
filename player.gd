extends Area2D

@export var speed = 400 # How fast the player will move (pixels/sec).
@export var base_speed := 400
var speed_boost_active := false
var shield_active: bool = false
@onready var shield_timer: Timer = null
@onready var shield_sprite = $ShieldSprite2D
@export var max_lives := 3
var lives := max_lives
var screen_size # Size of the game window.

@onready var powerup_music = $PowerupMusic
@export var holy_beam_scene: PackedScene

var cross_active := false
var shoot_cooldown := 0.4
var shoot_timer := 0.0

var look_direction = Vector2.RIGHT

signal hit(lives_left)

# invulnerabilidad y parpadeo
var invulnerable: bool = false
@onready var invul_timer: Timer = null
@onready var blink_timer: Timer = null

# referencia al sprite principal (para parpadear). Usa el tuyo (AnimatedSprite2D o Sprite2D)
@onready var main_sprite := $AnimatedSprite2D


func _ready():
	
	screen_size = get_viewport_rect().size
	speed = base_speed
	add_to_group("player")
	hide()
	
	if not has_node("ShieldTimer"):
		shield_timer = Timer.new()
		shield_timer.one_shot = true
		add_child(shield_timer)
		shield_timer.timeout.connect(Callable(self, "_on_shield_timeout"))
	else:
		shield_timer = $ShieldTimer
	# Asegúrate de agregar al grupo player
	add_to_group("player")
	
	# crear timers solo si no existen en la escena (evita duplicados)
	if not has_node("InvulTimer"):
		invul_timer = Timer.new()
		invul_timer.name = "InvulTimer"
		invul_timer.one_shot = true
		add_child(invul_timer)
		invul_timer.timeout.connect(Callable(self, "_on_invul_timeout"))
	else:
		invul_timer = $InvulTimer

	if not has_node("BlinkTimer"):
		blink_timer = Timer.new()
		blink_timer.name = "BlinkTimer"
		blink_timer.one_shot = false
		blink_timer.wait_time = 0.15  # parpadeo cada 0.15s (ajusta si quieres)
		add_child(blink_timer)
		blink_timer.timeout.connect(Callable(self, "_on_blink_timeout"))
	else:
		blink_timer = $BlinkTimer

func _process(delta):
	var velocity = Vector2.ZERO # The player's movement vector.
	if Input.is_action_pressed("move_right"):
		velocity.x += 1
	if Input.is_action_pressed("move_left"):
		velocity.x -= 1
	if Input.is_action_pressed("move_down"):
		velocity.y += 1
	if Input.is_action_pressed("move_up"):
		velocity.y -= 1
	if cross_active:
		shoot_timer -= delta
		if Input.is_action_pressed("shoot") and shoot_timer <= 0:
			shoot_beam()
			shoot_timer = shoot_cooldown


	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		$AnimatedSprite2D.play()

		look_direction = velocity.normalized()

	else:
		$AnimatedSprite2D.stop()
		
	if velocity.x != 0:
		$AnimatedSprite2D.animation = "walk"
		$AnimatedSprite2D.flip_v = false
	# See the note below about the following boolean assignment.
		$AnimatedSprite2D.flip_h = velocity.x < 0
	elif velocity.y != 0:
		$AnimatedSprite2D.animation = "up"
		$AnimatedSprite2D.flip_v = velocity.y > 0
	
	position += velocity * delta
	position = position.clamp(Vector2.ZERO, screen_size)
	
	
func activate_speed_boost(extra_speed: int, duration: float) -> void:
	if speed_boost_active:
		return  # evita bugs si agarras dos seguidos

	speed_boost_active = true
	speed = base_speed + extra_speed

	# feedback visual (opcional pero recomendado)
	$AnimatedSprite2D.modulate = Color(0.6, 1, 0.6)

	await get_tree().create_timer(duration).timeout

	speed = base_speed
	speed_boost_active = false
	$AnimatedSprite2D.modulate = Color(1, 1, 1)

func _on_body_entered(_body):
	# Ignorar si invulnerable (además del shield)
	if invulnerable:
		return

	if shield_active:
		shield_timer.stop()
		_on_shield_timeout()
		return
		
	# Si el objeto que colisionó es un mob (opcional: comprobar grupo o nombre)
	# y el shield está activo → consumir el escudo y no morir
	if shield_active:
		# consumir escudo inmediatamente
		shield_timer.stop()
		_on_shield_timeout()
		# opcional: feedback (partículas/sfx)
		return
		

	lives -= 1
	hit.emit(lives)
	#si no hay escudo, morir como antes
	hide()
	$CollisionShape2D.set_deferred("disabled", true)

	# Asegúrate de resetear estado del shield (por si quedó activo)
	shield_active = false
	if shield_sprite:
		shield_sprite.visible = false

# start(pos, invul_time) - invul_time en segundos; 0 = sin invulnerabilidad
func start(pos: Vector2, invul_time: float = 0.0) -> void:
	position = pos
	show()
	$CollisionShape2D.disabled = false

	# Reset estados existentes
	speed = base_speed
	speed_boost_active = false
	shield_active = false
	if shield_sprite:
		shield_sprite.visible = false

	# Invulnerabilidad opcional con parpadeo
	if invul_time > 0.0:
		invulnerable = true
		# asegurar visible al iniciar el parpadeo
		if main_sprite:
			main_sprite.visible = true
		# arrancar timers
		invul_timer.stop()
		invul_timer.wait_time = invul_time
		invul_timer.start()

		blink_timer.stop()
		blink_timer.start()
	else:
		invulnerable = false
		if main_sprite:
			main_sprite.visible = true
		blink_timer.stop()

func _on_blink_timeout() -> void:
	# alterna la visibilidad del sprite para parpadear
	if main_sprite:
		main_sprite.visible = not main_sprite.visible

func _on_invul_timeout() -> void:
	# fin de invulnerabilidad
	invulnerable = false
	blink_timer.stop()
	# asegurar que sprite quede visible
	if main_sprite:
		main_sprite.visible = true

func reset_lives():
	lives = max_lives
	hit.emit(lives)
	
func activate_shield(time: float) -> void:
	shield_active = true

	if shield_sprite:
		shield_sprite.visible = true
		# Blanco con un poco de transparencia
		shield_sprite.modulate = Color(1, 1, 1, 0.8)

	if shield_timer:
		shield_timer.stop()
		shield_timer.wait_time = time
		shield_timer.start()
	else:
		await get_tree().create_timer(time).timeout
		_on_shield_timeout()

func _on_shield_timeout() -> void:
	shield_active = false
	if shield_sprite:
		shield_sprite.visible = false


func activate_cross(time: float):
	cross_active = true
	powerup_music.stop()
	powerup_music.play()
	await get_tree().create_timer(time).timeout
	cross_active = false
	powerup_music.stop()

func shoot_beam():
	if holy_beam_scene == null:
		print("⚠ HolyBeam no asignado")
		return
	var beam = holy_beam_scene.instantiate()
	beam.global_position = global_position
	beam.direction = look_direction
	get_parent().add_child(beam)
