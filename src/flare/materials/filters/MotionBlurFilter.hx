package flare.materials.filters;

/**
 * MotionBlurFilter creates dynamic camera movement trailing blur.
 */
class MotionBlurFilter extends Filter3D {
    public var blur:Float = 0.8;

    public function new(blur:Float = 0.8) {
        super("motionBlur");
        this.blur = blur;
    }
}
