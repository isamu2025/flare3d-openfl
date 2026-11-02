package flare.materials.filters;

/**
 * BloomFilter applies high-luminance glowing blur to fragment outputs.
 */
class BloomFilter extends Filter3D {
    public var blurX:Float = 4.0;
    public var blurY:Float = 4.0;
    public var intensity:Float = 1.5;
    public var threshold:Float = 0.7;

    public function new(blurX:Float = 4.0, blurY:Float = 4.0, intensity:Float = 1.5, threshold:Float = 0.7) {
        super("bloom");
        this.blurX = blurX;
        this.blurY = blurY;
        this.intensity = intensity;
        this.threshold = threshold;
    }
}
