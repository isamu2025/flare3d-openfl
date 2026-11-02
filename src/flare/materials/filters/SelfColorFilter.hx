package flare.materials.filters;

/**
 * SelfColorFilter adds an emissive or self-illuminating tint color to materials.
 */
class SelfColorFilter extends Filter3D {
    public var color:Int;
    public var level:Float;

    public function new(color:Int = 0x000000, level:Float = 1.0) {
        super("selfColor");
        this.color = color;
        this.level = level;
    }
}
