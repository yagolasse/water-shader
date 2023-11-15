@tool
extends MeshInstance3D
class_name WaterBody

const water_mesh = preload("res://addons/water-shader/water_mesh.tres")
const water_material = preload("res://addons/water-shader/water_material.tres")

func _enter_tree() -> void:
	mesh = water_mesh
	material_override = water_material
