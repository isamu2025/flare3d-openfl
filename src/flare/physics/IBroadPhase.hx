package flare.physics;

import openfl.Vector;
import flare.physics.colliders.Collider;

/**
 * Interface for broad-phase spatial partition and collision culling.
 */
interface IBroadPhase {
    public var axis(get, set):Int;
    public function addCollider(collider:Collider):Bool;
    public function removeCollider(collider:Collider):Bool;
    public function test(contacts:Vector<Contact>):Int;
}
