extends Node
class_name MultiplayerManager


var players_list: Dictionary = {}

@export var player_scene: PackedScene

@export var players_container_node: Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Assumes that this is not an autload, is added after the peer connections have been made
	
	if multiplayer.has_multiplayer_peer() && is_multiplayer_authority():
		# Leverage the peer connected signal to trigger the player spawn
		multiplayer.peer_connected.connect(add_player)
		
		# Handle the disconnect signal here so we have access to what needs cleaned up in game.
		multiplayer.peer_disconnected.connect(remove_player)
		#add host
		add_player(1)

func add_player(peer_id: int):
	#Code should only run on server/host
	if not multiplayer.is_server():
		return
	print("Adding player to game: %s" % peer_id)
	if players_list.get(peer_id) == null:
		var player = player_scene.instantiate()
		#Set name of player node to be equal to the pper id, this is used to set authority in the plaeyr enter tree function
		player.name = str(peer_id)
		#Setting random spawn point
		player.position = Vector3(randi_range(-2, 2), 1, randi_range(-2, 2))
		#Add this plaer to list with key = peerid and value = player node
		players_list[peer_id] = player
		#Add to the player copntainer
		players_container_node.add_child(player)
	else:#Else should not trigger ideally
		print("Warning! Attempted to add existing player to game: %s" % peer_id)

func remove_player(peer_id: int):
	#Code should only run on server/host
	if not multiplayer.is_server():
		return
	print("Removing player from game: %s" % peer_id)
	if players_list.has(peer_id):
		var player_to_remove = players_list[peer_id]
		if player_to_remove:
			player_to_remove.queue_free()
			players_list.erase(peer_id)
