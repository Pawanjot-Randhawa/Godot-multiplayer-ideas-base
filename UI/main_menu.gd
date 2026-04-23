extends PanelContainer

@export_enum("Steam", "Local") var NET_MODE : String = "Local"

var peer: MultiplayerPeer

#UI
@onready var lobbies: VBoxContainer = $MarginContainer/LobbyList/lobbies/VBoxContainer
@onready var lobby_list_container: VBoxContainer = $MarginContainer/LobbyList
@onready var main_menu_container: VBoxContainer = $MarginContainer/MainMenu
@onready var filter_name: LineEdit = $MarginContainer/LobbyList/filterName


#const PLAYER = preload("uid://cdne2banlrbwx")
@export var PLAYER: PackedScene

@export var playersContainer: Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if NET_MODE == "Local":
		peer = ENetMultiplayerPeer.new()
		SteamManager.STEAM_USERNAME = str(multiplayer.get_unique_id())
	else:
		peer = SteamMultiplayerPeer.new()
	
	Steam.lobby_created.connect(on_lobby_created)
	Steam.lobby_joined.connect(on_lobby_joined)
	Steam.lobby_match_list.connect(on_lobby_match_list)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# View params by looking at the signal in documentation
func on_lobby_created(connect: int, _lobby_id: int):
	if connect:
		Steam.setLobbyData(_lobby_id, "name", str(SteamManager.STEAM_USERNAME+"'s Lobby"))
		Steam.setLobbyJoinable(_lobby_id, true)
		peer.host_with_lobby(_lobby_id)
		#peer.create_host(0)
		multiplayer.multiplayer_peer = peer
		
		SteamManager.lobby_id = _lobby_id
		SteamManager.is_lobby_host = true

#Triggered whenever we join a lobby, connected to this via ready function
func on_lobby_joined(lobby: int, permissons:int, locked:bool, response:int):
	if Steam.getLobbyOwner(SteamManager.lobby_id) == Steam.getSteamID():
		return
	peer.connect_to_lobby(SteamManager.lobby_id)
	multiplayer.multiplayer_peer = peer


# Triggerd when Main Menu join is pressed
# Hides main menu and brings up lobby menu
func _on_join_button_pressed() -> void:
	main_menu_container.hide()
	lobby_list_container.show()
	if NET_MODE == "Local":
		hide()
		peer.create_client("127.0.0.1", 1027)
		multiplayer.multiplayer_peer = peer #this is set automatically via singsla in steam version
		print("worked")
		return
	#Clear any chuildren if there are any
	var lobby_btns = lobbies.get_children()
	for i in lobby_btns:
		i.queue_free()
	#Request lobby data from steam
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.requestLobbyList()

#Triggered whebn we receive lobby list from steam, connected via ready function
#Parses lobbies into buttons that are added to list
func on_lobby_match_list(lobbies: Array):
	#Go through each lobby
	for lobby in lobbies:
		var lobby_name = Steam.getLobbyData(lobby, "name")
		var member_count = Steam.getNumLobbyMembers(lobby)
		var max_players = Steam.getLobbyMemberLimit(lobby)
		print(lobby_name)
		
		var but:Button = Button.new()
		but.text = "Name: {0} | Current: {1} | Max: {2}".format([lobby_name,member_count,max_players])
		
		but.pressed.connect(join_lobby.bind(lobby)) #lobby is the lobby id
		self.lobbies.add_child(but)

#This is connect to the lobby buttons, allows player to join a lobby
func join_lobby(_lobby_id : int = 0):
	#if NET_MODE == "Local":
		#peer.create_client("127.0.0.1", 1027)
		#multiplayer.multiplayer_peer = peer #this is set automatically via singsla in steam version
	#elif NET_MODE == "Steam":
	Steam.joinLobby(_lobby_id)
	SteamManager.lobby_id = _lobby_id
	hide()

# Adds a player with there ID
func add_player(peer_id):
	var p : Player = PLAYER.instantiate()
	p.name = str(peer_id)
	var authority = "SERVER" if multiplayer.is_server() else "CLIENT"
	p.set_playernametag(authority)
	#p.set_multiplayer_authority(peer_id) not sure if better to do here or in player
	%Players.add_child(p)

func remove_player(peer_id):
	var p = playersContainer.get_node_or_null(str(peer_id))
	if p:
		p.queue_free()
		if multiplayer.is_server():
			pass
#Triggered when pressing host from Main Menu
func _on_host_button_pressed() -> void:
	hide()
	if NET_MODE == "Local":
		peer.create_server(1027)
		multiplayer.multiplayer_peer = peer #this is set automatically via singsla in steam version
	elif NET_MODE == "Steam":
		Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC)
	multiplayer.peer_connected.connect(add_player) #when a player connects add them
	multiplayer.peer_disconnected.connect(remove_player) #when a player leaves remove them
	
	add_player(multiplayer.get_unique_id()) # add host

#Filters lobby names, triggers on text switch
func _on_filter_name_text_changed(new_text: String) -> void:
	for lobby in lobbies.get_children():
		if lobby is Button:
			if new_text == "":
				lobby.show()
			elif new_text in lobby.text.to_lower():
				lobby.show()
			else:
				lobby.hide()
