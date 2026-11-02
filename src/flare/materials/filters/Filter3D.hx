package flare.materials.filters;

/**
 * Filter3D is the base class for modular shader components in Flare3D.
 */
class Filter3D {
    public var name:String;
    public var alpha:Float = 1.0;
    public var r:Float = 1.0;
    public var g:Float = 1.0;
    public var b:Float = 1.0;
    public var repeatX:Float = 1.0;
    public var repeatY:Float = 1.0;

    public function new(name:String = "filter") {
        this.name = name;
    }
}
