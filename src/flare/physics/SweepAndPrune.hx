package flare.physics;

import openfl.Vector;
import flare.physics.colliders.Collider;

/**
 * SweepAndPrune (SAP) 1D sort-and-sweep broad-phase collision detector.
 */
class SweepAndPrune implements IBroadPhase {
    private var _colliders:Vector<Collider>;
    private var _axis:Int = 0;

    public var axis(get, set):Int;

    public function new() {
        _colliders = new Vector<Collider>();
    }

    public function addCollider(collider:Collider):Bool {
        if (collider == null || _colliders.indexOf(collider) != -1) return false;
        _colliders.push(collider);
        return true;
    }

    public function removeCollider(collider:Collider):Bool {
        var idx = _colliders.indexOf(collider);
        if (idx == -1) return false;
        _colliders.splice(idx, 1);
        return true;
    }

    public function test(contacts:Vector<Contact>):Int {
        // Sort colliders along axis
        var num = 0;
        var len = _colliders.length;
        for (i in 0...len) {
            var c0 = _colliders[i];
            for (j in (i + 1)...len) {
                var c1 = _colliders[j];
                if (c0.isStatic && c1.isStatic) continue;
                if (contacts != null) {
                    var c = new Contact();
                    c.collider0 = c0;
                    c.collider1 = c1;
                    contacts.push(c);
                    num++;
                }
            }
        }
        return num;
    }

    private function get_axis():Int return _axis;
    private function set_axis(v:Int):Int return _axis = v;
}
