extends Node

enum AvailableNetworks {ENET, STEAM}

var connection = AvailableNetworks.ENET
var peer: MultiplayerPeer
var is_host = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if connection == AvailableNetworks.ENET:
		peer = ENetMultiplayerPeer.new()
	elif connection == AvailableNetworks.STEAM:
		peer = SteamMultiplayerPeer.new()
		#Steam signal connections
		#Steam.lobby_created.connect(on_lobby_created)
		#Steam.lobby_joined.connect(on_lobby_joined)
		#Steam.lobby_match_list.connect(on_lobby_match_list)


##Universal for Enet and Steam, basic function to host a game, connect this to a host game button
func host_game():
	if connection == AvailableNetworks.ENET:
		peer.create_server(1027)
		multiplayer.multiplayer_peer = peer #this is set automatically via signals in steam version
	elif connection == AvailableNetworks.STEAM:
		Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC)
	print(get_tree().to_string())
	Signalbus.emit_signal("game_hosted")
	
##Universal for Enet and Steam, basic function to join a game, connect this to a join game button
func join_game():
	if connection == AvailableNetworks.ENET:
		peer.create_client("127.0.0.1", 1027)
		multiplayer.multiplayer_peer = peer #this is set automatically via signals in steam version
		print("worked")
	elif connection == AvailableNetworks.STEAM:
		pass
		#Lobby stuff

func _disconnect():
	pass

func reset_network_properties():
	is_host = false
