extends RigidBody3D

signal Hit_Successfull

var Damage: int = 0
var Shooter = null

func _on_body_entered(body):
	#if body.is_in_group("Target") && 
	print("Hit_Successful:  body: ", body)
	if body.has_method("Hit_Successful"):
		body.Hit_Successful(Shooter, Damage)
		emit_signal("Hit_Successfull")

	queue_free()

func _on_timer_timeout():
	queue_free()
