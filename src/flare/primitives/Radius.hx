package flare.primitives;

import flare.core.Lines3D;

/**
 * Radius renders a 3-axis orthogonal orbital ring gizmo.
 */
class Radius extends Lines3D {
    private var _radius:Float;
    private var _steps:Int;

    public var radius(get, set):Float;
    private function get_radius():Float return _radius;
    private function set_radius(v:Float):Float {
        _radius = v;
        config();
        return _radius;
    }

    public var steps(get, set):Int;
    private function get_steps():Int return _steps;
    private function set_steps(v:Int):Int {
        _steps = v;
        config();
        return _steps;
    }

    public function new(name:String = "radius", radius:Float = 5, color:Int = 0xffffff, alpha:Float = 1.0, steps:Int = 24) {
        super(name, color, alpha);
        this._radius = radius;
        this._steps = steps > 0 ? steps : 24;
        config();
    }

    public function config():Void {
        clear();
        lineStyle(1, _color, _alpha);
        var inc = (Math.PI * 2) / _steps;

        // Circle 1: XZ plane
        moveTo(Math.cos(0) * _radius, 0, Math.sin(0) * _radius);
        var a:Float = inc;
        while (a <= Math.PI * 2 + inc * 0.5) {
            lineTo(Math.cos(a) * _radius, 0, Math.sin(a) * _radius);
            a += inc;
        }

        // Circle 2: YZ plane
        moveTo(0, Math.cos(0) * _radius, Math.sin(0) * _radius);
        a = inc;
        while (a <= Math.PI * 2 + inc * 0.5) {
            lineTo(0, Math.cos(a) * _radius, Math.sin(a) * _radius);
            a += inc;
        }

        // Circle 3: XY plane
        moveTo(Math.cos(0) * _radius, Math.sin(0) * _radius, 0);
        a = inc;
        while (a <= Math.PI * 2 + inc * 0.5) {
            lineTo(Math.cos(a) * _radius, Math.sin(a) * _radius, 0);
            a += inc;
        }
    }
}
