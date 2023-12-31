extends Node3D

signal Weapon_Changed
signal Update_Ammo
signal Update_WeaponStack
signal Hit_Successfull
signal Add_Signal_To_HUD

signal Connect_Weapon_To_HUD

@export var Animation_Player: AnimationPlayer
@onready var Bullet_Point = get_node("%BulletPoint")
@onready var Bullet_RayCast = get_node("BulletRayCast3D")

@onready var Debug_Bullet = preload("res://Weapons/Scenes/hit_debug.tscn")

var Melee_Shake:= Vector3(0,0,2.5)
var Melee_Shake_Magnetude:= Vector4(1,1,1,1)

#var Secondary_Mode = false

var Current_Weapon = null

var WeaponStack = [] #An Array of weapons currently in possesion by the player

#var WeaponIndicator = 0
var Next_Weapon: String

#WEAPON TYPE ENUMERATOR TO HELP WITH CODE READABILITY
enum {NULL,HITSCAN, PROJECTILE}

var Collision_Exclusion: Array

#The List of All Available weapons in the game
var Weapons_List = {
}

#An Array of weapon resources to make dictionary creation easier
@export var _weapon_resources: Array[Weapon_Resource]

@export var Start_Weapons: Array[String]

func _ready():
	Animation_Player.animation_finished.connect(_on_animation_finished)
	Initialize(Start_Weapons) #current starts on the first weapon in the stack

func _unhandled_input(event):
	if not is_multiplayer_authority(): return

	#player die 
	if get_parent().get_parent().Health == 0: return 

	if event.is_action_pressed("WeaponUp"):
		var GetRef = WeaponStack.find(Current_Weapon.Weapon_Name)
		GetRef = min(GetRef+1,WeaponStack.size()-1)
		
		exit(WeaponStack[GetRef])

	if event.is_action_pressed("WeaponDown"):
		var GetRef = WeaponStack.find(Current_Weapon.Weapon_Name)
		GetRef = max(GetRef-1,0)

		exit(WeaponStack[GetRef])
		
	if event.is_action_pressed("Secondary_Fire"):
		secondary()
		
	if event.is_action_released("Secondary_Fire"):
		reset_secondary()
		
	if event.is_action_pressed("Shoot"):
		#shoot()
		shoot.rpc()
		
	if event.is_action_released("Shoot"):
		Current_Weapon.Spray_Count_Update()
		
	if event.is_action_pressed("Reload"):
		#reload()
		reload.rpc()

	if event.is_action_pressed("Drop_Weapon"):
		drop(Current_Weapon.Weapon_Name)
		
	if event.is_action_pressed("Melee"):
		melee()
		
func Initialize(_Start_Weapons: Array):
	for Weapons in _weapon_resources:
		Weapons.ready()
		Weapons_List[Weapons.Weapon_Name] = Weapons
		Connect_Weapon_To_HUD.emit(Weapons)
		
	for child in _Start_Weapons:
		WeaponStack.push_back(child)

	Current_Weapon = Weapons_List[WeaponStack[0]]

	Update_WeaponStack.emit(WeaponStack)
	enter()

func enter():
	Animation_Player.queue(Current_Weapon.Pick_Up_Anim)
	Current_Weapon.Spray_Count_Update()
	Weapon_Changed.emit(Current_Weapon.Weapon_Name)
	Update_Ammo.emit([Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])

func exit(_next_weapon: String):
	if _next_weapon != Current_Weapon.Weapon_Name:
		if Animation_Player.get_current_animation() != Current_Weapon.Change_Anim:
			if Current_Weapon.Secondary_Mode == true:
				reset_secondary()
			Animation_Player.queue(Current_Weapon.Change_Anim)
			Next_Weapon = _next_weapon

func Change_Weapon(weapon_name: String):
	Current_Weapon = Weapons_List[weapon_name]
	Next_Weapon = ""
	enter()

@rpc("call_local")
func shoot():
	if Current_Weapon.Current_Ammo != 0:
		if not Animation_Player.is_playing():
			Animation_Player.play(Current_Weapon.Shoot_Anim)
			var audio_node = Animation_Player.get_parent().get_node("{}/audio".format([Current_Weapon.Weapon_Name], "{}"))
			audio_node.get_node("shoot").play();
			Current_Weapon.Current_Ammo -= 1
			Update_Ammo.emit([Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])
			var Camera_Collission =  GetCameraCollision(Current_Weapon.Fire_Range)
			print("Camera_Collission: ", Camera_Collission,  "type: ", Current_Weapon.Type)
			match Current_Weapon.Type:
				NULL:
					pass
				HITSCAN:
					HitScanCollision(Camera_Collission)
				PROJECTILE:
					LaunchProjectile(Camera_Collission[1])
	else:
		reload()

