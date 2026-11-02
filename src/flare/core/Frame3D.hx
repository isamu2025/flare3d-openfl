package flare.core;

import openfl.geom.Matrix3D;
import openfl.Vector;

/**
 * Frame3D represents a keyframe matrix transform or animation event callback in Flare3D.
 */
class Frame3D extends Matrix3D {
    public static inline var TYPE_FRAME:Int = 0;
    public static inline var TYPE_NULL:Int = 2;

    public var type:Int = 0;
    public var callback:Dynamic;

    public function new(vector:Vector<Float> = null, type:Int = 0) {
        super(vector);
        this.type = type;
    }

    override public function clone():Matrix3D {
        var f = new Frame3D(rawData.copy(), type);
        f.callback = callback;
        return f;
    }
}
