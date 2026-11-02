package flare.materials.filters;

/**
 * ColorTransformFilter adjusts color channels using multiplier and offset components.
 */
class ColorTransformFilter extends Filter3D {
    public var redMultiplier:Float;
    public var greenMultiplier:Float;
    public var blueMultiplier:Float;
    public var alphaMultiplier:Float;
    public var redOffset:Float;
    public var greenOffset:Float;
    public var blueOffset:Float;
    public var alphaOffset:Float;

    public function new(redMultiplier:Float = 1, greenMultiplier:Float = 1, blueMultiplier:Float = 1, alphaMultiplier:Float = 1, redOffset:Float = 0, greenOffset:Float = 0, blueOffset:Float = 0, alphaOffset:Float = 0) {
        super("colorTransform");
        this.redMultiplier = redMultiplier;
        this.greenMultiplier = greenMultiplier;
        this.blueMultiplier = blueMultiplier;
        this.alphaMultiplier = alphaMultiplier;
        this.redOffset = redOffset;
        this.greenOffset = greenOffset;
        this.blueOffset = blueOffset;
        this.alphaOffset = alphaOffset;
    }
}
