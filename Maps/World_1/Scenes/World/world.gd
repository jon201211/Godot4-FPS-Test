extends Node
class_name World

@onready var hud = $CanvasLayer/HUD
@onready var health_bar = $CanvasLayer/HUD/HealthBar
@onready var players = $Players

const Player = preload("res://Players/Scenes/player_character.tscn")


var SPAWN_RANDOM = 3.0

var LEVEL_ROUND_MAX = 50

signal LEVEL_NEXT_ROUND

var playerList = {}
var level_round = 0

var player_total = 0
var alive_player_count = 0


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

	playerList[peer_id] = player
	player_total += 1
	alive_player_count += 1

	if player.is_multiplayer_authority():
		player.health_changed.connect(update_health_bar)

func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		playerList.erase(peer_id)
		player.queue_free()
		player_total -= 1
		alive_player_count -= 1

func update_health_bar(player, health_value):
	if health_bar.value != health_value and health_value == 0:
		alive_player_count -= 1

	#if health_bar.value == health_value
	#	return

	health_bar.value = health_value

	if (player_total > 1 ) and alive_player_count <= 1:
		print("game over this round!")
		#reset_level_round()
		reset_level_round.rpc()



func _on_multiplayer_spawner_spawned(node):
	if node.is_multiplayer_authority():
		node.health_changed.connect(update_health_bar)



@rpc("call_local", "any_peer")
func reset_level_round():
	level_round += 1
	print("next round: ", level_round)
	emit_signal("LEVEL_NEXT_ROUND")
