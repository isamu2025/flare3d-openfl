package flare.collisions;

import openfl.geom.Vector3D;
import flare.core.Mesh3D;
import flare.core.Surface3D;

/**
 * CollisionInfo provides detailed intersection metrics and barycentric coordinates for 3D picking/raycasting.
 */
class CollisionInfo {
    public var point:Vector3D;
    public var normal:Vector3D;
    public var mesh:Mesh3D;
    public var surface:Surface3D;
    public var u:Float = 0;
    public var v:Float = 0;
    public var poly:Dynamic;

    public var distance:Float = 0;
    public var target:flare.core.Pivot3D;

    public function new(p:Vector3D = null, n:Vector3D = null, dist:Float = 0, t:flare.core.Pivot3D = null) {
        this.point = p != null ? p : new Vector3D();
        this.normal = n != null ? n : new Vector3D(0, 1, 0);
        this.distance = dist;
        this.target = t;
        if (Std.isOfType(t, Mesh3D)) {
            this.mesh = cast t;
        }
    }
}
