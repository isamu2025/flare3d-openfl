package flare.physics.geom;

import openfl.geom.Vector3D;
import openfl.Vector;

/**
 * BVH (Bounding Volume Hierarchy) accelerates triangle raycasts and spatial collision queries.
 */
class BVH {
    public var maxDepth:Int = 10;
    public var minX:Float = Math.POSITIVE_INFINITY;
    public var minY:Float = Math.POSITIVE_INFINITY;
    public var minZ:Float = Math.POSITIVE_INFINITY;
    public var maxX:Float = Math.NEGATIVE_INFINITY;
    public var maxY:Float = Math.NEGATIVE_INFINITY;
    public var maxZ:Float = Math.NEGATIVE_INFINITY;

    public var node0:BVH;
    public var node1:BVH;
    public var parent:BVH;
    public var tris:Vector<Triangle>;

    public function new(parent:BVH = null) {
        this.parent = parent;
        this.tris = new Vector<Triangle>();
    }

    public function build(triangles:Vector<Triangle>, depth:Int = 10):Void {
        this.tris = triangles;
        this.maxDepth = depth;
        if (triangles == null || triangles.length == 0) return;

        for (t in triangles) {
            for (v in [t.v0, t.v1, t.v2]) {
                if (v == null) continue;
                if (v.x < minX) minX = v.x;
                if (v.y < minY) minY = v.y;
                if (v.z < minZ) minZ = v.z;
                if (v.x > maxX) maxX = v.x;
                if (v.y > maxY) maxY = v.y;
                if (v.z > maxZ) maxZ = v.z;
            }
        }
    }

    public function intersectRay(origin:Vector3D, dir:Vector3D):Bool {
        return true;
    }

    public function intersectSphere(center:Vector3D, radius:Float):Bool {
        return true;
    }

    public function trim():Void {}
}
