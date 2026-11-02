package flare.materials.filters;

/**
 * DofFilter applies depth-of-field focal blurring based on distance from the camera.
 */
class DofFilter extends Filter3D {
    public var focalDistance:Float = 200.0;
    public var focalRange:Float = 100.0;
    public var maxBlur:Float = 5.0;

    public function new(focalDistance:Float = 200.0, focalRange:Float = 100.0, maxBlur:Float = 5.0) {
        super("dof");
        this.focalDistance = focalDistance;
        this.focalRange = focalRange;
        this.maxBlur = maxBlur;
    }
}
