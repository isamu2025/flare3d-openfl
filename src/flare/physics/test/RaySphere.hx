package flare.physics.test;

import openfl.Vector;
import flare.physics.Contact;
import flare.physics.ICollision;
import flare.physics.colliders.Collider;

/**
 * RaySphere computes ray intersections against sphere colliders.
 */
class RaySphere implements ICollision {
    public function new() {}

    public function test(collider0:Collider, collider1:Collider, contacts:Vector<Contact>, numContacts:Int):Int {
        return 0;
    }
}
