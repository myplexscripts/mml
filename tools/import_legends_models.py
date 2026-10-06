"""Run with Blender 4.0+: blender --background --python tools/import_legends_models.py -- /path/to/extracted/packs
Prepare PSD composites first with tools/prepare_legends_sources.py. See docs/ASSETS.md.
"""
import bpy,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
args=sys.argv[sys.argv.index('--')+1:]
SOURCE=Path(args[0]).resolve()

# city-convert.py
import bpy,os,sys,json
from pathlib import Path
from mathutils import Vector
root=SOURCE/'Teomo City Set'
out=ROOT/'assets/scenery';out.mkdir(parents=True,exist_ok=True)
assets=[
 ('tree','Tree/tree.blend',{'Material.002':'barkuvTEXTURE.png','Material.001':'treeuvTEXTURE.png'}),
 ('lamp','Props/Lamp/lamp.blend',{'Material.001':'lampTEXTURE.png'}),
 ('shed','Shed/waiting shed.blend',{'Material':'waiting shed uv TEXTURE.png'}),
 ('harbour','Buildings/Dock/harbor.blend',{'Front_Back':'front_back.png','Sides':'sides.png'}),
 ('bakery','Buildings/2/Building_Bakery.blend',{'Main_Front':'textures/bakery.png','Main_Side':'textures/bakery side.png','Main_Top':'textures/bakery top.png','Main_Back':'textures/bakery back.png'}),
 ('boat','Props/Boat/boat.blend',{f'Material.00{i}':f'boat{i}TEXTURE.png' for i in range(1,5)}),
]
for key,src,mapping in assets:
 p=root/src;bpy.ops.wm.open_mainfile(filepath=str(p));bpy.context.scene.frame_set(1)
 for o in list(bpy.data.objects):
  if o.type!='MESH' or not o.data.polygons:bpy.data.objects.remove(o,do_unlink=True)
 for mat in bpy.data.materials:
  mat.use_nodes=True;mat.node_tree.nodes.clear();nodes=mat.node_tree.nodes
  bs=nodes.new('ShaderNodeBsdfPrincipled');bs.inputs['Roughness'].default_value=.95;bs.inputs['Metallic'].default_value=0
  target=nodes.new('ShaderNodeOutputMaterial');mat.node_tree.links.new(bs.outputs['BSDF'],target.inputs['Surface'])
  bs.inputs['Base Color'].default_value=(.45,.38,.28,1)
  if mat.name in mapping:
   imagep=p.parent/mapping[mat.name]
   if imagep.suffix=='.psd':imagep=imagep.with_suffix('.png')
   im=bpy.data.images.load(str(imagep),check_existing=True);tex=nodes.new('ShaderNodeTexImage');tex.image=im;tex.interpolation='Closest'
   mat.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color'])
   if key=='tree' and mat.name=='Material.001':
    mat.node_tree.links.new(tex.outputs['Alpha'],bs.inputs['Alpha']);mat.blend_method='CLIP';mat.alpha_threshold=.45
  mat.use_backface_culling=False
 bpy.ops.object.select_all(action='SELECT')
 bpy.context.view_layer.objects.active=next(o for o in bpy.data.objects if o.type=='MESH')
 bpy.ops.object.join()
 bpy.ops.export_scene.gltf(filepath=str(out/(key+'.glb')),export_format='GLB',use_selection=True,export_animations=False,export_apply=True)
 print('EXPORTED',key)

# josh-convert.py
import bpy
from pathlib import Path
out=ROOT/'assets/scenery'
# Main authored mesh and the small mesh bound to its rig; exclude the duplicate prototype and control shapes.
p=SOURCE/'josh/MMV3.blend';bpy.ops.wm.open_mainfile(filepath=str(p))
bpy.context.view_layer.objects.active=bpy.data.objects['Armature']
if bpy.context.object.mode!='OBJECT':bpy.ops.object.mode_set(mode='OBJECT')
keep={'Armature','Megaman Volnutt','Cylinder.003'}
for o in list(bpy.data.objects):
 if o.name not in keep:bpy.data.objects.remove(o,do_unlink=True)
rig=bpy.data.objects['Armature'];rig.animation_data.action=bpy.data.actions['CircularGait']
for t in rig.animation_data.nla_tracks:t.mute=True
for o in bpy.data.objects:
 if o.type=='MESH' and o.animation_data:o.animation_data_clear()
mat=bpy.data.materials['Material'];mat.use_nodes=True;mat.node_tree.nodes.clear();n=mat.node_tree.nodes
bs=n.new('ShaderNodeBsdfPrincipled');bs.inputs['Roughness'].default_value=.95
tex=n.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(SOURCE/'josh/MMV3.png'));tex.interpolation='Closest'
uv=n.new('ShaderNodeUVMap');uv.uv_map='MegaMap2';mat.node_tree.links.new(uv.outputs['UV'],tex.inputs['Vector'])
mat.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color']);output=n.new('ShaderNodeOutputMaterial');mat.node_tree.links.new(bs.outputs['BSDF'],output.inputs['Surface'])
# Preserve the author's run cycle; provide a quiet grounded pose for dialogue and menus.
from mathutils import Vector,Quaternion
run=bpy.data.actions['CircularGait'];run.name='Run'
for action in list(bpy.data.actions):
 if action!=run:bpy.data.actions.remove(action)
idle=bpy.data.actions.new('Idle');rig.animation_data.action=idle
for bone in rig.pose.bones:
 bone.rotation_mode='QUATERNION';bone.rotation_quaternion=Quaternion();bone.location=Vector((0,0,0));bone.scale=Vector((1,1,1))
