extends Node

@onready var levels = $Level
@onready var menu = $MainMenu
@onready var line_edit = $MainMenu/VBoxContainer/LineEdit
@onready var bill_board = $ScoreTable

const BILL_BOARD_SCENE = preload("res://UI/ScoreTable/ScoreTable.tscn")
var popup = null

const PORT = 9999

var menu_show = 0
var SPAWN_RANDOM = 5.0

func _ready():
#	bill_board.hide()
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
	levels.add_child(scene.instantiate())



func pop_delete():
	# Make sure the mouse is visible
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# If we have a popup, destoy it
	if popup != null:
		popup.queue_free()
		popup = null


# The server can restart the level by pressing HOME.
func _input(event):
	#if multiplayer.is_server() and event.is_action("ui_home") and Input.is_action_just_pressed("ui_home"):
	#	change_level.call_deferred(load("res://Maps/World_1/Scenes/World/world.tscn"))
	#print("main input:", event)

	if event.is_action_pressed("show_billboard"):
		print("TAB pressed")
		if popup == null:
			# Make a new popup scene
			popup = BILL_BOARD_SCENE.instantiate()

			# Add it as a child, and make it pop up in the center of the screen
			self.add_child(popup)
			popup.popup_centered()

			popup.connect("POP_CLOSE", Callable(self, "pop_delete"))
			
			# Make sure the mouse is visible
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)





	if event.is_action("ui_cancel") and Input.is_action_just_pressed("ui_cancel"):
		if menu_show:
			menu.hide()
			menu_show = 0
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			menu.show()
			menu_show = 1
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func return_main_menu():
	# Remove old level if any.
	for c in levels.get_children():
		levels.remove_child(c)
		c.queue_free()
	# Add new level.
	menu.show()


func _on_exit_button_pressed():
	return_main_menu()
	pass # Replace with function body.




