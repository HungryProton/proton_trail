tool
extends EditorPlugin


func get_name():
	return "ProtonTrail"


func _enter_tree():
	add_custom_type(
		"ProtonTrail",
		"Spatial",
		preload("proton_trail.gd"),
		preload("proton_trail.svg")
	)


func _exit_tree():
	remove_custom_type("ProtonTrail")
