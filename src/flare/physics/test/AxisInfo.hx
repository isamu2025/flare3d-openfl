package flare.physics.test;

/**
 * AxisInfo records projection interval (min, max) for SAT collision tests.
 */
class AxisInfo {
    public var min:Float;
    public var max:Float;

    public function new(min:Float = 0, max:Float = 0) {
        this.min = min;
        this.max = max;
    }
}
