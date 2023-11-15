@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_custom_type("WaterBody", "MeshInstance3D", preload("water_body.gd"), null)


func _exit_tree():
	remove_custom_type("WaterBody")
