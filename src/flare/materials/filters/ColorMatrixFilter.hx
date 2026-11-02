package flare.materials.filters;

import openfl.Vector;

/**
 * ColorMatrixFilter applies a 4x5 color transformation matrix on fragment colors.
 */
class ColorMatrixFilter extends Filter3D {
    public static var GRAY:Vector<Float> = new Vector<Float>(20, true, [
        0.3, 0.59, 0.11, 0, 0,
        0.3, 0.59, 0.11, 0, 0,
        0.3, 0.59, 0.11, 0, 0,
        0, 0, 0, 1, 0
    ]);

    public var values:Vector<Float>;

    public function new(values:Vector<Float> = null) {
        super("colorMatrix");
        this.values = values != null ? values : new Vector<Float>(20);
    }
}
