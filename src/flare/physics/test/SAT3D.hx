package flare.physics.test;

import openfl.geom.Vector3D;
import openfl.Vector;
import flare.physics.Contact;
import flare.physics.colliders.Collider;

/**
 * SAT3D (Separating Axis Theorem 3D) test framework for convex polyhedra.
 */
class SAT3D {
    public var collider0:Collider;
    public var collider1:Collider;
    public var depth:Float = 0;
    public var flags:Int = 0;
    public var swap:Bool = false;
    public var axis:Vector3D;

    public function new() {
        axis = new Vector3D();
    }

    public function init(c0:Collider, c1:Collider):Void {
        this.collider0 = c0;
        this.collider1 = c1;
        this.depth = Math.POSITIVE_INFINITY;
    }

    public function test(sepAxis:Vector3D):Bool {
        return true;
    }

    public function generateContacts(contacts:Vector<Contact>, numContacts:Int):Int {
        return 0;
    }
}
