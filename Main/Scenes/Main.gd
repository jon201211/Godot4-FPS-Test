extends Node

@onready var levels = $Level
@onready var menu = $MainMenu
@onready var line_edit = $MainMenu/VBoxContainer/LineEdit


var world_scene = null


const POPUP_SCORE_SCENE = preload("res://UI/ScoreTable/ScoreTable.tscn")
var popup_score = null

const POPUP_SETTINGS_SCENE = preload("res://UI/Settings/SettingsMenu.tscn")
var popup_settings = null


const PORT = 9999

var menu_show = 0
var SPAWN_RANDOM = 5.0

func _ready():

	# Start paused
	#get_tree().paused = true
	# You can save bandwith by disabling server relay and peer notifications.
	#multiplayer.server_relay = false

	# Automatically start the server in headless mode.
	if DisplayServer.get_name() == "headless":
		print("Automatically starting dedicated server")
		_on_host_button_pressed.call_deferred()


func _on_host_button_pressed():
	# Start as server
	var peer = WebSocketMultiplayerPeer.new()
	peer.create_server(PORT)

	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer server")
		return
	multiplayer.multiplayer_peer = peer
	start_game()


func _on_join_button_pressed():
	# Start as client
	var peer = WebSocketMultiplayerPeer.new()
	peer.create_client("ws://" + line_edit.text + ":" + str(PORT))

	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer client")
		return
	multiplayer.multiplayer_peer = peer
	start_game()

func start_game():
	# Hide the UI and unpause to start the game.
	menu.hide()
	menu_show = 0
	#get_tree().paused = false
	# Only change level on the server.
	# Clients will instantiate the level via the spawner.
	if multiplayer.is_server():
		change_level.call_deferred(load("res://Maps/World_1/Scenes/World/world.tscn"))


# Call this function deferred and only on the main authority (server).
func change_level(scene: PackedScene):
	# Remove old level if any.
	for c in levels.get_children():
		levels.remove_child(c)		
		c.queue_free()
	# Add new level.
	world_scene = scene.instantiate()
	world_scene.connect("LEVEL_NEXT_ROUND", self.on_level_next_round)
	levels.add_child(world_scene)


func popup_score_show():
	if popup_score == null:
		# Make a new popup scene
		popup_score = POPUP_SCORE_SCENE.instantiate()

		# Add it as a child, and make it pop up in the center of the screen
		self.add_child(popup_score)
		popup_score.popup_centered()

		popup_score.connect("POPUP_SCORE_CLOSE", Callable(self, "popup_score_delete"))
		
		# Make sure the mouse is visible
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func popup_score_delete():
	# Make sure the mouse is visible
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# If we have a popup, destoy it
	if popup_score != null:
		popup_score.queue_free()
		popup_score = null



func on_level_next_round():
	print("level next round")
	popup_score_show()
	GlobalTimer.create_timeout(self.on_level_next_round_timeout, 5)


func on_level_next_round_timeout():
	print("level next round start")
	popup_score_delete()
	if world_scene:
		world_scene.reset_level_round()



# The server can restart the level by pressing HOME.
func _unhandled_input(event):
	#if multiplayer.is_server() and event.is_action("ui_home") and Input.is_action_just_pressed("ui_home"):
	#	change_level.call_deferred(load("res://Maps/World_1/Scenes/World/world.tscn"))
	#print("main input:", event)

	if event.is_action_pressed("show_billboard"):
		#print("TAB pressed")
		popup_score_show()


	if event.is_action("ui_cancel") and Input.is_action_just_pressed("ui_cancel"):
		if menu_show:
			popup_settings_delete()
			menu_show = 0
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			popup_settings_show()
			menu_show = 1
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)



func popup_settings_show():
	if popup_settings == null:
		# Make a new popup scene
		popup_settings = POPUP_SETTINGS_SCENE.instantiate()

		# Add it as a child, and make it pop up in the center of the screen
		self.add_child(popup_settings)
		popup_settings.popup_centered()

		popup_settings.connect("POPUP_SETTINGS_CLOSE", Callable(self, "popup_settings_delete"))
		


func popup_settings_delete():
	# If we have a popup, destoy it
	if popup_settings != null:
		popup_settings.queue_free()
		popup_settings = null




func _on_settings_button_pressed():
	popup_settings_show()
	pass


func _on_exit_button_pressed():
	get_tree().quit()




func _on_level_spawner_spawned(node):
	#if node.is_multiplayer_authority():
	node.connect("LEVEL_NEXT_ROUND", self.on_level_next_round)
	world_scene = node
	#pass # Replace with function body.
