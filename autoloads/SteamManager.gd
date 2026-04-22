extends Node

# SPACE WAR ID is 480
var STEAM_APP_ID:int = 480
var STEAM_USERNAME:String = ""
var STEAM_ID:int = 0

#track is this client is the host
var is_lobby_host:bool
#store the id of the lobby we are in or hosting
var lobby_id:int
#store people in lobby
var lobby_memebrs:Array

@export var checkpoints : Array[Marker3D] = []


func _init() -> void:
	#set initial steam settings
	OS.set_environment("SteamAppID", str(STEAM_APP_ID))
	OS.set_environment("SteamGameID", str(STEAM_APP_ID))

func _ready() -> void:
	#start steam
	Steam.steamInit()
	
	STEAM_ID = Steam.getSteamID()
	if STEAM_USERNAME == "": #done to account for local case
		STEAM_USERNAME = Steam.getPersonaName()
	print(STEAM_USERNAME)

func _process(delta: float) -> void:
	#need to run this to allow steam to run its stuff
	Steam.run_callbacks()
