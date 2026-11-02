package flare.flsl;

import flare.core.Texture3D;

/**
 * FLSLSampler binds a 2D or Cube texture sampler with filtering and wrap parameters.
 */
class FLSLSampler extends FLSL {
    public var value:Texture3D;
    public var type:Int;
    public var format:String = "rgba";
    public var filter:String = "linear";
    public var mip:String = "none";
    public var bias:Float = 0;
    public var height:Int = 0;
    public var options:Dynamic;
    public var optimizeForRenderToTexture:Bool = false;
    public var order:Int = 0;

    public function new(value:Texture3D = null, type:Int = 0) {
        super();
        this.value = value;
        this.type = type;
    }
}
