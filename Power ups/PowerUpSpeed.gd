extends Area2D

@export var speed_bonus := 200
@export var duration := 3.0

func _ready():
	area_entered.connect(_on_area_entered)
	add_to_group("powerups")

func _on_area_entered(area):
	if area.is_in_group("player"):
		$AudioStreamPlayer2D.play()
		await $AudioStreamPlayer2D.finished
		area.activate_speed_boost(speed_bonus, duration)
		queue_free()
