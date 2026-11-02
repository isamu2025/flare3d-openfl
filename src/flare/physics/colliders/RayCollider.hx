package flare.physics.colliders;

import openfl.geom.Vector3D;
import flare.core.Pivot3D;

/**
 * RayCollider casts a single physical ray for ground alignment or projectile hits.
 */
class RayCollider extends Collider {
    public var origin:Vector3D;
    public var direction:Vector3D;
    public var length:Float = 1000.0;

    public function new(pivot:Pivot3D = null, length:Float = 1000.0) {
        super(pivot);
        this.shape = Collider.SHAPE_RAY;
        this.length = length;
        this.origin = new Vector3D();
        this.direction = new Vector3D(0, -1, 0);
    }
}
