package flare.primitives;

import flare.core.IDrawable;
import flare.core.Lines3D;

/**
 * HPlane renders an infinite or wide horizontal grid plane for ground reference.
 */
class HPlane extends Lines3D implements IDrawable {
    public function new(name:String = "hplane", size:Int = 10, color:Int = 0xffcb00, alpha:Float = 1.0) {
        super(name, color, 1.0);

        var step = size / 10.0;
        var hs = size * 0.5;

        var i = -hs;
        while (i <= hs) {
            lineTo(i, 0, -hs, i, 0, hs);
            lineTo(-hs, 0, i, hs, 0, i);
            i += step;
        }
    }
}
