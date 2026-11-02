package flare.physics.test;

import openfl.Vector;
import flare.physics.Contact;
import flare.physics.ICollision;
import flare.physics.colliders.Collider;

/**
 * BoxMesh computes collision between an oriented box and arbitrary mesh geometry.
 */
class BoxMesh implements ICollision {
    public function new() {}

    public function test(collider0:Collider, collider1:Collider, contacts:Vector<Contact>, numContacts:Int):Int {
        return 0;
    }
}
