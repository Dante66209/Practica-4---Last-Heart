extends CanvasLayer

signal start_game

@onready var lives_container := $LivesContainer


func update_lives(lives: int) -> void:
	for i in range(lives_container.get_child_count()):
		lives_container.get_child(i).visible = i < lives


func show_message(text: String) -> void:
	# ocultar logo si estaba visible
	if $Logo:
		$Logo.visible = false

	$Message.text = text
	$Message.show()
	$MessageTimer.start()


func show_game_over() -> void:
	show_message("Game Over")
	await $MessageTimer.timeout
	$Message.hide()
	$Logo.visible = true
	# esperamos un segundo (o ajusta)
	await get_tree().create_timer(1.0).timeout
	$StartButton.show()
	

func update_score(score):
	$ScoreLabel.text = str(score)

func _on_start_button_pressed():
	$StartButton.hide()
	start_game.emit()

func _on_message_timer_timeout():
	$Message.hide()
	
