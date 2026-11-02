package flare.physics.geom;

import openfl.geom.Vector3D;
import flare.materials.Material3D;
import flare.physics.IShape;

/**
 * Triangle represents a 3D polygon face for mesh collisions.
 */
class Triangle implements IShape {
    public var v0:Vertex;
    public var v1:Vertex;
    public var v2:Vertex;
    public var e0:Edge;
    public var e1:Edge;
    public var e2:Edge;
    public var n:Vector3D;
    public var material:Material3D;

    public function new(v0:Vertex = null, v1:Vertex = null, v2:Vertex = null) {
        this.v0 = v0;
        this.v1 = v1;
        this.v2 = v2;
        this.n = new Vector3D();
        this.e0 = new Edge(v0, v1);
        this.e1 = new Edge(v1, v2);
        this.e2 = new Edge(v2, v0);
        e0.tri = this;
        e1.tri = this;
        e2.tri = this;
        calculateNormal();
    }

    public function calculateNormal():Void {
        if (v0 == null || v1 == null || v2 == null) return;
        var ax = v1.x - v0.x;
        var ay = v1.y - v0.y;
        var az = v1.z - v0.z;
        var bx = v2.x - v0.x;
        var by = v2.y - v0.y;
        var bz = v2.z - v0.z;

        n.x = ay * bz - az * by;
        n.y = az * bx - ax * bz;
        n.z = ax * by - ay * bx;
        n.normalize();
    }

    public function closetPoint(p:Vector3D, out:Vector3D):Void {
        if (out == null || v0 == null) return;
        var diffX = p.x - v0.x;
        var diffY = p.y - v0.y;
        var diffZ = p.z - v0.z;
        var dist = diffX * n.x + diffY * n.y + diffZ * n.z;
        out.x = p.x - n.x * dist;
        out.y = p.y - n.y * dist;
        out.z = p.z - n.z * dist;
    }

    public function getSupportPoints(dir:Vector3D, out:Vector3D):Void {
        if (out == null || v0 == null) return;
        var d0 = v0.x * dir.x + v0.y * dir.y + v0.z * dir.z;
        var d1 = v1.x * dir.x + v1.y * dir.y + v1.z * dir.z;
        var d2 = v2.x * dir.x + v2.y * dir.y + v2.z * dir.z;

        if (d0 >= d1 && d0 >= d2) {
            out.copyFrom(v0);
        } else if (d1 >= d0 && d1 >= d2) {
            out.copyFrom(v1);
        } else {
            out.copyFrom(v2);
        }
    }

    public function isPoint():Bool return false;

    public function project(axis:Vector3D, out:Vector3D):Void {
        if (out == null || v0 == null) return;
        var d0 = v0.x * axis.x + v0.y * axis.y + v0.z * axis.z;
        var d1 = v1.x * axis.x + v1.y * axis.y + v1.z * axis.z;
        var d2 = v2.x * axis.x + v2.y * axis.y + v2.z * axis.z;

        var minD = Math.min(d0, Math.min(d1, d2));
        var maxD = Math.max(d0, Math.max(d1, d2));
        out.x = minD;
        out.y = maxD;
    }
}
