package flare.materials.filters;

/**
 * SepiaFilter applies an antique brown/sepia tone to fragment rendering.
 */
class SepiaFilter extends Filter3D {
    public var intensity:Float = 1.0;

    public function new(intensity:Float = 1.0) {
        super("sepia");
        this.intensity = intensity;
    }
}
