package flare.primitives;

import openfl.geom.Vector3D;
import flare.core.Lines3D;
import flare.core.Shape3D;

/**
 * DebugShape visualizes vector Shape3D curves using 3D line primitives.
 */
class DebugShape extends Lines3D {
    private var _shape:Shape3D;
    private var _steps:Int = 12;

    public var shape(get, set):Shape3D;
    private function get_shape():Shape3D return _shape;
    private function set_shape(val:Shape3D):Shape3D {
        _shape = val;
        config();
        return _shape;
    }

    public var steps(get, set):Int;
    private function get_steps():Int return _steps;
    private function set_steps(val:Int):Int {
        _steps = val;
        config();
        return _steps;
    }

    public function new(shape:Shape3D = null, steps:Int = 12) {
        super("debug_" + (shape != null ? shape.name : "shape"));
        this._steps = steps;
        this.shape = shape;
    }

    public function config():Void {
        if (_shape == null) return;
        clear();

        var col:Int = 0xffffff;
        if (_shape.color != null) {
            col = cast _shape.color;
        }
        lineStyle(1, col);

        if (_shape.splines == null) return;
        var p = new Vector3D();
        for (spline in _shape.splines) {
            if (spline.knots == null || spline.knots.length == 0) continue;
            var p0 = spline.getPoint(0);
            var totalSteps = spline.knots.length * _steps;
            if (totalSteps <= 0) totalSteps = 1;
            moveTo(p0.x, p0.y, p0.z);
            var stepInc = 1.0 / totalSteps;
            var t:Float = stepInc;
            while (t < 1.0) {
                spline.getPoint(t, p);
                lineTo(p.x, p.y, p.z);
                t += stepInc;
            }
            if (spline.closed) {
                lineTo(p0.x, p0.y, p0.z);
            } else {
                spline.getPoint(1.0, p);
                lineTo(p.x, p.y, p.z);
            }
        }
    }
}