@rpc("call_local")
func reload():
	if Current_Weapon.Current_Ammo == Current_Weapon.Magazine:
		return
	elif not Animation_Player.is_playing():
		
		if Current_Weapon.Reserve_Ammo != 0:		
			if Current_Weapon.Secondary_Mode == true:
				reset_secondary()
				
			Animation_Player.queue(Current_Weapon.Reload_Anim)
			var audio_node = Animation_Player.get_parent().get_node("{}/audio".format([Current_Weapon.Weapon_Name], "{}"))
			audio_node.get_node("reload").play();

		else:
			Animation_Player.queue(Current_Weapon.Out_Of_Ammo_Anim)
			var audio_node = Animation_Player.get_parent().get_node("{}/audio".format([Current_Weapon.Weapon_Name], "{}"))
			audio_node.get_node("out").play();

func Calculate_Reload():
	var Reload_Amount = min(Current_Weapon.Magazine-Current_Weapon.Current_Ammo,Current_Weapon.Magazine,Current_Weapon.Reserve_Ammo)

	Current_Weapon.Current_Ammo = Current_Weapon.Current_Ammo+Reload_Amount
	Current_Weapon.Reserve_Ammo = Current_Weapon.Reserve_Ammo-Reload_Amount
	Current_Weapon.Spray_Count_Update()
	
	Update_Ammo.emit([Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])


func melee():
	if Current_Weapon.Secondary_Mode:
		reset_secondary()
		
	var Current_Anim = Animation_Player.get_current_animation()
	
	if Current_Anim == Current_Weapon.Shoot_Anim:
		return
		
	if Current_Anim != Current_Weapon.Melee_Anim:
		Animation_Player.play(Current_Weapon.Melee_Anim)
		var Camera_Collission =  GetCameraCollision(2)
		if Camera_Collission[0]:
			var Direction = (Camera_Collission[1] - owner.global_transform.origin).normalized()
			HitScanDamage(Camera_Collission[0],Direction,Camera_Collission[1], Current_Weapon.Melee_Damage)
			
func drop(_name: String):
	if Weapons_List[_name].Can_Be_Dropped and WeaponStack.size() != 1:
		var Weapon_Ref = WeaponStack.find(_name,0)
		if Weapon_Ref != -1:
			WeaponStack.pop_at(Weapon_Ref)
			Update_WeaponStack.emit(WeaponStack)

			if Weapons_List[_name].Weapon_Drop:
				var Weapon_Dropped = Weapons_List[_name].Weapon_Drop.instantiate()
				Weapon_Dropped._current_ammo = Weapons_List[_name].Current_Ammo
				Weapon_Dropped._reserve_ammo = Weapons_List[_name].Reserve_Ammo

				Weapon_Dropped.set_global_transform(Bullet_Point.get_global_transform())
				get_tree().get_root().add_child(Weapon_Dropped)

				Animation_Player.play(Current_Weapon.Drop_Anim)
				var audio_node = Animation_Player.get_parent().get_node("{}/audio".format([Current_Weapon.Weapon_Name], "{}"))
				audio_node.get_node("out").play();
				Weapon_Ref  = max(Weapon_Ref-1,0)
				exit(WeaponStack[Weapon_Ref])
	else:
		return
		
func _on_animation_finished(anim_name):
	if anim_name == Current_Weapon.Shoot_Anim:
		if Current_Weapon.AutoFire == true:
				if Input.is_action_pressed("Shoot"):
					shoot()

	
	if anim_name == Current_Weapon.Change_Anim:
		Change_Weapon(Next_Weapon)
	
	if anim_name == Current_Weapon.Reload_Anim:
		Calculate_Reload()
	
	CheckSecondaryMode()
	
func CheckSecondaryMode():	
	if Current_Weapon.Secondary_Mode == true:
		if !Input.is_action_pressed("Secondary_Fire"):
			reset_secondary()	


func GetCameraCollision(_fire_range: int)->Array:
	var space_state = get_world_3d().direct_space_state

	var Ray_Origin = Bullet_RayCast.global_transform.origin
	var dir = -Bullet_RayCast.global_transform.basis.z

	var Spray = Current_Weapon.Get_Spray()
	
	if Current_Weapon.Secondary_Mode == true:
		Spray = Vector2.ZERO
	

	var Ray_End = Ray_Origin + dir * _fire_range
	#print("Ray_Origin: ", Ray_Origin)
	#print("Ray_End: ", Ray_End)

	# solution local mode
	#var _Camera = get_viewport().get_camera_3d()
	#var _Viewport = get_viewport().get_size()

	#var Ray_Origin1 = _Camera.project_ray_origin(_Viewport/2)
	#var Ray_End1 = (Ray_Origin + _Camera.project_ray_normal((_Viewport/2)+Vector2i(Spray))*_fire_range)

	#print("Ray_Origin1: ", Ray_Origin1)
	#print("Ray_End1: ", Ray_End1)

	var New_Intersection = PhysicsRayQueryParameters3D.create(Ray_Origin,Ray_End)
	New_Intersection.set_exclude(Collision_Exclusion)
	var Intersection = space_state.intersect_ray(New_Intersection)
	
	if not Intersection.is_empty():
		var Collision = [Intersection.collider,Intersection.position]
		var rd = Debug_Bullet.instantiate()
		var world = get_tree().get_root()
		world.add_child(rd)
		rd.global_translate(Intersection.position)
		return Collision
	else:
		return [null,Ray_End]



