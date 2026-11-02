package flare.physics;

import flare.collisions.CollisionInfo;
import flare.core.Pivot3D;
import flare.physics.colliders.Collider;

/**
 * ContactData holds contact reference between colliders and their collision info.
 */
class ContactData {
    public var collider:Collider;
    public var info:CollisionInfo;
    public var pivot:Pivot3D;

    public function new() {
        info = new CollisionInfo();
    }
}
