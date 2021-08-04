tool
extends Spatial

# --
# ProtonTrail
# --
# This node generates a 3D trail at runtime
# Two nodes defines the width of the the trail. At each tick, the process
# function update the trail geometry, add new points if the latest ones
# are too far away from the previous ones, and remove the oldest points
# if they expired.
#
# --
# material : The material applied to the trail. UV coordinates are
#   defined as follow :
#   + The most recent points are at the left of the texture (0,0) and (0,1)
#   + The oldest points are at the right (1,0) and (1,1)
#   + That means the texture is stretch accross the entire trail
#
# invert_uv_x / y : Flip the UV coordinates on their respective axis
#
# smooth: 0 to disable. Smooth the previous geometry, useful if your emitter
#   moves too fast and produce a jagged trail
#
# resolution : The higher the value, the more vertices will be generated
#
# life_time : How long a point can exist in the trail.
#
# emit : True means the trail will keep creating new points. False means it
#   will only draw points still in memory and delete them, but wont create
#   new geometry.
# --

export var material: Material
export var resolution := 4.0
export var life_time = 0.1
export(float, 0.0, 1.0) var smooth = 0.5
export var invert_uv_x := false
export var invert_uv_y := false
export var cast_shadow := true
export var emit := true setget set_emit


var _geometry := ImmediateGeometry.new()
var _data := []
var _previous_data := []
var _max_dist: float

onready var _top: Spatial = get_node("Top")
onready var _bottom: Spatial = get_node("Bottom")


class Point:
	var ttl: float
	var p1: Vector3
	var p2: Vector3
	var n: Vector3


func _ready():
	if Engine.is_editor_hint():
		if not _top or not _bottom:
			_create_required_nodes()

	_geometry.set_name(get_name() + "Geometry")
	_geometry.set_material_override(material)
	_geometry.translation = Vector3(0.0, 0.0, 0.0)
	_geometry.cast_shadow = cast_shadow

	_max_dist = 1.0 / resolution


func _enter_tree() -> void:
	if _geometry and not _geometry.get_parent():
		get_tree().get_root().call_deferred("add_child", _geometry)


func _exit_tree() -> void:
	if _geometry and _geometry.get_parent():
		_geometry.get_parent().call_deferred("remove_child", _geometry)


func _process(delta : float):
	if not _top or not _bottom:
		if has_node("Top") and has_node("Bottom"):
			_top = get_node("Top")
			_bottom = get_node("Bottom")
		else:
			set_process(false)
			return

	_update_all_ttl(delta)
	_update_geometry()
	_draw_all_geometry()


func _update_all_ttl(delta: float) -> void:
	_update_ttl(_data, delta)
	var size := _previous_data.size()
	var index := 0
	for i in size:
		index = size - 1.0 - i
		_update_ttl(_previous_data[index], delta)
		if _previous_data[index].empty():
			_previous_data.pop_back()


func _update_ttl(data: Array, delta: float) -> void:
	var size = data.size()
	var index = 0
	for i in size:
		index = size - 1.0 - i
		data[index].ttl -= delta
		if data[index].ttl <= 0:
			data.pop_back()


func _update_geometry():
	if not emit:
		return

	if _data.size() <= 1:
		_add_single_point()
		return

	var top_pos := _top.get_global_transform().origin
	var bottom_pos := _bottom.get_global_transform().origin
	var dist_top: float = _data[1].p1.distance_to(top_pos)
	var dist_bottom: float = _data[1].p2.distance_to(bottom_pos)
	var dist = max(dist_top, dist_bottom)

	# Always keep the last point on the emitter position
	# if there's no need for new points
	if dist <= _max_dist:
		_data[0].p1 = top_pos
		_data[0].p2 = bottom_pos
	else:
		_add_points_to_trail(ceil(dist / _max_dist))

	_smooth_trail(_data)
	for data in _previous_data:
		_smooth_trail(data)


func _smooth_trail(data: Array) -> void:
	var a1: Vector3
	var a2: Vector3
	var b1: Vector3
	var b2: Vector3
	var c1: Vector3
	var c2: Vector3
	var mean1: Vector3
	var mean2: Vector3

	for i in data.size() - 1:
		if i == 0:
			continue

		a1 = data[i - 1].p1
		a2 = data[i - 1].p2
		b1 = data[i].p1
		b2 = data[i].p2
		c1 = data[i + 1].p1
		c2 = data[i + 1].p2

		mean1 = (a1 + c1) / 2.0
		mean2 = (a2 + c2) / 2.0
		data[i].p1 = b1.linear_interpolate(mean1, smooth)
		data[i].p2 = b2.linear_interpolate(mean2, smooth)
		data[i].n = (b1 - mean1).normalized()


func _add_points_to_trail(count: int):
	var top_start = _data[0].p1
	var top_end = _top.get_global_transform().origin
	var bottom_start = _data[0].p2
	var bottom_end = _bottom.get_global_transform().origin

	for i in count:
		var f: float = (i + 1.0) / (count)
		var p = Point.new()
		p.ttl = life_time
		p.p1 = top_start.linear_interpolate(top_end, f)
		p.p2 = bottom_start.linear_interpolate(bottom_end, f)
		_data.push_front(p)


func _add_single_point():
	var p = Point.new()
	p.ttl = life_time
	p.p1 = _top.get_global_transform().origin
	p.p2 = _bottom.get_global_transform().origin
	_data.push_front(p)


func _draw_all_geometry() -> void:
	_geometry.clear()
	_draw_geometry(_data)
	for d in _previous_data:
		_draw_geometry(d)


func _draw_geometry(data: Array):
	if data.size() <= 1:
		return

	var count := data.size()
	var uv_x := 0.0
	var uv_y_top := 1.0 if invert_uv_y else 0.0
	var uv_y_bottom := 0.0 if invert_uv_y else 1.0

	_geometry.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, null)

	var a: Vector3
	var b: Vector3
	var c: Vector3

	for i in count:
		uv_x = i / (count - 1.0)
		if invert_uv_x:
			uv_x = 1.0 - uv_x

		_geometry.set_normal(data[i].n)
		_geometry.set_uv(Vector2(uv_x, uv_y_top))
		_geometry.add_vertex(data[i].p1)

		_geometry.set_uv(Vector2(uv_x , uv_y_bottom))
		_geometry.add_vertex(data[i].p2)

	_geometry.end()


func _create_required_nodes():
	var owner = get_tree().get_edited_scene_root()
	_top = Position3D.new()
	_top.set_name("Top")
	add_child(_top)
	_top.translate(Vector3.UP)
	_top.set_owner(owner)

	_bottom = Position3D.new()
	_bottom.set_name("Bottom")
	add_child(_bottom)
	_bottom.translate(Vector3.DOWN)
	_bottom.set_owner(owner)


func set_emit(val: bool) -> void:
	if emit == val:
		return

	emit = val
	if not emit:
		_previous_data.push_front(_data.duplicate())
		_data.clear()
