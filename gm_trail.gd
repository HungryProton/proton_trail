tool
extends EditorPlugin

func get_name(): 
	return "Trail"

func _enter_tree():
	add_custom_type(
		"Trail", 
		"Spatial",
		load("res://addons/gm_trail/trail.gd"),
		load("res://addons/gm_trail/trail.svg")
	)

func _exit_tree():
	remove_custom_type("Trail")
