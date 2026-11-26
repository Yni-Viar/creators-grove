extends Node3D
class_name BaseMobScript

@export var animation_player: AnimationPlayer
@export var animation_remaps: Dictionary[MovableNpc.State, String]

# Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#pass # Replace with function body.
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _physics_process(delta: float) -> void:
	#pass

func set_state(state: MovableNpc.State) -> void:
	if animation_player != null:
		animation_player.play(animation_remaps[state])
