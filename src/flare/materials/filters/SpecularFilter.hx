package flare.materials.filters;

/**
 * SpecularFilter calculates Blinn-Phong specular highlights without requiring a specular map texture.
 */
class SpecularFilter extends Filter3D {
    public var power:Float;
    public var level:Float;

    public function new(power:Float = 50, level:Float = 1.0) {
        super();
        this.power = power;
        this.level = level;
    }
}
