package flare.utils;

import openfl.geom.Matrix3D;
import openfl.Vector;
import flare.core.Mesh3D;
import flare.core.Pivot3D;
import flare.core.Surface3D;
import flare.materials.Material3D;

/**
 * Utility functions for Mesh3D operations (merging, splitting, transforming).
 */
class Mesh3DUtils {
    public static function cloneMaterials(pivot:Pivot3D):Void {
        if (pivot == null) return;
        if (Std.isOfType(pivot, Mesh3D)) {
            cloneMaterialsAux(cast pivot);
        }
        for (child in pivot.children) {
            cloneMaterials(child);
        }
    }

    public static function cloneMaterialsAux(mesh:Mesh3D):Void {
        for (surf in mesh.surfaces) {
            if (surf.material != null) {
                // clone or re-assign
            }
        }
    }

    public static function merge(vector:Vector<Mesh3D>, removeOriginal:Bool = false, material:Material3D = null, includeChildren:Bool = false):Mesh3D {
        if (vector == null || vector.length == 0) return null;

        var merged = new Mesh3D("merged");
        var mergedSurf = new Surface3D("merged_surface");

        for (mesh in vector) {
            for (surf in mesh.surfaces) {
                Surface3DUtils.concat(surf, mergedSurf);
            }
            if (removeOriginal && mesh.parent != null) {
                mesh.parent.removeChild(mesh);
            }
        }

        merged.addSurface(mergedSurf, material != null ? material : (vector[0].surfaces.length > 0 ? vector[0].surfaces[0].material : null));
        return merged;
    }

    public static function split(mesh:Mesh3D):Void {
        // Splits multi-surface mesh into individual single-surface child meshes
        if (mesh == null || mesh.surfaces.length <= 1) return;
        var parent = mesh.parent;
        for (i in 1...mesh.surfaces.length) {
            var subMesh = new Mesh3D(mesh.name + "_part" + i);
            subMesh.transform = mesh.transform.clone();
            subMesh.addSurface(mesh.surfaces[i], mesh.surfaces[i].material);
            if (parent != null) parent.addChild(subMesh);
        }
        mesh.surfaces.splice(1, mesh.surfaces.length - 1);
    }

    public static function transform(mesh:Mesh3D, matrix:Matrix3D):Void {
        if (mesh == null || matrix == null) return;
        for (surf in mesh.surfaces) {
            Surface3DUtils.transform(surf, matrix);
        }
    }
}
