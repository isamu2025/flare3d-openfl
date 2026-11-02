package flare.collisions;

import openfl.geom.Vector3D;
import flare.core.Pivot3D;

/**
 * BoxCollision provides Axis-Aligned Bounding Box (AABB) collision checks.
 */
class BoxCollision {
    public var min:Vector3D;
    public var max:Vector3D;
    public var target:Pivot3D;

    public function new(width:Float = 100, height:Float = 100, depth:Float = 100, target:Pivot3D = null) {
        this.target = target;
        var hw = width * 0.5;
        var hh = height * 0.5;
        var hd = depth * 0.5;
        this.min = new Vector3D(-hw, -hh, -hd);
        this.max = new Vector3D(hw, hh, hd);
    }

    public function contains(point:Vector3D):Bool {
        var origin = target != null ? new Vector3D(target.x, target.y, target.z) : new Vector3D(0, 0, 0);
        var p = new Vector3D(point.x - origin.x, point.y - origin.y, point.z - origin.z);
        return p.x >= min.x && p.x <= max.x &&
               p.y >= min.y && p.y <= max.y &&
               p.z >= min.z && p.z <= max.z;
    }
}
