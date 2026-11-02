package flare.physics;

import openfl.geom.Vector3D;
import flare.physics.colliders.Collider;

/**
 * Contact stores contact manifold information between colliding rigid bodies.
 */
class Contact {
    public var collider0:Collider;
    public var collider1:Collider;
    public var point:Vector3D;
    public var normal:Vector3D;
    public var penetration:Float = 0;
    public var distance:Float = 0;

    public function new() {
        point = new Vector3D();
        normal = new Vector3D(0, 1, 0);
    }
}
