extends Node3D
## Simple drift practice track: a skidpad — two concentric rings of cones
## marking a circular lane to hold a sustained drift / do donuts around.
## Cones are visual-only markers (no collision), generated in code.

@export var inner_radius: float = 6.0
@export var outer_radius: float = 10.0
@export var cone_spacing: float = 2.2   # approx meters between cones
@export var cone_color: Color = Color(0.95, 0.45, 0.1)


func _ready() -> void:
	_ring(inner_radius)
	_ring(outer_radius)


func _ring(radius: float) -> void:
	var count := maxi(6, int(round(TAU * radius / cone_spacing)))
	for i in count:
		var a := TAU * float(i) / float(count)
		var cone := _make_cone()
		add_child(cone)
		cone.position = Vector3(cos(a) * radius, 0.25, sin(a) * radius)


func _make_cone() -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.02
	mesh.bottom_radius = 0.16
	mesh.height = 0.5
	m.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = cone_color
	m.material_override = mat
	return m
