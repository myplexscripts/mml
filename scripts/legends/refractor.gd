extends RefCounted
## Canonical Legends-style Refractor: a long hexagonal crystal with pointed ends.

const COLOURS := {
 "red": Color("ff315f"),
 "pink": Color("ff4f8d"),
 "blue": Color("48b9ff"),
 "cyan": Color("61e7e1"),
 "green": Color("6ee98a"),
 "yellow": Color("ffd65b"),
 "purple": Color("b77cff"),
 "white": Color("e9fbff")
}

static func make(colour: Color=Color("ff315f"), height: float=1.6, radius: float=.28) -> Node3D:
 var root:=Node3D.new();root.name="Refractor"
 var mesh_instance:=MeshInstance3D.new();mesh_instance.name="Crystal"
 mesh_instance.mesh=_mesh(height,radius)
 var mat:=StandardMaterial3D.new()
 mat.albedo_color=Color(colour.r,colour.g,colour.b,.83)
 mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
 mat.shading_mode=BaseMaterial3D.SHADING_MODE_PER_VERTEX
 mat.roughness=.22;mat.metallic=.05
 mat.emission_enabled=true;mat.emission=colour*.36
 mat.cull_mode=BaseMaterial3D.CULL_DISABLED
 mesh_instance.material_override=mat;root.add_child(mesh_instance)

 # Bright inner core gives the PS1 refractor its layered glass look.
 var core:=MeshInstance3D.new();core.name="Core";core.mesh=_mesh(height*.72,radius*.47)
 var core_mat:=StandardMaterial3D.new();core_mat.albedo_color=Color(colour.r,colour.g,colour.b,.58)
 core_mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
 core_mat.emission_enabled=true;core_mat.emission=colour*.65;core_mat.roughness=.08
 core.material_override=core_mat;root.add_child(core)

 var light:=OmniLight3D.new();light.name="Glow";light.light_color=colour;light.light_energy=.45;light.omni_range=maxf(1.6,height*1.7);light.shadow_enabled=false;root.add_child(light)
 return root

static func make_variant(name: String, height: float=1.6, radius: float=.28) -> Node3D:
 return make(COLOURS.get(name.to_lower(),COLOURS.red),height,radius)

static func _mesh(height: float,radius: float) -> ArrayMesh:
 var vertices:=PackedVector3Array();var normals:=PackedVector3Array();var colours:=PackedColorArray();var indices:=PackedInt32Array()
 var half_body:=height*.34
 var tip:=height*.5
 var ring_top: Array[Vector3]=[];var ring_bottom: Array[Vector3]=[]
 for i in range(6):
  var angle:=TAU*float(i)/6.0
  ring_top.append(Vector3(cos(angle)*radius,half_body,sin(angle)*radius))
  ring_bottom.append(Vector3(cos(angle)*radius,-half_body,sin(angle)*radius))
 var top:=Vector3(0,tip,0);var bottom:=Vector3(0,-tip,0)

 # Separate vertices per face keep the strong faceted shading of the original.
 for i in range(6):
  var j: int=(i+1)%6
  _quad(vertices,normals,indices,ring_top[i],ring_bottom[i],ring_bottom[j],ring_top[j])
  _tri(vertices,normals,indices,top,ring_top[i],ring_top[j])
  _tri(vertices,normals,indices,bottom,ring_bottom[j],ring_bottom[i])
 var arrays:=[];arrays.resize(Mesh.ARRAY_MAX)
 arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_INDEX]=indices
 var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);return mesh

static func _quad(vertices: PackedVector3Array,normals: PackedVector3Array,indices: PackedInt32Array,a: Vector3,b: Vector3,c: Vector3,d: Vector3) -> void:
 var normal: Vector3=(b-a).cross(d-a).normalized();var base:=vertices.size()
 for v in [a,b,c,d]:vertices.append(v);normals.append(normal)
 for index in [0,1,2,0,2,3]:indices.append(base+index)

static func _tri(vertices: PackedVector3Array,normals: PackedVector3Array,indices: PackedInt32Array,a: Vector3,b: Vector3,c: Vector3) -> void:
 var normal: Vector3=(b-a).cross(c-a).normalized();var base:=vertices.size()
 for v in [a,b,c]:vertices.append(v);normals.append(normal)
 indices.append(base);indices.append(base+1);indices.append(base+2)
