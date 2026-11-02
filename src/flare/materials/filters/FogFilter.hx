package flare.materials.filters;

/**
 * FogFilter applies distance-based atmospheric fog to rendered geometry.
 */
class FogFilter extends Filter3D {
    public var color:Int;
    public var near:Float;
    public var far:Float;

    public function new(color:Int = 0x808080, near:Float = 100.0, far:Float = 1000.0) {
        super("fog");
        this.color = color;
        this.near = near;
        this.far = far;

        this.r = ((color >> 16) & 0xff) / 255.0;
        this.g = ((color >> 8) & 0xff) / 255.0;
        this.b = (color & 0xff) / 255.0;
    }
}
