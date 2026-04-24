extends Node

@onready var canvas_layer: CanvasLayer = $CanvasLayer

@export var inital_area : PackedScene
@export var MULTIPLAYERMANAGER : PackedScene

const PLAYER = preload("uid://cvfx5ewamu3c2")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Signalbus.game_hosted.connect(new_game)

func new_game():
	#Code should only run on server/host
	if not multiplayer.is_server():
		return

	#Add in the Multiplayer manger for host only, the spawner nodes will sync things
	var MM : MultiplayerManager = MULTIPLAYERMANAGER.instantiate()
	MM.player_scene = PLAYER
	MM.players_container_node = %Players
	add_child(MM)
	#Spawn in intial area, dont use method as the method is desinged for switches so it will throw an error due to no current
	handle_area_switch(inital_area)
	#Connect relavent signals
	Signalbus.change_level_to.connect(handle_area_switch)

func handle_area_switch(area: PackedScene):
	if multiplayer.is_server():
		var new_area = area.instantiate()
		#assumes only one area is loaded
		var current_area = %LevelContainer.get_child(0)
		if current_area == null:
			print("Current area is null when trying to do a area switch")
		elif current_area:
			current_area.queue_free()
		%LevelContainer.add_child(new_area)
