#  __         ______     _____     ______     __    __     ______     ______     ______     
# /\ \       /\  __ \   /\  __-.  /\  ___\   /\ "-./  \   /\  __ \   /\___  \   /\  ___\   
# \ \ \____  \ \ \/\ \  \ \ \/\ \ \ \  __\   \ \ \-./\ \  \ \  __ \  \/_/  /__  \ \  __\   
#  \ \_____\  \ \_____\  \ \____-  \ \_____\  \ \_\ \ \_\  \ \_\ \_\   /\_____\  \ \_____\ 
#   \/_____/   \/_____/   \/____/   \/_____/   \/_/  \/_/   \/_/\/_/   \/_____/   \/_____/ 
#
#                            Copyright (C) 2020 by Rowan Games.
#                                Licensed under MIT license.
#

extends Node2D

signal chest_found

const MAX_LIVES = 5
const INIT_SCORE = 0
const INIT_LEVEL = 2
const HUD_HEIGHT = 64

# Terrain blocks
const solidBlockBottom = preload("res://terrain/SolidBlockBottom.tscn")
const solidBlockCenter = preload("res://terrain/SolidBlockCenter.tscn")
const solidBlockTop = preload("res://terrain/SolidBlockTop.tscn")
const solidBlockTop2 = preload("res://terrain/SolidBlockTop2.tscn")
const brickWall = preload("res://terrain/BrickWall.tscn")
const brickWallTop = preload("res://terrain/BrickWallTop.tscn")
const chest = preload("res://terrain/Chest.tscn")
const ladderLeft = preload("res://terrain/LadderLeft.tscn")
const ladderRight = preload("res://terrain/LadderRight.tscn")
const fire = preload("res://terrain/Fire.tscn")
const flor = preload("res://terrain/Floor.tscn")
const bulb = preload("res://terrain/Bulb.tscn")
const gateLeft = preload("res://terrain/GateLeft.tscn")
const gateRight = preload("res://terrain/GateRight.tscn")
const liveSmall = preload("res://terrain/LiveSmall.tscn")
const bullet = preload("res://Bullet.tscn")
const enemy = preload("res://Enemy.tscn")
const player = preload("res://Player.tscn")

# HUD instance.
var hud

# Player, enemy instance.
var gamer
var enemy1 
var enemy2

var curLvl = INIT_LEVEL
var curScore = INIT_SCORE
var curLives = MAX_LIVES

var player_init_x
var player_init_y

func _ready():
	# Init randomzier.
	randomize()
	
	$LevelTitle.visible = false
	
	# Start the game.
	load_map_and_render()
	
func on_new_bullet(pos: Vector2, move_right: bool) -> void:
	var bul = bullet.instance()
	
	bul.init(move_right)
	
	bul.position.x = pos.x + (25 if move_right else -25)
	bul.position.y = pos.y + 10
		
	$Map.add_child(bul)
	
func abort_game(errMsg: String) -> void:
	# TODO: temp implementation
	print_debug(errMsg)
	print_stack()
	
func score_plus_one() -> void:
	curScore += 1
	
	# Update HUD.
	hud.set_score(curScore)
	
func lives_plus_one() -> void:
	curLives = min(curLives + 1, MAX_LIVES)
	
	# Update HUD.
	hud.set_lives(curLives)
	
func turn_light_on() -> void:
	$Darken.visible = false
	gamer.get_node("Light2D").visible = false
	
func player_died() -> void:
	curLives -= 1
	
	if curLives == 0:
		# TODO
		abort_game("Game over!")
		
	# Update HUD.
	hud.set_lives(curLives)		
	
	# Animation + sound.
	gamer.die(self, "respawn_player")
	
func clear_map() -> void:
	for child in $Map.get_children():
		child.queue_free()

func respawn_player() -> void:
	# Set the current level.
	$LevelTitle/Level.text = str(curLvl)
	
	# Show level title screen.
	$Map.visible = false
	$LevelTitle.visible = true
	
	$LevelTitle/LevelPlayer.play()
	$LevelTitle/Timer.start()
	$LevelTitle/Timer.connect("timeout", self, "finish_respawn")
	
func finish_respawn() -> void:
	$Map.visible = true
	$LevelTitle.visible = false	
	$LevelTitle/Timer.disconnect("timeout", self, "finish_respawn")
	$LevelTitle/LevelPlayer.stop()
	
	gamer.position.x = player_init_x
	gamer.position.y = player_init_y
