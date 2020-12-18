#  __         ______     _____     ______     __    __     ______     ______     ______     
# /\ \       /\  __ \   /\  __-.  /\  ___\   /\ "-./  \   /\  __ \   /\___  \   /\  ___\   
# \ \ \____  \ \ \/\ \  \ \ \/\ \ \ \  __\   \ \ \-./\ \  \ \  __ \  \/_/  /__  \ \  __\   
#  \ \_____\  \ \_____\  \ \____-  \ \_____\  \ \_\ \ \_\  \ \_\ \_\   /\_____\  \ \_____\ 
#   \/_____/   \/_____/   \/____/   \/_____/   \/_/  \/_/   \/_/\/_/   \/_____/   \/_____/ 
#
#                            Copyright (C) 2020 by Rowan Games.
#                                Licensed under MIT license.
#

extends TextureRect

func set_score(score) -> void:
	$"Score/Value".text = str(score)

func set_level(lvl) -> void:
	$"Level/Value".text = str(lvl)

const live = preload("res://Live.tscn")
const MAX_LIVES = 5

var hearts = []
	
func set_lives(lives) -> void:
	var sz = hearts.size()
	
	for i in range(MAX_LIVES):
		hearts[i].visible = false
	for i in range(lives):
		hearts[sz - 1 - i].visible = true
	
func _ready():
	var x = 1020
	
	# Initialize live sprites.
	for i in range(MAX_LIVES):
		var heart = live.instance()
		
		heart.visible = false
		heart.position.y = 18
		heart.position.x = x
		
		x += 34
		
		hearts.append(heart)			
		$Lives.add_child(heart)

