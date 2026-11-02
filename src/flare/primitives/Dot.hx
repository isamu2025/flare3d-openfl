package flare.primitives;

/**
 * Dot renders a small spherical or circular point indicator.
 */
class Dot extends Radius {
    public function new(name:String = "point", radius:Float = 5, color:Int = 0xffffff) {
        super(name, radius, color, 1.0, 16);
    }
}
