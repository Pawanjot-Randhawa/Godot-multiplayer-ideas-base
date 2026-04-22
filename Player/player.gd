extends CharacterBody3D
class_name Player
const PROGRESS_BAR = preload("uid://dug37jm6e2f8u")

@export_group("Movement")
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 10.0
@export var rotation_speed: float = 12.0

@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensitivity: float = 0.25
@export var tilt_upper_limit: float = PI / 3.0
@export var tilt_lower_limit: float = -PI / 8.0

#jump
@export_group("Jump")
@export var jump_height : float = 2.25
@export var jump_time_to_peak : float = 0.4
@export var jump_time_to_descent : float = 0.3

@onready var jump_velocity : float = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
@onready var jump_gravity : float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
@onready var fall_gravity : float = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)) * -1.0
# source: https://youtu.be/IOe1aGY6hXA?feature=shared

signal stamina_change(value)

var _camera_input_direction := Vector2.ZERO
var _last_movement_direction := Vector3.BACK
var move_speed: float
var stamina: int = 100:
	set(value):
		stamina = clampi(value, 0, 100)
		stamina_change.emit(stamina)
		if stamina == 0:
			zero_stamina()
	get:
		return stamina
var locked: bool = false

@export var move = false
@export var run = false
@export var on_floor = true

@onready var camera_pivot: Node3D = $Camera_Pivot
@onready var camera: Camera3D = $Camera_Pivot/SpringArm3D/Camera3D
@onready var animation_tree: AnimationTree = $AnimationTree

@onready var stamina_regen_timer: Timer = $StaminaRegen
@onready var drain_timer: Timer = $DrainTimer

func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())
func _ready() -> void:
	if not is_multiplayer_authority():
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	move_speed = walk_speed
	
	stamina_regen_timer.timeout.connect(func(): stamina+= 2)
	stamina_regen(true)
	spawn_stamina_bar()
	camera.current = true

func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("emote"):
		lock()
		print("auth is " + str(get_multiplayer_authority()) + "machine is " + str(multiplayer.get_unique_id()))
		one_shot_animation.rpc("parameters/Emote/request")
		await animation_tree.animation_finished
		unlock()
	if event.is_action_pressed("sprint") and stamina > 25:
		move_speed = sprint_speed
		run = true
		drain_stamina(1,true)
	elif event.is_action_released("sprint"):
		move_speed = walk_speed
		run = false
		stamina_regen(true)

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if event is InputEventMouseMotion:
		if event is InputEventMouseMotion:
			#camera_pivot.rotation.x -= deg_to_rad(event.screen_relative.y * mouse_sensitivity)
			#rotate_y(deg_to_rad(-event.screen_relative.x * mouse_sensitivity))
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				_camera_input_direction = event.screen_relative * mouse_sensitivity

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	handle_cam_rotation(delta)
	jump_logic(delta)
	var direction: Vector3
	if !locked:
		var input_dir := Input.get_vector("left", "right", "foward", "back")
		direction = (camera.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * move_speed
			velocity.z = direction.z * move_speed
			move = true
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
			move = false
	move_and_slide()
	
	if direction.length() > 0.2:
		_last_movement_direction = direction
	#calculate angle to the last movemnt direction, used to turn model
	var target_angle := Vector3.BACK.signed_angle_to(_last_movement_direction, Vector3.UP)
	%godot_plush_model.global_rotation.y = lerp_angle(%godot_plush_model.rotation.y, target_angle, rotation_speed * delta)

##Rotates the camera based on mouse motion
func handle_cam_rotation(delta):
	#Turn the camera with the mouse motion
	camera_pivot.rotation.x -= _camera_input_direction.y * delta
	camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, tilt_lower_limit, tilt_upper_limit)
	camera_pivot.rotation.y -= _camera_input_direction.x * delta
	#Reset to zero to prevent constant rotation
	_camera_input_direction = Vector2.ZERO

##Handles Jumping and gravity
func jump_logic(delta) -> void:
	#Default logic
	#if not is_on_floor():
		#velocity += get_gravity() * delta
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		#velocity.y = JUMP_VELOCITY
	#Custom logic
	if is_on_floor():
		on_floor = true
		if Input.is_action_just_pressed("jump") and stamina >= 20 and not locked:
			velocity.y = -jump_velocity
			drain_stamina(20,false)
			move_animation_state.rpc("parameters/Movement/playback", "up")
	else:
		on_floor = false
	var gravity = jump_gravity if velocity.y > 0.0 else fall_gravity
	velocity.y -= gravity * delta

###Locks Player movement
func lock():
	locked = true
	velocity.x = 0.0
	velocity.z = 0.0

###Unlocks Player Movment
func unlock():
	locked = false

##Drain Stamina at a constant rate or a one time value
func drain_stamina(rate: int, constant: bool):
	if not constant:
		stamina -= rate
	else:
		stamina_regen(false)
		#disconnect previous singals to remove old drain rate
		var conn = drain_timer.timeout.get_connections()
		if (conn):
			drain_timer.disconnect("timeout", conn.get(0).callable)
		drain_timer.timeout.connect(func(): stamina -= rate)
		drain_timer.start()

##Turns stamina regen off or on
func stamina_regen(allow_regen: bool):
	if allow_regen:
		drain_timer.stop()
		stamina_regen_timer.start()
	else:
		stamina_regen_timer.stop()

##Changes settings when out of stamina
func zero_stamina():
	drain_timer.stop()
	stamina_regen(true)
	move_speed = walk_speed
	run = false

##Spawns in a stamina bar that tracks this players stamina
func spawn_stamina_bar():
	var bar = PROGRESS_BAR.instantiate()
	bar.player = self
	
	#add it to the canvas layer of root for better project structure
	var canvas = get_tree().root.find_child("CanvasLayer", true, false)
	if canvas:
		canvas.add_child(bar)
	else:
		print("Error: Could not find CanvasLayer!")
func set_playernametag(value: String):
	%PlayerName.text = value
##Helper function to call one shot animations on all machines
@rpc("call_local", "reliable", "authority")
func one_shot_animation(location: String):
	animation_tree.set(location, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

@rpc("call_local", "reliable", "authority")
func move_animation_state(location: String, new_state):
	animation_tree.get(location).travel(new_state)
