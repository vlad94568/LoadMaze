#  __         ______     _____     ______     __    __     ______     ______     ______     
# /\ \       /\  __ \   /\  __-.  /\  ___\   /\ "-./  \   /\  __ \   /\___  \   /\  ___\   
# \ \ \____  \ \ \/\ \  \ \ \/\ \ \ \  __\   \ \ \-./\ \  \ \  __ \  \/_/  /__  \ \  __\   
#  \ \_____\  \ \_____\  \ \____-  \ \_____\  \ \_\ \ \_\  \ \_\ \_\   /\_____\  \ \_____\ 
#   \/_____/   \/_____/   \/____/   \/_____/   \/_/  \/_/   \/_/\/_/   \/_____/   \/_____/ 
#
#                            Copyright (C) 2020 by Rowan Games.
#                                Licensed under MIT license.
#

extends StaticBody2D

onready var timer = $RespawnTimer
onready var sprite = $AnimatedSprite
onready var collision = $CollisionShape2D
onready var audio = $RespawnPlayer

func _ready():	
	timer.connect("timeout", self, "on_respawn_timer")

func respawn() -> void:	
	timer.start()
	
func on_respawn_timer() -> void:
	audio.play()
	sprite.show()
	sprite.connect("animation_finished", self, "on_respawn_finished")
	sprite.play("respawn")
	
func on_respawn_finished() -> void:
	sprite.disconnect("animation_finished", self, "on_respawn_finished")
	
	collision.disabled = false
	sprite.play("idle")