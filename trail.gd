extends Spatial

export(Material) var material
export(float) var resolution = 0.2
export(float) var life_time = 0.1
export(bool) var emit = true

# TODO : replace with an arbitrary sized array of positions
onready var trail_top : Spatial = get_node("Top")
onready var trail_bottom : Spatial = get_node("Bottom")

var geometry : ImmediateGeometry = ImmediateGeometry.new()
var data : Array = []
var midpoint : Vector3
var resolution_squared : float

class Point:
	var ttl : float
	var midpoint : Vector3
	var p1 : Vector3
	var p2 : Vector3

func _ready():
	set_process(true)
	get_tree().get_root().call_deferred("add_child", geometry)
	
	geometry.set_name("TrailMeshInstance")
	geometry.set_material_override(material)
	geometry.translation = Vector3(0.0, 0.0, 0.0)
	
	resolution_squared = resolution * resolution

func _process(delta):
	_update_midpoint()
	if emit:
		_update_last_points()
		_update_geometry_data(delta)
	_draw_geometry()

func _update_last_points():
	if len(data) == 0:
		return

	data[0].p1 = trail_top.get_global_transform().origin
	data[0].p2 = trail_bottom.get_global_transform().origin
	data[0].midpoint = midpoint

func _update_geometry_data(delta):
	for i in range(len(data) - 1, 0, -1):
		data[i].ttl -= delta
		if data[i].ttl <= 0:
			data.pop_back()
			
	if len(data) <= 1:
		_add_point_to_trail()
		return

	if data[0].midpoint.distance_squared_to(data[1].midpoint) >= resolution_squared:
		_add_point_to_trail()

func _add_point_to_trail():
	var p = Point.new()
	p.ttl = life_time
	p.p1 = trail_top.get_global_transform().origin
	p.p2 = trail_bottom.get_global_transform().origin
	p.midpoint = midpoint
	data.push_front(p)

func _draw_geometry():
	if(len(data) < 1):
		return
	geometry.clear()
	geometry.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, null)

	for i in range(len(data)):
		geometry.add_vertex(data[i].p1)
		geometry.add_vertex(data[i].p2)

	geometry.end()

func _update_midpoint():
	if not trail_top:
		_ready()
	midpoint = (trail_top.get_global_transform().origin + trail_bottom.get_global_transform().origin) / 2.0