#  __         ______     _____     ______     __    __     ______     ______     ______     
# /\ \       /\  __ \   /\  __-.  /\  ___\   /\ "-./  \   /\  __ \   /\___  \   /\  ___\   
# \ \ \____  \ \ \/\ \  \ \ \/\ \ \ \  __\   \ \ \-./\ \  \ \  __ \  \/_/  /__  \ \  __\   
#  \ \_____\  \ \_____\  \ \____-  \ \_____\  \ \_\ \ \_\  \ \_\ \_\   /\_____\  \ \_____\ 
#   \/_____/   \/_____/   \/____/   \/_____/   \/_/  \/_/   \/_/\/_/   \/_____/   \/_____/ 
#
#                            Copyright (C) 2020 by Rowan Games.
#                                Licensed under MIT license.
#

extends Area2D

signal live_found

onready var sprite = $AnimatedSprite
onready var soundPlayer = $AudioStreamPlayer
	
func _ready():
	connect("body_entered", self, "on_body_entered")
	soundPlayer.connect("finished", self, "on_sound_finished")
#
# body - the object the chest is colliding with.
#
func on_body_entered(body):
	if body.get_name() == "Player":
		emit_signal("live_found")
		
		# Puff effect.
		$PuffEffect.set_emitting(true)
		
		# Hide immediately to avoid "late" visual removal.
		sprite.hide()

		# Play ka-ching.		
		soundPlayer.play()
		
func on_sound_finished():
	queue_free()