for name in ['Bicep.l','Bicep.r']:
 bone=rig.pose.bones[name];basis=bone.bone.matrix_local.to_quaternion()
 direction=(bone.bone.tail_local-bone.bone.head_local).normalized()
 target=Vector((.12 if name.endswith('.l') else -.12,-.12,-1)).normalized()
 bone.rotation_quaternion=basis.inverted()@direction.rotation_difference(target)@basis
for frame in [1,45]:
 for bone in rig.pose.bones:
  bone.keyframe_insert('rotation_quaternion',frame=frame,group=bone.name)
  bone.keyframe_insert('location',frame=frame,group=bone.name)
  bone.keyframe_insert('scale',frame=frame,group=bone.name)
bpy.context.scene.frame_start=1;bpy.context.scene.frame_end=45;bpy.context.scene.frame_set(1)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=str(out/'volnutt.glb'),export_format='GLB',use_selection=True,export_animations=True,export_nla_strips=False,export_frame_range=False,export_apply=True)
print('EXPORTED volnutt')

# fbx-convert.py
import bpy
from pathlib import Path
root=ROOT/'assets/models'
for key in ['flutter','container','drache']:
 bpy.ops.wm.read_factory_settings(use_empty=True)
 p=root/key;bpy.ops.import_scene.fbx(filepath=str(p/'model.fbx'))
 im=bpy.data.images.load(str(next(f for f in (p/'tex').iterdir() if f.suffix.lower()=='.png')))
 for mat in bpy.data.materials:
  mat.use_nodes=True;mat.node_tree.nodes.clear();n=mat.node_tree.nodes
  bs=n.new('ShaderNodeBsdfPrincipled');bs.inputs['Roughness'].default_value=1
  tex=n.new('ShaderNodeTexImage');tex.image=im;tex.interpolation='Closest'
  mat.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color']);output=n.new('ShaderNodeOutputMaterial');mat.node_tree.links.new(bs.outputs['BSDF'],output.inputs['Surface'])
 bpy.context.view_layer.update()
 deps=bpy.context.evaluated_depsgraph_get()
 baked=[]
 for o in list(bpy.data.objects):
  if o.type=='MESH':
   mesh=bpy.data.meshes.new_from_object(o.evaluated_get(deps),preserve_all_data_layers=True,depsgraph=deps)
   obj=bpy.data.objects.new(o.name+'Baked',mesh);bpy.context.collection.objects.link(obj);obj.matrix_world=o.matrix_world.copy();baked.append(obj)
 for o in list(bpy.data.objects):
  if o not in baked:bpy.data.objects.remove(o,do_unlink=True)
 bpy.ops.export_scene.gltf(filepath=str(p/'model.glb'),export_format='GLB',export_animations=False,export_apply=True)
 print('CONVERT',key)

# buster-convert.py
import bpy
from mathutils import Matrix,Vector
from pathlib import Path
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(ROOT/'assets/models/megaman/model.glb'))
o=bpy.data.objects['BusterGun'];deps=bpy.context.evaluated_depsgraph_get()
mesh=bpy.data.meshes.new_from_object(o.evaluated_get(deps),preserve_all_data_layers=True,depsgraph=deps)
coords=[o.matrix_world@v.co for v in mesh.vertices]
centre=(Vector((min(v.x for v in coords),min(v.y for v in coords),min(v.z for v in coords)))+Vector((max(v.x for v in coords),max(v.y for v in coords),max(v.z for v in coords))))/2
size=Vector((max(v.x for v in coords)-min(v.x for v in coords),max(v.y for v in coords)-min(v.y for v in coords),max(v.z for v in coords)-min(v.z for v in coords)))
print('GUN',centre,size)
axis=max(range(3),key=lambda i:size[i]);direction=Vector((1 if axis==0 else 0,1 if axis==1 else 0,1 if axis==2 else 0));rot=direction.rotation_difference(Vector((0,0,1)))
for v,c in zip(mesh.vertices,coords):v.co=rot@(c-centre)
for other in list(bpy.data.objects):bpy.data.objects.remove(other,do_unlink=True)
obj=bpy.data.objects.new('Buster',mesh);bpy.context.collection.objects.link(obj)
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/scenery/buster.glb'),export_format='GLB',export_animations=False)

# hangar-convert.py
import bpy,bmesh
from mathutils import Vector
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(ROOT/'assets/scenery/harbour.glb'))
meshes=[o for o in bpy.data.objects if o.type=='MESH']
bpy.ops.object.select_all(action='DESELECT')
for o in meshes:o.select_set(True)
bpy.context.view_layer.objects.active=meshes[0];bpy.ops.object.join();o=bpy.context.object
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
bm=bmesh.new();bm.from_mesh(o.data)
r=bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.00001,plane_co=(3.5,0,0),plane_no=(1,0,0),clear_inner=True)
cut=[e for e in bm.edges if e.is_boundary and all(abs(v.co.x-3.5)<.001 for v in e.verts)]
filled=bmesh.ops.holes_fill(bm,edges=cut,sides=0)['faces']
side=next((i for i,m in enumerate(o.data.materials) if m.name=='Sides'),0)
uv=bm.loops.layers.uv.active
for face in filled:
 face.material_index=side
 for loop in face.loops:loop[uv].uv=((loop.vert.co.y+1.8)/3.6,loop.vert.co.z/5.4)
bm.to_mesh(o.data);bm.free()
for mat in o.data.materials:
 if mat.name in ['LOL','Chimney']:
  mat.diffuse_color=(.27,.34,.35,1)
  bs=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED');bs.inputs['Base Color'].default_value=(.27,.34,.35,1)
  tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(ROOT/'assets/legends/cabin_metal.png'));tex.interpolation='Closest';mat.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color'])
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/scenery/hangar.glb'),export_format='GLB',use_selection=True,export_animations=False)
