extends Node3D

var is_raining: bool = false
var current_mouse_position: Vector2 = Vector2.ZERO
var is_window_dragging: bool = false:
	set(val):
		is_window_dragging = val
		if is_window_dragging:
			current_mouse_position = DisplayServer.mouse_get_position()

var mouse_offset: Vector2 = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if OS.get_name() == "Web":
		$UI/HBoxContainer/Close.hide()
		$UI/HBoxContainer/Regenerate.hide()
		$UI/HBoxContainer/ToggleRain.hide()
	await get_tree().process_frame
	$TerrainGenerator.generate(true)

func _input(event: InputEvent) -> void:
	if OS.get_name() != "Web" && OS.get_name() != "Android":
		if event.is_action_pressed("drag"):
			is_window_dragging = true
			mouse_offset = get_viewport().get_mouse_position()
		if event.is_action_released("drag"):
			is_window_dragging = false
			mouse_offset = Vector2.ZERO
			current_mouse_position = Vector2.ZERO
		if is_window_dragging:
			DisplayServer.window_set_position(current_mouse_position - mouse_offset)
			current_mouse_position = DisplayServer.mouse_get_position()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("regenerate") && OS.get_name() != "Web":
		$TerrainGenerator.clear()
		$TerrainGenerator.generate(true)
	if Input.is_action_just_pressed("rain") && OS.get_name() != "Web":
		if !is_raining:
			rain_weather()


func rain_weather() -> void:
	is_raining = true
	var tween: Tween = create_tween()
	tween.tween_property($DirectionalLight3D, "light_color", Color(0.625, 0.625, 0.625), 1.0)
	$Rain.show()
	await get_tree().create_timer(90.0).timeout
	$Rain.hide()
	tween.tween_property($DirectionalLight3D, "light_color", Color(0.973, 0.973, 0.918, 1.0), 1.0)
	is_raining = false


func _on_close_pressed() -> void:
	if OS.get_name() != "Web":
		get_tree().quit()


func _on_regenerate_pressed() -> void:
	if OS.get_name() != "Web":
		Input.action_press("regenerate")
		await get_tree().process_frame
		Input.action_release("regenerate")


func _on_camera_toggle_pressed() -> void:
	Input.action_press("toggle_mode")
	await get_tree().process_frame
	Input.action_release("toggle_mode")


func _on_toggle_rain_pressed() -> void:
	if OS.get_name() != "Web":
		Input.action_press("rain")
		await get_tree().process_frame
		Input.action_release("rain")


func _on_info_pressed() -> void:
	$UI/Panel.visible = !$UI/Panel.visible
