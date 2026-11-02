package flare.flsl;

import openfl.Vector;

/**
 * FLSLParam binds a vector or float uniform constant parameter in shaders.
 */
class FLSLParam extends FLSL {
    public var value:Vector<Float>;
    public var length:Int;
    public var format:String;
    public var min:Float = 0;
    public var max:Float = 1;
    public var order:Int = 0;
    public var ui:String;

    public function new(value:Vector<Float> = null, length:Int = 1) {
        super();
        this.length = length;
        this.value = value != null ? value : new Vector<Float>(length * 4);
    }
}
