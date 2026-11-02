package flare.core;

import openfl.geom.Vector3D;

/**
 * Shape3D represents a 3D vector spline curve or path.
 */
class Shape3D extends Pivot3D {
    public var bounds:Dynamic;
    public var color:Dynamic;
    public var splines:Array<Spline3D>;

    public function new(name:String = "") {
        super(name);
        this.splines = [];
    }

    public function getPoint(a:Dynamic, b:Dynamic = null, out:Vector3D = null):Vector3D {
        if (out == null) out = new Vector3D();
        if (splines == null || splines.length == 0) return out;

        var segment:Int = 0;
        var t:Float = 0;
        if (b != null && !Std.isOfType(b, Vector3D)) {
            segment = Std.int(a);
            t = cast b;
        } else {
            segment = 0;
            t = cast a;
            if (Std.isOfType(b, Vector3D)) {
                out = cast b;
            }
        }

        if (segment < 0) segment = 0;
        if (segment >= splines.length) segment = splines.length - 1;

        return splines[segment].getPoint(t, out);
    }

    public function getTangent(a:Dynamic, b:Dynamic = null, out:Vector3D = null):Vector3D {
        if (out == null) out = new Vector3D(0, 0, 1);
        if (splines == null || splines.length == 0) return out;

        var segment:Int = 0;
        var t:Float = 0;
        if (b != null && !Std.isOfType(b, Vector3D)) {
            segment = Std.int(a);
            t = cast b;
        } else {
            segment = 0;
            t = cast a;
            if (Std.isOfType(b, Vector3D)) {
                out = cast b;
            }
        }

        if (segment < 0) segment = 0;
        if (segment >= splines.length) segment = splines.length - 1;

        return splines[segment].getTangent(t, out);
    }

    public function updateBoundings():Void {}

    override public function clone():Pivot3D {
        var s = new Shape3D(name);
        s.splines = this.splines.copy();
        return s;
    }
}
