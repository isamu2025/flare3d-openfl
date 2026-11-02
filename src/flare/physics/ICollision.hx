package flare.physics;

import openfl.Vector;
import flare.physics.colliders.Collider;

/**
 * Interface for narrow-phase collision detectors between collider pairs.
 */
interface ICollision {
    public function test(collider0:Collider, collider1:Collider, contacts:Vector<Contact>, numContacts:Int):Int;
}
