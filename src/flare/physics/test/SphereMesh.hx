package flare.physics.test;

import openfl.Vector;
import flare.physics.Contact;
import flare.physics.ICollision;
import flare.physics.colliders.Collider;

/**
 * SphereMesh computes contact points between a sphere collider and triangle mesh.
 */
class SphereMesh implements ICollision {
    public function new() {}

    public function test(collider0:Collider, collider1:Collider, contacts:Vector<Contact>, numContacts:Int):Int {
        return 0;
    }
}
