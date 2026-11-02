package flare.core;

import openfl.geom.Vector3D;

/**
 * The Boundings3D class contains dimensional bounding information (AABB and bounding sphere) for 3D objects.
 */
class Boundings3D {
    public var center:Vector3D;
    public var length:Vector3D;
    public var max:Vector3D;
    public var min:Vector3D;
    public var radius:Float = 0;

    public function new() {
        center = new Vector3D();
        length = new Vector3D();
        max = new Vector3D();
        min = new Vector3D();
        reset();
    }

    public function reset():Void {
        min.setTo(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY);
        max.setTo(Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY);
        center.setTo(0, 0, 0);
        length.setTo(0, 0, 0);
        radius = 0;
    }

    public function clone():Boundings3D {
        var b = new Boundings3D();
        b.center = center.clone();
        b.length = length.clone();
        b.max = max.clone();
        b.min = min.clone();
        b.radius = radius;
        return b;
    }

    public function update(minX:Float, minY:Float, minZ:Float, maxX:Float, maxY:Float, maxZ:Float):Void {
        min.setTo(minX, minY, minZ);
        max.setTo(maxX, maxY, maxZ);
        length.setTo(maxX - minX, maxY - minY, maxZ - minZ);
        center.setTo((minX + maxX) * 0.5, (minY + maxY) * 0.5, (minZ + maxZ) * 0.5);
        var dx = length.x * 0.5;
        var dy = length.y * 0.5;
        var dz = length.z * 0.5;
        radius = Math.sqrt(dx * dx + dy * dy + dz * dz);
    }

    public function toString():String {
        return "[Boundings3D min=" + min + ", max=" + max + ", center=" + center + ", radius=" + radius + "]";
    }
}
