extends Node

@onready var canvas_layer: CanvasLayer = $CanvasLayer

@export var inital_area : PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if multiplayer.is_server():
		handle_area_switch(inital_area)
		Signalbus.change_level_to.connect(handle_area_switch)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func handle_area_switch(area: PackedScene):
	var authority = "SERVER" if multiplayer.is_server() else "CLIENT"
	var peer_id = multiplayer.get_unique_id()
	print("[%s (ID: %d)] handle_area_switch called for: %s" % [authority, peer_id, area.resource_path])
	if multiplayer.is_server():
		var new_area = area.instantiate()
		#assumes only one area is loaded
		var current_area = %LevelContainer.get_child(0)
		if current_area:
			%LevelContainer.remove_child(current_area)
			current_area.queue_free()
		%LevelContainer.add_child(new_area)
