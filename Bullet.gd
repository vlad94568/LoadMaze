#  __         _____     _____     ______     __    __     ______     ______     ______     
# /\ \       /\  __ \   /\  __-.  /\  ___\   /\ "-./  \   /\  __ \   /\___  \   /\  ___\   
# \ \ \____  \ \ \/\ \  \ \ \/\ \ \ \  __\   \ \ \-./\ \  \ \  __ \  \/_/  /__  \ \  __\   
#  \ \_____\  \ \_____\  \ \____-  \ \_____\  \ \_\ \ \_\  \ \_\ \_\   /\_____\  \ \_____\ 
#   \/_____/   \/_____/   \/____/   \/_____/   \/_/  \/_/   \/_/\/_/   \/_____/   \/_____/ 
#
#                            Copyright (C) 2020 by Rowan Games.
#                                Licensed under MIT license.
#

extends KinematicBody2D

const BULLET_ACCEL = 350

var motion = Vector2(0, 0)
var disable_movement = false

func init(right: bool) -> void:
	motion.x = BULLET_ACCEL if right else -BULLET_ACCEL

	$AnimatedSprite.flip_h = !right

	$ExplosionTimer.connect("timeout", self, "finish_effect")
	
func _physics_process(delta): 
	if !disable_movement:
		move_and_slide(
			motion, 
			Vector2(0, 1),
			false,
			1,
			0.785398,
			false
		)
		
		for i in get_slide_count():
			var collider = get_slide_collision(i).collider
			var node_name = collider.get_name()
		
			if collider:
				disable_movement = true
				
				var is_enemy = node_name.find("Enemy") != -1
				var is_brick_wall = node_name.find("BrickWall") != -1
				
				if is_enemy:
					$EnemyHitPlayer.play()
				elif is_brick_wall:
					# Start explosion effect.
					$ExplosionEffect.set_emitting(true)
	
					# Play explosion audio SFX.	
					$ExplosionPlayer.play()					
				else:
					# Play explosion audio SFX.	
					$ExplosionPlayer.play()
			
				# Turn of collision shape.
				$CollisionShape2D.disabled = true
					
				# Hide the bullet itself with a delay.
				$AnimatedSprite.hide()
				
				$ExplosionTimer.start()
				
				if is_brick_wall:
					# Small delay to visualy separate bullet impact and brick destruction.
					$DelayTimer.connect("timeout", self, "on_delay_finish", [collider])
					$DelayTimer.start()
					
					# Turn off collision share right away.
					collider.get_node("CollisionShape2D").disabled = true

func on_delay_finish(brickwall) -> void:
	var sprite = brickwall.get_node("AnimatedSprite")
	
	# Stop any curren animation.
	sprite.stop()
	
	# Hide the brickwall when animation is finished.
	sprite.connect("animation_finished", self, "on_breakup_finish", [sprite])

	# Play breakup animation.	
	sprite.play("breakup")
	
	brickwall.respawn()

func on_breakup_finish(sprite) -> void:
	sprite.hide()

func finish_effect():
	queue_free()
