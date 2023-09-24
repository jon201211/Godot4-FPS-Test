extends CharacterBody3D

signal health_changed(health_value)

@onready var camera = $Camera

var peer_id = 0
var peer_name = ""
var shoot_count = 0
var failed_count = 0
var Health = 3
var die = 0

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var CameraRotation = Vector2(0.0,0.0)
var MouseSensitivity = 0.001

var shake_rotation = 0 
var Start_Shake_Rotation = 0


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 9.8 #ProjectSettings.get_setting("physics/3d/default_gravity")

func _enter_tree():
	peer_name = name
	print("_enter_tree  player name : ", peer_name, position)
	set_multiplayer_authority(str(peer_name).to_int())
	peer_id = str(peer_name).to_int()

func _ready():
	print("_ready  player name : ", name, position)
	if not is_multiplayer_authority(): return
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true

func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	
	if die: return

	if event is InputEventMouseMotion:
		#var MouseEvent = event.relative * MouseSensitivity
		#CameraLook(MouseEvent)
		rotate_y(-event.relative.x * .005)
		camera.rotate_x(-event.relative.y * .005)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

# 	if Input.is_action_just_pressed("shoot") \
# 			and anim_player.current_animation != "shoot":
# 		play_shoot_effects.rpc()
# 		if raycast.is_colliding():
# 			var hit_player = raycast.get_collider()
# 			hit_player.receive_damage.rpc_id(hit_player.get_multiplayer_authority())


func CameraLook(Movement: Vector2):
	CameraRotation += Movement
	
	transform.basis = Basis()
	camera.transform.basis = Basis()
	
	rotate_object_local(Vector3(0,1,0),-CameraRotation.x) # first rotate in Y
	camera.rotate_object_local(Vector3(1,0,0), -CameraRotation.y) # then rotate in X
	CameraRotation.y = clamp(CameraRotation.y,-1.5,1.2)

func _physics_process(delta):
	if not is_multiplayer_authority(): return

	if die: return
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta


	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	velocity.x = move_toward(velocity.x, direction.x * SPEED, SPEED)
	velocity.z = move_toward(velocity.z, direction.z * SPEED, SPEED)

	move_and_slide()
	
	

func Die():
	die = 1
	print("die, player name : ", get_multiplayer_authority())


#@rpc("call_local")
#func play_shoot_effects():
#	anim_player.stop()
#	anim_player.play("shoot")
#	muzzle_flash.restart()
#	muzzle_flash.emitting = true
#
#@rpc("any_peer")
#func receive_damage():
#	health -= 1
#	if health <= 0:
#		health = 3
#		position = Vector3.ZERO
#	health_changed.emit(health)
#
#func _on_animation_player_animation_finished(anim_name):
#	if anim_name == "shoot":
#		anim_player.play("idle")

func Hit_Successful(Damage, _Direction: Vector3 = Vector3.ZERO, _Position: Vector3 = Vector3.ZERO):
	Health -= Damage
	health_changed.emit(Health)
	if Health <= 0:
		Die()
