package flare.primitives;

import flare.core.Lines3D;

/**
 * Dummy renders a wireframe bounding box / pivot placeholder helper.
 */
class Dummy extends Lines3D {
    private var _size:Float;

    public function new(name:String = "dummy", size:Float = 10, thickness:Float = 1, color:Int = 0xffffff, alpha:Float = 1.0) {
        super(name, color, alpha, thickness);
        this._size = size;
        config();
    }

    public function config():Void {
        var s = _size * 0.5;
        clear();
        lineStyle(_thickness, _color, _alpha);

        // Face 1 (Z = -s)
        moveTo(-s, -s, -s);
        lineTo(s, -s, -s);
        lineTo(s, s, -s);
        lineTo(-s, s, -s);
        lineTo(-s, -s, -s);

        // Face 2 (Z = +s)
        moveTo(-s, -s, s);
        lineTo(s, -s, s);
        lineTo(s, s, s);
        lineTo(-s, s, s);
        lineTo(-s, -s, s);

        // 4 Connecting edges along Z
        moveTo(-s, -s, -s);
        lineTo(-s, -s, s);

        moveTo(s, -s, -s);
        lineTo(s, -s, s);

        moveTo(-s, s, -s);
        lineTo(-s, s, s);

        moveTo(s, s, -s);
        lineTo(s, s, s);
    }
}
