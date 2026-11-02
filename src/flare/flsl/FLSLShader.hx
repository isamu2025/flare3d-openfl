package flare.flsl;

/**
 * FLSLShader represents a complete multi-pass shader definition in FLSL.
 */
class FLSLShader extends FLSLScope {
    public var currentPass:Int = 0;
    public var outputFragment:String;
    public var outputVertex:String;

    public function new(name:String = null) {
        super(name);
    }

    public function build():Void {}
    public function getNumPasses():Int return 1;
    public function init():Void {}
    public function process():Void {}
}
