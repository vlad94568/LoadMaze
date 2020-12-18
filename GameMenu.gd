extends Node2D
onready var soundPlayer = $AudioStreamPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
#func _process(delta):
#	pass


func _on_Button_pressed():
	soundPlayer.play()
	get_tree().change_scene("res://Main.tscn")
