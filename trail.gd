extends Path

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
export(float) var cross_section_resolution = 0.5
export(float) var trail_resolution = 1
export(float) var life_time = 0.1
export(bool) var emit = true
export(bool) var flip_uv_x = false
export(bool) var flip_uv_y = false
export(NodePath) var debug_path

export(NodePath) var debug
onready var dnode = get_node(debug)
onready var dpath = get_node(debug_path)

class Point:
	var ttl : float
	var basis : Basis

var geometry : ImmediateGeometry = ImmediateGeometry.new()
var points : Array = []
var trail_curve : Curve3D

func _ready():
	set_process(true)
	_init_geometry()
	_init_trail_curve()
	_init_cross_section_path()

func _init_geometry():
	# Generated geometry is attached to the scene root node to simplify
	# the mesh generation and reduce unnecessary local <-> global space
	# switches
	get_tree().get_root().call_deferred("add_child", geometry)
	geometry.set_name("TrailMeshInstance")
	geometry.set_material_override(material)
	geometry.translation = Vector3(0.0, 0.0, 0.0)

func _init_trail_curve():
	trail_curve = Curve3D.new()
	trail_curve.set_bake_interval(0.1)
	trail_curve.clear_points()

func _init_cross_section_path():
	# If the path is empty, add two points to create a minimal valid trail
	# and give the user a visual clue in the editor
	if curve.get_point_count() == 0:
		curve.add_point(Vector3(0.0, 0.0, 0.0))
		curve.add_point(Vector3(0.0, 1.0, 0.0))
		curve.set_bake_interval(0.1)

func _process(delta):
	_update_trail_path(delta)
	_draw_geometry()

func _update_trail_path(delta):
	# Remove old points from the trail path
	for i in range(trail_curve.get_point_count() - 1, -1, -1):
		points[i].ttl -= delta
		if points[i].ttl <= 0:
			points.remove(i)
			trail_curve.remove_point(i)
			
	if not emit:
		return
	# Add a new point in the path at the current trail global position
	var p = Point.new()
	p.ttl = life_time
	p.basis = get_global_transform().basis
	points.push_back(p)
	trail_curve.add_point(to_global(curve.get_point_position(0)))

func _draw_geometry():
	
	if(trail_curve.get_point_count() < 1):
		return
	geometry.clear()
	
	var trail_count = round(trail_curve.get_baked_length() / trail_resolution) + 1
	var cross_count = round(curve.get_baked_length() / cross_section_resolution) + 1 
	
	var trail_pixel_length = trail_curve.get_baked_length()
	var cross_pixel_length = curve.get_baked_length()
	var c_origin = curve.get_point_position(0)
	
	#dnode.translation = c_origin + trail_curve.interpolate_baked(0.0)
	#dnode.look_at(points[0].normal, dnode.get_global_transform().basis.z)
		
	for i in range(trail_count):
		geometry.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, null)
		
		var pos = Vector3.ZERO
		var pos_offset = Vector3.ZERO
		var uv = Vector2.ZERO
		var uv_x_l = i / float(trail_count)
		var uv_x_r = (i + 1) / float(trail_count)
		
		var trail_pos_i = trail_curve.interpolate_baked((i/float(trail_count)) * trail_pixel_length)
		var trail_pos_i_1 = trail_curve.interpolate_baked(((i + 1)/float(trail_count)) * trail_pixel_length)
	
		var basis = points[i].basis

		for j in range(cross_count) :
			uv.x = 1 - uv_x_l
			uv.y = j / float(cross_count)
			
			var v1 =  curve.interpolate_baked((j / float(cross_count)) * cross_pixel_length) - c_origin
			pos = v1 + trail_pos_i
			_add_vertex(pos, uv)
		
			uv.x = 1 - uv_x_r
			v1 = curve.interpolate_baked((j / float(cross_count)) * cross_pixel_length) - c_origin
			pos = v1 + trail_pos_i_1
			_add_vertex(pos, uv)

		# Complete the current strip
		geometry.end()

func _add_vertex(pos, uv):
	# Handle uv options
	if flip_uv_x:
		uv.x = 1 - uv.x
	if flip_uv_y:
		uv.y = 1 - uv.y

	geometry.set_uv(uv)
	geometry.add_vertex(pos)
