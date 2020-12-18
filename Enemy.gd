#  __         ______     _____     ______     __    __     ______     ______     ______     
# /\ \       /\  __ \   /\  __-.  /\  ___\   /\ "-./  \   /\  __ \   /\___  \   /\  ___\   
# \ \ \____  \ \ \/\ \  \ \ \/\ \ \ \  __\   \ \ \-./\ \  \ \  __ \  \/_/  /__  \ \  __\   
#  \ \_____\  \ \_____\  \ \____-  \ \_____\  \ \_\ \ \_\  \ \_\ \_\   /\_____\  \ \_____\ 
#   \/_____/   \/_____/   \/____/   \/_____/   \/_/  \/_/   \/_/\/_/   \/_____/   \/_____/ 
#
#                            Copyright (C) 2020 by Rowan Games.
#                                Licensed under MIT license.
#

extends KinematicBody2D

signal enemy_got_player

var disable_movement = false
var spawn_x
var spawn_y

const ACCEL_X = 65	
const ACCEL_Y = 65
const MAX_DELTA_Y = 1
const MAX_DELTA_X = 1

var ladder = 0
var motion = Vector2(0, 0)

func _ready():
	spawn_x = position.x
	spawn_y = position.y
	
	$Timer1.start()
	$Timer1.connect("timeout", self, "start_spawn")
	
	disable_movement = true
	
func respawn() -> void:		
	disable_movement = true
	
	$AnimatedSprite.animation = "idle"

	position.x = spawn_x
	position.y = spawn_y
	
	$Timer1.start()
	$Timer1.connect("timeout", self, "start_spawn")
	
func start_spawn():
	$Timer1.stop()
	$Timer1.disconnect("timeout", self, "start_spawn")
	
	$SpawnPlayer.play()
	$PuffEffect.set_emitting(true)
	
	$Timer2.start()
	$Timer2.connect("timeout", self, "finish_spawn")

func finish_spawn():
	$Timer2.stop()
	$Timer2.disconnect("timeout", self, "finish_spawn")
	
	disable_movement = false
	
func on_left_ladder_in(body):
	if body == self:
		ladder += 1
func on_left_ladder_out(body):
	if body == self:
		ladder -= 1
func on_right_ladder_in(body):
	if body == self:
		ladder += 1
func on_right_ladder_out(body):
	if body == self:
		ladder -= 1
			
func is_on_ladder() -> bool:
	return ladder > 0

func is_falling() -> bool:
	return !is_on_floor() && !is_on_ladder()
	
func move(vec: Vector2) -> Vector2:
	$AnimatedSprite.animation = "run"
	$AnimatedSprite.flip_v = false
	$AnimatedSprite.flip_h = vec.x < 0
	
	return move_and_slide(
		vec, 
		Vector2(0, 1),
		false,
		1,
		0.785398,
		false
	)
	
func die() -> void:	
	disable_movement = true	

	$AnimatedSprite.animation = "die"

	$DeathPlayer.play()
	$DeathPlayer.connect("finished", self, "die_step1")
	
func die_step1() -> void:
	$DeathPlayer.disconnect("finished", self, "die_step1")
	
	position.x = spawn_x
	position.y = spawn_y
	
	$AnimatedSprite.animation = "idle"
	
	$SpawnPlayer.play()
	$PuffEffect.set_emitting(true)
	
	$Timer2.start()
	$Timer2.connect("timeout", self, "die_step2")

func die_step2() -> void:
	$Timer2.stop()
	$Timer2.disconnect("timeout", self, "die_step2")
	
	disable_movement = false

func _physics_process(delta):    
	if disable_movement:
		return
		
	var player_x = Global.Player.position.x
	var player_y = Global.Player.position.y
	
	motion.x = 0
	motion.y = 0
	
	var delta_x = int(round(abs(player_x - position.x)))
	var delta_y = int(round(abs(player_y - position.y)))
	
	var try_hor_mov = true

	# If on ladder - always try to move up or down, if necessary.	
	if is_on_ladder() && delta_y > MAX_DELTA_Y:
		motion.y = -ACCEL_Y if player_y < position.y else ACCEL_Y
			
		var res = move(motion)				
		
		# If we stuck vertically, try horizontal move (default).
		# If we moved vertically - skip horizontal movement.
		if res.y != 0:
			try_hor_mov = false
					
	if try_hor_mov && delta_x > MAX_DELTA_X:
		# Inore any vertical velocity, if any.
		motion.y = 0
		motion.x = -ACCEL_X if player_x < position.x else ACCEL_X
		
		move(motion)	
				
	if motion.x == 0 && motion.y == 0:
		$AnimatedSprite.animation = "idle"
		$AnimatedSprite.flip_v = false
		$AnimatedSprite.flip_h = false
			
	# HACK!
	# The only way to detect a collision between KinematicBody2D (player) and
	# fire cell (RigidBody2D) is to do it here...
	for i in get_slide_count():
		var node_name = get_slide_collision(i).collider.get_name()
		
		if node_name.find("Fire") != -1:
			die()
			
		if node_name.find("Player") != -1:
			emit_signal("enemy_got_player")
			disable_movement = true
	
	if is_falling():		
		# Actual falling velocity.
		move_and_collide(Vector2(0, 5))
