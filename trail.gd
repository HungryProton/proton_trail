extends Spatial

# --
# GM Trail
# --
# This node generates a 3D trail at runtime
# Two nodes defines the width of the the trail. At each tick, the process
# function update the trail geometry, add new points if the latest ones 
# are too far away from the previous ones, and remove the oldest points 
# if they expired.
#
# This behavior will probably change in the future to accomodate
# bezier curves, camera facing and other features.
# --
# material : The material applied to the trail. UV coordinates are
#   defined as follow :
#   + The most recent points are at the left of the texture (0,0) and (0,1)
#   + The oldest points are at the right (1,0) and (1,1)
#   + That means the texture is stretch accross the entire trail at all times
#
# resolution : The maximum distance between two sets of points.
#   + One caveat though : If the two trails drivers moved farther than the
#     trail resolution in one frame, intermediate vertices will not be created
# 
# life_time : How long a point can exist in the trail.
#
# emit : True means the trail will keep creating new points. False means it
#   will only draw points still in memory and delete them, but wont create
#   new geometry.
# --

class_name GM_Trail

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
	if not emit:
		return
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
	var count = len(data)
	for i in range(count):
		var uv_x = i/(count+0.0)
		
		geometry.set_uv(Vector2(uv_x, 1.0))
		geometry.add_vertex(data[i].p1)
		
		geometry.set_uv(Vector2(uv_x , 0.0))
		geometry.add_vertex(data[i].p2)

	geometry.end()

func _update_midpoint():
	if not trail_top:
		_ready()
	midpoint = (trail_top.get_global_transform().origin + trail_bottom.get_global_transform().origin) / 2.0