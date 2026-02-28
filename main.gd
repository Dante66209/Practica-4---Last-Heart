extends Node

@export var mob_scene: PackedScene
@onready var powerup_timer = $PowerUpTimer
@onready var player = $Player
@export var shield_scene: PackedScene
@export var spawn_interval: float = 10.0  # cada cuánto intentar spawnear
@export var powerup_scenes: Array[PackedScene]
@onready var pause_overlay = $HUD/PauseOverlay
@onready var pause_sound = $PauseSound

var score = 0

func _on_score_timer_timeout():
	score += 1
	$HUD.update_score(score)

func _on_start_timer_timeout():
	$MobTimer.start()
	$ScoreTimer.start()
	
func _on_mob_timer_timeout():
	# Create a new instance of the Mob scene.
	var mob = mob_scene.instantiate()

	# Choose a random location on Path2D.
	var mob_spawn_location = $MobPath/MobSpawnLocation
	mob_spawn_location.progress_ratio = randf()

	# Set the mob's position to the random location.
	mob.position = mob_spawn_location.position

	# Set the mob's direction perpendicular to the path direction.
	var direction = mob_spawn_location.rotation + PI / 2

	# Add some randomness to the direction.
	direction += randf_range(-PI / 4, PI / 4)
	mob.rotation = direction

	# Choose the velocity for the mob.
	var velocity = Vector2(randf_range(150.0, 250.0), 0.0)
	mob.linear_velocity = velocity.rotated(direction)

	# Spawn the mob by adding it to the Main scene.
	add_child(mob)
	

func game_over() -> void:
	$ScoreTimer.stop()
	$MobTimer.stop()
	$HUD.show_game_over()
	$Music.stop()
	$DeathSound.play()
	$PowerUpTimer.stop()
	clear_powerups() 


func clear_powerups() -> void:
	for p in get_tree().get_nodes_in_group("powerups"):
		p.queue_free()


func new_game():
	score = 0
	get_tree().call_group("mobs", "queue_free") 
	$HUD.update_score(score)
	$HUD.show_message("Get Ready")
	$HUD.update_lives($Player.lives)
	$Player.start($StartPosition.position)
	$StartTimer.start()
	$Music.play()
	$PowerUpTimer.start() 
	$Player.reset_lives()


func _ready():
	pass
	randomize()
	$PowerUpTimer.timeout.connect(spawn_powerup)
	$LifetimeTimer.timeout.connect(spawn_powerup)
	$Player.hit.connect(_on_player_hit)
	print("Conexiones de hit:", $Player.get_signal_connection_list("hit"))
	
	# Crear acción "pause" si no existe
	if not InputMap.has_action("pause"):
		InputMap.add_action("pause")
		var ev := InputEventKey.new()
		ev.keycode = Key.KEY_Q   # <- CORRECTO EN GODOT 4
		InputMap.action_add_event("pause", ev)

	# Este nodo debe seguir procesando aunque el juego esté pausado
	process_mode = Node.PROCESS_MODE_ALWAYS

	# El overlay también debe seguir activo
	if pause_overlay:
		pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
		pause_overlay.visible = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()


func toggle_pause() -> void:
	if get_tree().paused:
		#$UnpauseSound.play()
		pass
	else:
		$PauseSound.play()
	
	get_tree().paused = !get_tree().paused
	
	if pause_overlay:
		pause_overlay.visible = get_tree().paused

func _on_player_hit(lives_left: int) -> void:
	$HUD.update_lives(lives_left)

	if lives_left > 0:
		$RespawnTimer.start()
		$RespawnSound.play()
	else:
		game_over()

func _on_RespawnTimer_timeout():
	# respawnear donde estaba el jugador (evita centro)
	# opcional: un pequeño desplazamiento para evitar overlap con el mob
	var respawn_pos = $Player.position + Vector2(0, -8)  # sube 8px si quieres evitar solapamiento
	# invulnerabilidad de 2.5 segundos (ajusta)
	$Player.start(respawn_pos, 2.5)



func spawn_powerup() -> void:
	if powerup_scenes.is_empty():
		print("⚠ powerup_scenes vacío")
		return

	var idx := randi() % powerup_scenes.size()
	var pu := powerup_scenes[idx].instantiate()

	const GAME_WIDTH := 480
	const GAME_HEIGHT := 720
	var margin := 32

	pu.global_position = Vector2(
		randf_range(margin, GAME_WIDTH - margin),
		randf_range(margin, GAME_HEIGHT - margin)
	)

	add_child(pu)
