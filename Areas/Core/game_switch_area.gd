extends Area3D


@export var area_to_switch_to : PackedScene


func _on_body_entered(body: Node3D) -> void:
	if body is Player and multiplayer.is_server():
		var authority = "SERVER" if multiplayer.is_server() else "CLIENT"
		print(authority + " enter")
		Signalbus.change_level_to.emit(area_to_switch_to)


func _on_body_exited(body: Node3D) -> void:
	if body is Player:
		print("Player exit")
