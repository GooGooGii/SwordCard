"""Small PAL1 silhouette weapons; independent of character surface baking."""
import bpy
from mathutils import Matrix, Vector


def build_pal_weapon(rig, kind, length, height):
    grip = rig.data.bones['weapon'].head_local.copy()
    parts = []

    def finish(obj, name, color, metal=0.0):
        obj.name = name
        mat = bpy.data.materials.new(name + 'Material')
        mat.diffuse_color = (*color, 1.0)
        mat.use_nodes = True
        shader = mat.node_tree.nodes.get('Principled BSDF')
        shader.inputs['Base Color'].default_value = (*color, 1.0)
        shader.inputs['Metallic'].default_value = metal
        shader.inputs['Roughness'].default_value = 0.32 if metal else 0.6
        obj.data.materials.append(mat)
        parts.append(obj)
        return obj

    def cylinder(name, radius, depth, z, color, metal=0.0):
        bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=radius * height,
            depth=depth * height, location=grip + Vector((0, 0, z * height)))
        return finish(bpy.context.object, name, color, metal)

    bronze = (0.52, 0.33, 0.09)
    if kind == 'staff':
        cylinder('StaffShaft', .009, length, length * .23, (.22, .12, .055))
        cylinder('StaffCollar', .016, .05, length * .71, bronze, .65)
        # Original green staff head: compact jade point in a gold cradle.
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=.04 * height,
            location=grip + Vector((0, 0, length * .78 * height)))
        obj = bpy.context.object
        obj.scale = (.7, .55, 1.4)
        finish(obj, 'JadeStaffHead', (.09, .40, .21), .18)
    else:
        cylinder('WrappedGrip', .010, .07, 0, (.08, .045, .025))
        cylinder('Pommel', .014, .02, .042, bronze, .65)
        bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=6,
            radius=.02 * height, location=grip + Vector((0, 0, -.045 * height)))
        obj = bpy.context.object
        obj.scale = (2.3, .55, .35)
        finish(obj, 'Guard', bronze, .65)
        # Diamond cross-section and a real point, rather than a rectangular slab.
        vertices = []
        sections = [(-.052, .012, 0), (-length * .74, .010, .006 if kind == 'dao' else 0),
                    (-length * .91, .007, .020 if kind == 'dao' else 0)]
        for z, half_width, curve in sections:
            for x, y in [(-half_width, 0), (0, -.003), (half_width, 0), (0, .003)]:
                vertices.append(tuple(grip + Vector(((x + curve) * height, y * height, z * height))))
        vertices.append(tuple(grip + Vector(((.035 if kind == 'dao' else 0) * height, 0, -length * height))))
        faces = [(3, 2, 1, 0)]
        for ring in range(2):
            for side in range(4):
                a = ring * 4 + side
                b = ring * 4 + (side + 1) % 4
                faces.append((a, b, b + 4, a + 4))
        faces.extend((8 + i, 8 + (i + 1) % 4, 12) for i in range(4))
        mesh = bpy.data.meshes.new('PointedBladeMesh')
        mesh.from_pydata(vertices, [], faces)
        mesh.update()
        obj = bpy.data.objects.new('PointedBlade', mesh)
        bpy.context.collection.objects.link(obj)
        finish(obj, 'PointedBlade', (.63, .71, .77), .8)

    bpy.ops.object.select_all(action='DESELECT')
    for obj in parts:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    weapon = bpy.context.object
    weapon.name = 'Weapon'
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bone = rig.data.bones['weapon']
    weapon.parent = rig
    weapon.parent_type = 'BONE'
    weapon.parent_bone = 'weapon'
    weapon.matrix_parent_inverse = (rig.matrix_world @ bone.matrix_local @
        Matrix.Translation((0, bone.length, 0))).inverted()
    return weapon
