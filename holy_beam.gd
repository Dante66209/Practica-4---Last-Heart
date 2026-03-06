extends Area2D

@export var speed := 800
var direction = Vector2.RIGHT

func _ready():
	rotation = direction.angle()
	$LifeTimer.timeout.connect(queue_free)
	body_entered.connect(_on_body_entered)

func _process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("mobs"):
		body.queue_free()
