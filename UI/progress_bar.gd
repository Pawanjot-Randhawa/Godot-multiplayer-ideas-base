extends ProgressBar

@export var player: Player
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player.stamina_change.connect(update)

func update(stamina):
	value = stamina
