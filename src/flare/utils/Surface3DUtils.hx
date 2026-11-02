package flare.utils;

import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import openfl.Vector;
import flare.core.Poly3D;
import flare.core.Surface3D;

/**
 * Utility functions for Surface3D operations (geometry transformations, normal flipping, poly generation).
 */
class Surface3DUtils {
    public static function buildPolys(surface:Surface3D, force:Bool = false):Vector<Poly3D> {
        var polys = new Vector<Poly3D>();
        if (surface == null) return polys;

        var v = surface.vertexData;
        var idx = surface.indexData;
        var numTris = Std.int(idx.length / 3);

        for (i in 0...numTris) {
            var i0 = idx[i * 3] * 8;
            var i1 = idx[i * 3 + 1] * 8;
            var i2 = idx[i * 3 + 2] * 8;

            var v0 = new Vector3D(v[i0], v[i0 + 1], v[i0 + 2]);
            var v1 = new Vector3D(v[i1], v[i1 + 1], v[i1 + 2]);
            var v2 = new Vector3D(v[i2], v[i2 + 1], v[i2 + 2]);

            polys.push(new Poly3D(v0, v1, v2));
        }

        return polys;
    }

    public static function buildTangentsAndBitangents(surface:Surface3D):Void {}

    public static function compress(surf:Surface3D, vertex:Vector<Float>, indices:Vector<UInt>):Void {
        if (surf == null) return;
        surf.vertexVector = vertex;
        surf.indexVector = indices;
    }

    public static function concat(source:Surface3D, dest:Surface3D):Void {
        if (source == null || dest == null) return;

        var baseIdx = Std.int(dest.vertexData.length / 8);
        for (i in 0...source.vertexData.length) {
            dest.vertexData.push(source.vertexData[i]);
        }
        for (i in 0...source.indexData.length) {
            dest.indexData.push(source.indexData[i] + baseIdx);
        }
    }

    public static function flipNormals(surface:Surface3D):Void {
        if (surface == null) return;
        var v = surface.vertexData;
        var len = v.length;
        var i = 0;
        while (i < len) {
            v[i + 3] = -v[i + 3]; // nx
            v[i + 4] = -v[i + 4]; // ny
            v[i + 5] = -v[i + 5]; // nz
            i += 8;
        }

        // Reverse winding order
        var idx = surface.indexData;
        var numTris = Std.int(idx.length / 3);
        for (t in 0...numTris) {
            var tmp = idx[t * 3 + 1];
            idx[t * 3 + 1] = idx[t * 3 + 2];
            idx[t * 3 + 2] = tmp;
        }
    }

    public static function transform(surface:Surface3D, matrix:Matrix3D, firstIndex:Int = 0, numTriangles:Int = -1):Void {
        if (surface == null || matrix == null) return;
        var v = surface.vertexData;
        var len = v.length;
        var pos = new Vector3D();
        var nor = new Vector3D();

        var i = 0;
        while (i < len) {
            pos.setTo(v[i], v[i + 1], v[i + 2]);
            pos = matrix.transformVector(pos);
            v[i] = pos.x;
            v[i + 1] = pos.y;
            v[i + 2] = pos.z;

            nor.setTo(v[i + 3], v[i + 4], v[i + 5]);
            nor = matrix.deltaTransformVector(nor);
            nor.normalize();
            v[i + 3] = nor.x;
            v[i + 4] = nor.y;
            v[i + 5] = nor.z;

            i += 8;
        }
    }
}
