extends Node3D
## Made by Yni Viar
## Contains third-party code by GDQuest
## Licensed under MIT License
class_name TerrainChunk

enum Quality {LOW, MIDDLE}

## With LOW quality, any prop or mob can spawn in 1/64 chance per vertex,
## while MIDDLE quality - 1/32 chance per vertex
@export var quality: Quality = Quality.LOW
## Prop registry
@export var registry: GameRegistry

var biomes: FastNoiseLite = FastNoiseLite.new()
## Static rock mesh
@export var terrain_mesh: ArrayMesh
## Water level mesh
@export var water_level_mesh: ArrayMesh
## Base terrain mesh
@export var terrain_surface_mesh: ArrayMesh
## Navigation mesh (you can create new one)
@export var navigation_mesh_preset: NavigationMesh
## Chance of spawning a mob
@export var mob_spread: float = 0.125
## Chance of spawning a tree
@export var tree_spread: float = 0.75
## Chance of spawning a sculpture
@export var sculpture_spread: float = 0.125

var has_lake: bool = false

var underwater_monument: Vector2i = Vector2i.ZERO

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var temp_terrain_mesh: ArrayMesh


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if OS.get_name() == "Web" || OS.get_name() == "Android":
		quality = Quality.LOW
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass

func generate(immediate: bool) -> void:
	var navigation_mesh: NavigationRegion3D = NavigationRegion3D.new()
	add_child(navigation_mesh)
	navigation_mesh.navigation_mesh = navigation_mesh_preset
	
	biomes.seed = rng.randi()
	
	if temp_terrain_mesh == null:
		await terrain_generator(navigation_mesh, immediate)
	
	#var water_level: MeshInstance3D = MeshInstance3D.new()
	#water_level.mesh = PlaneMesh.new()
	#water_level.mesh.size = Vector2(64, 64)
	#water_level.mesh.center_offset = Vector3(32, -1, 32)
	#water_level.mesh.surface_set_material(0, preload("res://Shaders/water.tres"))
	#call_deferred("add_child", water_level)

## Generates terrain
func terrain_generator(navigation_mesh: NavigationRegion3D, immediate: bool) -> void:
	var structures: Node3D = Node3D.new()
	navigation_mesh.add_child(structures)
	var static_body: StaticBody3D = StaticBody3D.new()
	structures.add_child(static_body)
	## BEGIN THIRD-PARTY CODE
	## Copyright (c) 2022 GDQuest . Licensed under MIT License
	var mesh: ArrayMesh = ArrayMesh.new()
	var mdt: MeshDataTool = MeshDataTool.new()
	mdt.create_from_surface(terrain_surface_mesh, 0)
	
	for vertex_index in mdt.get_vertex_count():
		var vertex_normal := mdt.get_vertex_normal(vertex_index)
		if vertex_normal.dot(Vector3.UP) < 0.1: continue
		#var vertex_uv := mdt.get_vertex_uv(vertex_index)
		var vertex := mdt.get_vertex(vertex_index)
		var sample := biome_height_generator(vertex, true)
		vertex.y += sample 
		mdt.set_vertex(vertex_index, vertex)
		
		
	mdt.commit_to_surface(mesh)
	var st: SurfaceTool = SurfaceTool.new()
	st.create_from(mesh, 0)
	## END THIRD-PARTY CODE
	st.generate_normals()
	if !immediate:
		await get_tree().process_frame
	st.generate_tangents()
	if !immediate:
		await get_tree().process_frame
	temp_terrain_mesh = st.commit()
	
	if terrain_mesh != null:
		var static_mi: MeshInstance3D = MeshInstance3D.new()
		static_mi.mesh = terrain_mesh
		static_mi.create_trimesh_collision()
		add_child(static_mi)
		static_mi.global_position.y = 1.0
	
	if water_level_mesh != null:
		var water_level: MeshInstance3D = MeshInstance3D.new()
		water_level.mesh = water_level_mesh
		add_child(water_level)
		water_level.global_position.y = 1.0
	
	if !immediate:
		await get_tree().process_frame
	## Spawn the result terrain
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.mesh = temp_terrain_mesh
	mi.mesh.surface_set_material(0, preload("res://Shaders/chunk.tres"))
	mi.create_trimesh_collision()
	navigation_mesh.add_child(mi)
	## Create biomes
	for vertex_index in mdt.get_vertex_count():
		biome_generator(mdt.get_vertex(vertex_index), structures, static_body)
		if !immediate:
			await get_tree().process_frame
	
	if !immediate:
		await get_tree().process_frame
	
	navigation_mesh.bake_navigation_mesh(false)
	
	if !immediate:
		await get_tree().process_frame