func HitScanCollision(Collision: Array):
	var Point = Collision[1]
	if Collision[0]:
		#if Collision[0].is_in_group("Target"):
			var Bullet = get_world_3d().direct_space_state

			var Bullet_Direction = (Point - Bullet_Point.global_transform.origin).normalized()
			var New_Intersection = PhysicsRayQueryParameters3D.create(Bullet_Point.global_transform.origin,Point+Bullet_Direction*2)

			var Bullet_Collision = Bullet.intersect_ray(New_Intersection)

			if Bullet_Collision:
				HitScanDamage(Bullet_Collision.collider, Bullet_Direction,Bullet_Collision.position,Current_Weapon.Damage)


func HitScanDamage(Collider, Direction, Position, Damage):
	#print("HitScanDamage")
	#if Collider.is_in_group("Target") and 
	if Collider.has_method("Hit_Successful"):
		Hit_Successfull.emit()
		var shooter = get_parent().get_parent()
		Collider.Hit_Successful(shooter, Damage, Direction, Position)


func LaunchProjectile(Point: Vector3):
	#print("LaunchProjectile: ", Point)
	var Direction = (Point - Bullet_Point.global_transform.origin).normalized()
	var shooter = get_parent().get_parent()
	var Projectile = Current_Weapon.Projectile_To_Load.instantiate()
	Projectile.Shooter = shooter

	Bullet_Point.add_child(Projectile)
	Add_Signal_To_HUD.emit(Projectile)
	
	var Projectile_RID = Projectile.get_rid()
	
	Collision_Exclusion.push_back(Projectile_RID)
	Projectile.tree_exited.connect(Remove_Exclusion.bind(Projectile_RID))
	
	Projectile.set_linear_velocity(Direction*Current_Weapon.Projectile_Velocity)
	Projectile.Damage = Current_Weapon.Damage


func Remove_Exclusion(_RID):
	Collision_Exclusion.erase(_RID)

func _on_pick_up_detection_body_entered(body):
	var Weapon_In_Stack = WeaponStack.find(body._weapon_name,0)
	
	if Weapon_In_Stack != -1:
		var remaining

		remaining = Add_Ammo(body._weapon_name, body._current_ammo+body._reserve_ammo)
		body._current_ammo = min(remaining, Weapons_List[body._weapon_name].Magazine)
		body._reserve_ammo = max(remaining - body._current_ammo,0)

		if remaining == 0:
			body.queue_free()
		
	elif body.TYPE == "Weapon":
		if body.Pick_Up_Ready == true:
			var GetRef = WeaponStack.find(Current_Weapon.Weapon_Name)
			WeaponStack.insert(GetRef,body._weapon_name)

			#Zero Out Ammo From the Resource
			Weapons_List[body._weapon_name].Current_Ammo = body._current_ammo
			Weapons_List[body._weapon_name].Reserve_Ammo = body._reserve_ammo

			Update_WeaponStack.emit(WeaponStack)
			exit(body._weapon_name)

			body.queue_free()

func Add_Ammo(_Weapon: String, Ammo: int)->int:
	var _weapon = Weapons_List[_Weapon]

	var Required = _weapon.Max_Ammo - _weapon.Reserve_Ammo
	var Remaining = max(Ammo - Required,0)

	_weapon.Reserve_Ammo += min(Ammo, Required)

	Update_Ammo.emit([Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])
	return Remaining
	
func secondary():
	if Current_Weapon.Secondary_Fire_Resource:
		if not Animation_Player.is_playing():
			Current_Weapon.Secondary_Fire()
			
			if Current_Weapon.Secondary_Fire_Resource.Secondary_Fire_Shoot:
				Secondary_Shoot(Current_Weapon.Secondary_Fire_Resource)
				
			Animation_Player.play(Current_Weapon.Secondary_Fire_Resource.Seconday_Fire_Animation)
			#var audio_node = Animation_Player.get_parent().get_node("{}/audio".format([Current_Weapon.Weapon_Name], "{}"))
			#audio_node.get_node("shoot").play();


func reset_secondary():
	if Current_Weapon.Secondary_Fire_Resource:
		if Current_Weapon.Secondary_Mode:
			if not Animation_Player.is_playing():
				Current_Weapon.Secondary_Fire_Released()
				if Current_Weapon.Secondary_Fire_Resource.Seconday_Fire_Animation_Reset:
					Animation_Player.play(Current_Weapon.Secondary_Fire_Resource.Seconday_Fire_Animation_Reset)


func Secondary_Shoot(secondary_resource):
	if secondary_resource.Ammo != 0:
		secondary_resource.Ammo  -= 1
		var CollissionPoint =  GetCameraCollision(Current_Weapon.Fire_Range)
		match secondary_resource.Fire_Type:
			"Hitscan":
				HitScanCollision(CollissionPoint)
			"Projectile":
				LaunchProjectile(CollissionPoint[1])
	reset_secondary()
