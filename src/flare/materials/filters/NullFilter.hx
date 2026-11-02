package flare.materials.filters;

/**
 * NullFilter provides a fallback constant tint filter for debug surfaces.
 */
class NullFilter extends Filter3D {
    public var color:Int;
    public var size:Float;
    public var blendMode:String;
    public var a:Float = 1;

    public function new(color:Int = 0xffffff, size:Float = 10, blendMode:String = null) {
        super("null");
        this.color = color;
        this.size = size;
        this.blendMode = blendMode;
    }
}
