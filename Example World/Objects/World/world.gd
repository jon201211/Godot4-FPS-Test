extends Node


@onready var main_menu = $CanvasLayer/MainMenu
@onready var address_entry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry
@onready var hud = $CanvasLayer/HUD
@onready var health_bar = $CanvasLayer/HUD/HealthBar


const Player = preload("res://Player_Controller/player_character.tscn")
const PORT = 9999
var peer = WebSocketMultiplayerPeer.new()


func _init():
	peer.supported_protocols = ["ludus"]


func _ready():
	multiplayer.peer_connected.connect(self.add_player)
	multiplayer.peer_disconnected.connect(self.remove_player)
	#multiplayer.server_disconnected.connect(self._close_network)
	#multiplayer.connection_failed.connect(self._close_network)
	#multiplayer.connected_to_server.connect(self._connected)



#func _unhandled_input(event):
#	#print(event)
#	if Input.is_action_just_pressed("quit"):
#		get_tree().quit()

func _on_host_button_pressed():
	main_menu.hide()
	#hud.show()
	
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer

	add_player(multiplayer.get_unique_id())
	

func _on_join_button_pressed():
	main_menu.hide()
	#hud.show()
	
	peer.create_client("ws://" + address_entry.text + ":" + str(PORT))
	multiplayer.multiplayer_peer = peer


func add_player(peer_id):
	var player = Player.instantiate()
	player.name = str(peer_id)
	player.position.y = 3
	add_child(player)
	if player.is_multiplayer_authority():
		player.health_changed.connect(update_health_bar)

func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()

func update_health_bar(health_value):
	health_bar.value = health_value

func _on_multiplayer_spawner_spawned(node):
	if node.is_multiplayer_authority():
		node.health_changed.connect(update_health_bar)



