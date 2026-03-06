extends Area2D

@export var duration := 10.0

func _ready():
	area_entered.connect(_on_area_entered)
	add_to_group("powerups")

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		$AudioStreamPlayer2D.play()
		await $AudioStreamPlayer2D.finished
		area.activate_cross(duration)
		queue_free()
