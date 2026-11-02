package flare.core;

import openfl.geom.Vector3D;
import openfl.Vector;

/**
 * Spline3D represents a 3D parametric spline formed by Knot3D control points.
 */
class Spline3D {
    public var knots:Vector<Knot3D>;
    public var closed:Bool = false;
    public var segments:Int = 10;

    public function new() {
        knots = new Vector<Knot3D>();
    }

    public function clone():Spline3D {
        var s = new Spline3D();
        s.closed = closed;
        s.segments = segments;
        for (k in knots) {
            s.knots.push(cast k.clone());
        }
        return s;
    }

    public function getPoint(value:Float, out:Vector3D = null):Vector3D {
        if (out == null) out = new Vector3D();
        if (knots == null || knots.length == 0) return out;
        if (knots.length == 1) {
            out.copyFrom(knots[0]);
            return out;
        }

        var numSegments = closed ? knots.length : (knots.length > 1 ? knots.length - 1 : 1);
        var v = (value < 0) ? 0.0 : ((value > 1.0) ? 1.0 : value);
        var t = v * numSegments;
        var idx = Math.floor(t);
        if (idx >= numSegments) {
            idx = numSegments - 1;
        }
        var u = t - idx;

        var p0 = knots[idx];
        var p1 = knots[(idx + 1) % knots.length];

        // Cubic Hermite / Bezier interpolation using tangent handles
        var c0 = (1.0 - u) * (1.0 - u) * (1.0 - u);
        var c1 = 3.0 * (1.0 - u) * (1.0 - u) * u;
        var c2 = 3.0 * (1.0 - u) * u * u;
        var c3 = u * u * u;

        var h0x = p0.x + p0.outVec.x;
        var h0y = p0.y + p0.outVec.y;
        var h0z = p0.z + p0.outVec.z;

        var h1x = p1.x + p1.inVec.x;
        var h1y = p1.y + p1.inVec.y;
        var h1z = p1.z + p1.inVec.z;

        out.x = c0 * p0.x + c1 * h0x + c2 * h1x + c3 * p1.x;
        out.y = c0 * p0.y + c1 * h0y + c2 * h1y + c3 * p1.y;
        out.z = c0 * p0.z + c1 * h0z + c2 * h1z + c3 * p1.z;

        return out;
    }

    public function getTangent(value:Float, out:Vector3D = null):Vector3D {
        if (out == null) out = new Vector3D();
        var delta = 0.001;
        var p0 = getPoint(value);
        var p1 = getPoint(value + delta);
        out.x = p1.x - p0.x;
        out.y = p1.y - p0.y;
        out.z = p1.z - p0.z;
        out.normalize();
        return out;
    }
}
