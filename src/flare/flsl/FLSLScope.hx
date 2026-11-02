package flare.flsl;

/**
 * FLSLScope encapsulates scoped blocks, techniques, and local variables in FLSL.
 */
class FLSLScope extends FLSL {
    public var params:Array<FLSLParam>;

    public function new(name:String = null) {
        super(name);
        params = [];
    }

    public function bind():Void {}
    public function call():Void {}
    public function getTechniqueNames():Array<String> return [];
}
