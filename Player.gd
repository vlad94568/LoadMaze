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

signal player_died
signal new_bullet

const ACCEL_X = 100
const ACCEL_Y = 100
const SNAP_DELTA = 7

var motion = Vector2(0, 0)
var ladder = 0
var disable_controls = false
var moving_right = true
var time_before_shot = 0

func _ready():
	Global.Player = self
	time_before_shot = 0

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
	
func die(cbObj, cbMtd) -> void:
	disable_controls = true
	
	# Animation.
	$AnimatedSprite.animation = "death"
	
	# Death sound.
	if !$DeathPlayer.is_connected("finished", cbObj, cbMtd):
		$DeathPlayer.connect("finished", cbObj, cbMtd)
	$DeathPlayer.play()
			
func spawn() -> void:
	disable_controls = true
	
	# Animation.
	$AnimatedSprite.animation = "spawn"
	
	# Spawn sound.	
	$SpawnPlayer.play()
	$SpawnTimer.start()
	$SpawnTimer.connect("timeout", self, "finish_spawn")
	
func finish_spawn() -> void: 
	$SpawnTimer.disconnect("timeout", self, "finish_spawn")
	disable_controls = false	
	
func kill_brick(node_name):
	print("node_name")
	if node_name == "BrickWall":
		pass
	
func _physics_process(delta):
	time_before_shot += delta
			
	if disable_controls:
		return
		
	motion.y = 0
	motion.x = 0
	
	var anim
	var flip_h
	
	var bulletInstance = null
	var vec = Vector2 (100, 100)
	
	var int_y = int(round(position.y))
	var below = int_y > int_y / 32 * 32
	var snap_delta = min(int_y % 32, int_y / 32 * 32 + 32 - int_y)
	
	if Input.is_action_pressed("ui_right"):
		motion.x = ACCEL_X
		flip_h = false
		anim = "right"
		moving_right = true			
	elif Input.is_action_pressed("ui_left"):
		motion.x = -ACCEL_X
		flip_h = true
		anim = "right"
		moving_right = false			
	elif Input.is_action_pressed("ui_up"):
		if is_on_ladder():
			motion.y = -ACCEL_Y

		flip_h = false
		anim = "vert"			
	elif Input.is_action_pressed("ui_down"):
		if is_on_ladder():
			motion.y = ACCEL_Y
			
		flip_h = false
		anim = "vert"	
	else:
		flip_h = !moving_right
		anim = "idle"
						
	if Input.is_action_pressed("ui_select") && time_before_shot > 0.25:
		anim = "shoot"
		flip_h = !moving_right
	
		# Add bullet node.
		emit_signal("new_bullet", position, moving_right)
		
		time_before_shot = 0
		
	$AnimatedSprite.animation = anim
	$AnimatedSprite.flip_v = false
	$AnimatedSprite.flip_h = flip_h
	
	# Snap vertical position if is on ladder.
	if anim == "right" && is_on_ladder() && snap_delta <= SNAP_DELTA && snap_delta > 0:
		position.y += snap_delta - 1
		
	# Process dust effect.
	if anim == "right" && !is_on_ladder():
		$DustEffect.position.x = 18 if flip_h else 6
		$DustEffect.process_material.gravity.x = 40 if flip_h else -40
		$DustEffect.visible = true
		$DustEffect.emitting = true
	else:
		$DustEffect.emitting = false	
		$DustEffect.visible = false	
	
	if $AnimatedSprite.animation == "shoot":
		if !$ShootPlayer.playing:
			$ShootPlayer.play()
	elif $AnimatedSprite.animation != "idle":
		if !$RunPlayer.playing:
			$RunPlayer.play()
	else:
		$RunPlayer.stop()
				
	var is_idle = motion.y == 0 && motion.x == 0
	
	if !is_idle:
		move_and_slide(
			motion, 
			Vector2(0, 1),
			false,
			1,
			0.785398,
			false
		)
	
		# HACK!
		# The only way to detect a collision between KinematicBody2D (player) and
		# fire cell (RigidBody2D) is to do it here...
		for i in get_slide_count():
			var node_name = get_slide_collision(i).collider.get_name()
			
			if node_name.find("Fire") != -1 || node_name.find("Enemy") != -1:
				emit_signal("player_died")
	
		if is_falling():		
			# Actual falling velocity.
			move_and_collide(Vector2(0, 5))