#	
	gamer.spawn()
	enemy1.respawn()
	enemy2.respawn()
		
# Read the map file and renders new map on the current scene.
func load_map_and_render() -> void:
	# Read the map file.
	var mapFileName = 'res://maps/' + str(curLvl) + '.map'
	var file = File.new()
	file.open(mapFileName, File.READ)
	var text = file.get_as_text()
	file.close()

	var openCurlyIdx = text.find('{')
	var closeCurlyIdx = text.find_last('}')
	
	if (openCurlyIdx == -1 || closeCurlyIdx == -1):
		abort_game('Malformed map file: ' + mapFileName)
		
	var map = text.substr(openCurlyIdx + 2, closeCurlyIdx - openCurlyIdx - 2)
	
	var chIdx = 0
	
	hud = preload("res://HUD.tscn").instance()

	# Add HUD first.
	$Map.add_child(hud)
	
	# Setup HUD.
	hud.set_level(curLvl)
	hud.set_score(curScore)
	hud.set_lives(curLives)
	
	# Player, enemy instances.
	gamer = player.instance()
	enemy1 = enemy.instance()
	enemy2 = enemy.instance()
	
	gamer.connect("new_bullet", self, "on_new_bullet")
	
	var found_bulb = false
	
	# Drawing the scene.
	for row in range(16):
		for col in range(50):
			var ch = map[chIdx]
			chIdx += 1
			
			var vec = Vector2(col * 24, HUD_HEIGHT + row * 32)
			var block = null
			
			if ch == '#':
				block = solidBlockBottom.instance()
			elif ch == '1' || ch == '2' || ch == '3' || ch == '4':
				block = fire.instance()
			elif ch == '[':		
				block = ladderLeft.instance()
				block.connect("body_entered", gamer, "on_left_ladder_in")
				block.connect("body_exited", gamer, "on_left_ladder_out")
				block.connect("body_entered", enemy1, "on_left_ladder_in")
				block.connect("body_exited", enemy1, "on_left_ladder_out")
				block.connect("body_entered", enemy2, "on_left_ladder_in")
				block.connect("body_exited", enemy2, "on_left_ladder_out")
			elif ch == ']':		
				block = ladderRight.instance()
				block.connect("body_entered", gamer, "on_right_ladder_in")
				block.connect("body_exited", 	gamer, "on_right_ladder_out")
				block.connect("body_entered", enemy1, "on_left_ladder_in")
				block.connect("body_exited", enemy1, "on_left_ladder_out")
				block.connect("body_entered", enemy2, "on_left_ladder_in")
				block.connect("body_exited", enemy2, "on_left_ladder_out")
			elif ch == 'C':		
				block = solidBlockCenter.instance()
			elif ch == 'c':		
				block = solidBlockTop.instance()
			elif ch == '<':		
				block = gateLeft.instance()
			elif ch == '>':		
				block = gateRight.instance()
			elif ch == '^':		
				block = flor.instance()
			elif ch == 'b':		
				block = bulb.instance()
				block.connect("bulb_found", self, "turn_light_on")
				found_bulb = true
			elif ch == 'p':		
				block = gamer
				player_init_x = vec.x
				player_init_y = vec.y
				block.connect("player_died", self, "player_died")
			elif ch == '$':		
				block = chest.instance()
				block.connect("chest_found", self, "score_plus_one")
			elif ch == 'H':		
				block = liveSmall.instance()
				block.connect("live_found", self, "lives_plus_one")
			elif ch == 'x':		
				block = brickWallTop.instance()
			elif ch == '~':		
				block = solidBlockTop2.instance()
			elif ch == 'E':		
				block = enemy2
				block.connect("enemy_got_player", self, "player_died")
			elif ch == 'e':		
				block = enemy1
				block.connect("enemy_got_player", self, "player_died")
			elif ch == '%':		
				block = brickWall.instance()
				
			if block != null:	
				block.position = vec
				$Map.add_child(block)
			
		chIdx += 1
		
	if found_bulb:
		$Darken.visible = true
		$Darken/DarkenBackground.visible = true
		gamer.get_node("Light2D").visible = true
	else:
		$Darken.visible = false
		$Darken/DarkenBackground.visible = false
		gamer.get_node("Light2D").visible = false
		

	$Map.visible = true
	
	gamer.spawn()				