extends MeshInstance3D
## Apply seasonal outfits
## Applied only for built-in classes.
## Made by Yni, licensed under MIT License.

@export var custom_seed_material: Dictionary[String, Array] = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if get_tree().root.get_node_or_null("Game") != null && !custom_seed_material.is_empty():
		var seed: String = get_tree().root.get_node("Game").player_name
		if custom_seed_material.has(seed):
			for i in range(custom_seed_material[seed].size()):
				if custom_seed_material[seed][i] == null:
					continue
				if custom_seed_material[seed][i] is Material:
					set_surface_override_material(i, custom_seed_material[seed][i])


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
