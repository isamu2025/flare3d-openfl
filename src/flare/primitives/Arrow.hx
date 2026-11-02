package flare.primitives;

import flare.core.Lines3D;

/**
 * Arrow renders a directional line indicator with an arrow tip.
 */
class Arrow extends Lines3D {
    public function new(name:String = "arrow", length:Float = 50, size:Float = 5, color:Int = 0xffcb00, alpha:Float = 1.0) {
        super(name, color, 1.0);
        // Shaft
        lineTo(0, 0, 0, 0, 0, length);
        // Arrow head
        lineTo(0, 0, length, -size * 0.5, 0, length - size);
        lineTo(0, 0, length, size * 0.5, 0, length - size);
        lineTo(0, 0, length, 0, -size * 0.5, length - size);
        lineTo(0, 0, length, 0, size * 0.5, length - size);
    }
}
