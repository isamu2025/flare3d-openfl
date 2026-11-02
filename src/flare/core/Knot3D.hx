package flare.core;

import openfl.geom.Vector3D;

/**
 * Knot3D represents a control point on a 3D spline with incoming and outgoing tangent vectors.
 */
class Knot3D extends Vector3D {
    public var inVec:Vector3D;
    public var outVec:Vector3D;

    public function new(x:Float = 0, y:Float = 0, z:Float = 0, w:Float = 0) {
        super(x, y, z, w);
        inVec = new Vector3D();
        outVec = new Vector3D();
    }

    override public function clone():Vector3D {
        var k = new Knot3D(x, y, z, w);
        k.inVec = inVec.clone();
        k.outVec = outVec.clone();
        return k;
    }
}