func biome_height_generator(vertex: Vector3, generate_lake_monument: bool) -> float:
	if vertex.distance_to(global_position) <= 48:
		#if biomes.get_noise_2d(x, y) > 0.85 && enable_mountains:
			#return 32.0
		if biomes.get_noise_2d(vertex.x, vertex.z) < -0.1:
			has_lake = true
			if biomes.get_noise_2d(vertex.x - 1, vertex.z - 1) < -0.1 && \
			   biomes.get_noise_2d(vertex.x - 1, vertex.z) < -0.1 && \
			   biomes.get_noise_2d(vertex.x - 1, vertex.z + 1) < -0.1 && \
			   biomes.get_noise_2d(vertex.x + 1, vertex.z - 1) < -0.1 && \
			   biomes.get_noise_2d(vertex.x + 1, vertex.z) < -0.1 && \
			   biomes.get_noise_2d(vertex.x + 1, vertex.z + 1) < -0.1 && \
			   generate_lake_monument:
				underwater_monument = Vector2i(vertex.x, vertex.z)
			return -32.0
		elif biomes.get_noise_2d(vertex.x, vertex.z) < -0.01:
			has_lake = true
			return -2.0
		elif biomes.get_noise_2d(vertex.x, vertex.z) < 0.625 && biomes.get_noise_2d(vertex.x, vertex.z) > 0.375:
			return 2.0
		else:
			return 1.0
	else:
		return 1.0

func biome_generator(vertex: Vector3, structures: Node3D, static_body: StaticBody3D):
	var quality_preset: int = 64
	if quality == Quality.MIDDLE:
		quality_preset = 32
	var random_number: float = rng.randf_range(0, (tree_spread + sculpture_spread + mob_spread) * quality_preset)
	if random_number < tree_spread:
		# Don't spawn trees in lakes
		if vertex.y < -0.01: 
			return
			
		var mi: MeshInstance3D = MeshInstance3D.new()
		mi.mesh = registry.trees[rng.randi_range(0, registry.trees.size() - 1)]
		static_body.add_child(mi)
		mi.scale = Vector3(0.75, 0.75, 0.75)
		mi.global_position = Vector3(vertex.x, vertex.y - 1, vertex.z)
		var collider: CollisionShape3D = CollisionShape3D.new()
		collider.shape = CylinderShape3D.new()
		collider.shape.height = 32.0
		collider.shape.radius = 2.0
		static_body.add_child(collider)
		collider.position = Vector3(mi.global_position.x, vertex.y - 1, mi.global_position.z)
	elif random_number < tree_spread + sculpture_spread:
		var scene: Node3D
		if vertex.y < -0.01:
			scene = registry.underwater_sculptures[rng.randi_range(0, registry.underwater_sculptures.size() - 1)].instantiate()
		else:
			scene = registry.sculptures[rng.randi_range(0, registry.sculptures.size() - 1)].instantiate()
		structures.add_child(scene)
		scene.global_position = Vector3(vertex.x, vertex.y, vertex.z)
	elif random_number < tree_spread + sculpture_spread + mob_spread:
		if vertex.y < -0.01: 
			return
		var npc: MovableNpc = load("res://Mobs/Npc.tscn").instantiate()
		npc.mob_res = registry.mobs[rng.randi_range(0, registry.mobs.size() - 1)]
		npc.wandering = true
		structures.add_child(npc)
		npc.global_position = Vector3(vertex.x, vertex.y, vertex.z)

func clear() -> void:
	for child in get_children():
		child.queue_free()
	temp_terrain_mesh = null
