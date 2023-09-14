extends Node


@onready var hud = $CanvasLayer/HUD
@onready var health_bar = $CanvasLayer/HUD/HealthBar
@onready var players = $Players

const Player = preload("res://Players/Scenes/player_character.tscn")


var SPAWN_RANDOM = 3.0


func _ready():
	hud.show()
	
	if not multiplayer.is_server():
		return
	

	multiplayer.peer_connected.connect(self.add_player)
	multiplayer.peer_disconnected.connect(self.remove_player)
	#multiplayer.server_disconnected.connect(self._close_network)
	#multiplayer.connection_failed.connect(self._close_network)
	#multiplayer.connected_to_server.connect(self._connected)

	add_player(multiplayer.get_unique_id())
	


func _exit_tree():
	if not multiplayer.is_server():
		return

	multiplayer.peer_connected.disconnect(self.add_player)
	multiplayer.peer_disconnected.disconnect(self.remove_player)



func add_player(peer_id):
	var player = Player.instantiate()
	player.name = str(peer_id)
	print("add_player  player name : ", player.name)
	# Randomize character position.
	var pos := Vector2.from_angle(randf() * 2 * PI)
	player.position = Vector3(pos.x * SPAWN_RANDOM * randf(), 3, pos.y * SPAWN_RANDOM * randf())
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


