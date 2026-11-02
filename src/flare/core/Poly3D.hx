package flare.core;

import openfl.geom.Point;
import openfl.geom.Vector3D;

/**
 * Poly3D represents a 3D triangle polygon with vertices, UV coordinates, and normal vector.
 */
class Poly3D {
    public var v0:Vector3D;
    public var v1:Vector3D;
    public var v2:Vector3D;
    public var uv0:Point;
    public var uv1:Point;
    public var uv2:Point;
    public var normal:Vector3D;

    public function new(v0:Vector3D, v1:Vector3D, v2:Vector3D, uv0:Point = null, uv1:Point = null, uv2:Point = null) {
        this.v0 = v0 != null ? v0.clone() : new Vector3D();
        this.v1 = v1 != null ? v1.clone() : new Vector3D();
        this.v2 = v2 != null ? v2.clone() : new Vector3D();
        this.uv0 = uv0 != null ? uv0.clone() : new Point();
        this.uv1 = uv1 != null ? uv1.clone() : new Point();
        this.uv2 = uv2 != null ? uv2.clone() : new Point();
        this.normal = new Vector3D();
        calculateNormal();
    }

    public function calculateNormal():Void {
        var e1x = v1.x - v0.x;
        var e1y = v1.y - v0.y;
        var e1z = v1.z - v0.z;

        var e2x = v2.x - v0.x;
        var e2y = v2.y - v0.y;
        var e2z = v2.z - v0.z;

        normal.x = e1y * e2z - e1z * e2y;
        normal.y = e1z * e2x - e1x * e2z;
        normal.z = e1x * e2y - e1y * e2x;
        normal.normalize();
    }

    public function closetPoint(p:Vector3D, out:Vector3D):Void {
        if (out == null) return;
        // Project p onto triangle plane
        var diffX = p.x - v0.x;
        var diffY = p.y - v0.y;
        var diffZ = p.z - v0.z;
        var dist = diffX * normal.x + diffY * normal.y + diffZ * normal.z;
        out.x = p.x - normal.x * dist;
        out.y = p.y - normal.y * dist;
        out.z = p.z - normal.z * dist;
    }

    public function closetPointOnLine(a:Vector3D, b:Vector3D, p:Vector3D, out:Vector3D):Void {
        var abx = b.x - a.x;
        var aby = b.y - a.y;
        var abz = b.z - a.z;
        var apx = p.x - a.x;
        var apy = p.y - a.y;
        var apz = p.z - a.z;
        var lenSq = abx * abx + aby * aby + abz * abz;
        if (lenSq == 0) {
            out.copyFrom(a);
            return;
        }
        var t = (apx * abx + apy * aby + apz * abz) / lenSq;
        if (t < 0) t = 0;
        else if (t > 1) t = 1;
        out.x = a.x + abx * t;
        out.y = a.y + aby * t;
        out.z = a.z + abz * t;
    }
}
