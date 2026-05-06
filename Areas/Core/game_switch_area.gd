extends Area3D


@export_file(".tscn") var target_area : String
#Export file must be used as this scene can cause circular depencys where A loads B, and B loads A
#With export file we can just load the scene when the player actually enters the area, avoiding the infinite loop


func _on_body_entered(body: Node3D) -> void:
	if body is Player and multiplayer.is_server():
		var authority = "SERVER" if multiplayer.is_server() else "CLIENT"
		print(authority + " enter")
		Signalbus.change_level_to.emit(load(target_area))


func _on_body_exited(body: Node3D) -> void:
	if body is Player:
		print("Player exit")
