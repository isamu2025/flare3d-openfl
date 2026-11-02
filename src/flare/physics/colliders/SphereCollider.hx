package flare.physics.colliders;

import flare.core.Pivot3D;

/**
 * SphereCollider represents a spherical collision volume.
 */
class SphereCollider extends Collider {
    public var radius:Float;

    public function new(pivot:Pivot3D = null, radius:Float = 10) {
        super(pivot);
        this.shape = Collider.SHAPE_SPHERE;
        this.radius = radius;
    }
}
