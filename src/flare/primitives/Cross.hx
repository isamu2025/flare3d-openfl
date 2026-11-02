package flare.primitives;

import flare.core.Lines3D;

/**
 * Cross renders a 3D orthogonal cross axis gizmo.
 */
class Cross extends Lines3D {
    public function new(name:String = "cross", size:Float = 10, color:Int = 0xffffff, alpha:Float = 1.0) {
        super(name, color, 1.0);
        var hs = size * 0.5;
        lineTo(-hs, 0, 0, hs, 0, 0);
        lineTo(0, -hs, 0, 0, hs, 0);
        lineTo(0, 0, -hs, 0, 0, hs);
    }
}
