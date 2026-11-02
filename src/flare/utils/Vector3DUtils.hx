package flare.utils;

import openfl.geom.Vector3D;

/**
 * Vector3DUtils provides 3D vector math routines and standard basis vectors.
 */
class Vector3DUtils {
    public static var UP:Vector3D = new Vector3D(0, 1, 0);
    public static var DOWN:Vector3D = new Vector3D(0, -1, 0);
    public static var LEFT:Vector3D = new Vector3D(-1, 0, 0);
    public static var RIGHT:Vector3D = new Vector3D(1, 0, 0);
    public static var FORWARD:Vector3D = new Vector3D(0, 0, 1);
    public static var BACK:Vector3D = new Vector3D(0, 0, -1);
    public static var ZERO:Vector3D = new Vector3D(0, 0, 0);
    public static var ONE:Vector3D = new Vector3D(1, 1, 1);

    public static function random(min:Float = -1, max:Float = 1, out:Vector3D = null):Vector3D {
        if (out == null) out = new Vector3D();
        var d = max - min;
        out.x = min + Math.random() * d;
        out.y = min + Math.random() * d;
        out.z = min + Math.random() * d;
        return out;
    }

    public static function interpolate(a:Vector3D, b:Vector3D, f:Float, out:Vector3D = null):Vector3D {
        if (out == null) out = new Vector3D();
        out.x = a.x + (b.x - a.x) * f;
        out.y = a.y + (b.y - a.y) * f;
        out.z = a.z + (b.z - a.z) * f;
        return out;
    }

    public static function add(a:Vector3D, b:Vector3D, out:Vector3D = null):Vector3D {
        if (out == null) out = new Vector3D();
        out.x = a.x + b.x;
        out.y = a.y + b.y;
        out.z = a.z + b.z;
        return out;
    }

    public static function sub(a:Vector3D, b:Vector3D, out:Vector3D = null):Vector3D {
        if (out == null) out = new Vector3D();
        out.x = a.x - b.x;
        out.y = a.y - b.y;
        out.z = a.z - b.z;
        return out;
    }

    public static function negate(a:Vector3D, out:Vector3D = null):Vector3D {
        if (out == null) out = new Vector3D();
        out.x = -a.x;
        out.y = -a.y;
        out.z = -a.z;
        return out;
    }
}
