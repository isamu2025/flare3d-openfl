package flare.primitives;

import flare.core.Camera3D;
import flare.core.Light3D;
import flare.core.Pivot3D;
import flare.core.IDrawable;
import flare.core.Lines3D;
import flare.materials.Material3D;
import flare.system.Device3D;

/**
 * DebugLight renders a visual indicator for light positions and directions.
 */
class DebugLight extends Pivot3D implements IDrawable {
    public var light:Light3D;
    public var inView(get, never):Bool;
    public var color:Int;
    public var alpha:Float;

    private var _lPoint:Lines3D;
    private var _lPointInfinite:Lines3D;
    private var _lDir:Lines3D;

    public function new(light:Light3D, color:Int = 0xffcb00, alpha:Float = 1.0) {
        super("debug_" + (light != null ? light.name : "light"));
        this.light = light;
        this.color = color;
        this.alpha = alpha;

        _lPoint = new Lines3D("lPoint", color, alpha);
        _lPointInfinite = new Lines3D("lPointInfinite", color, alpha);
        _lDir = new Lines3D("lDir", color, alpha);

        drawDir();
        drawPointInfinite();
        drawRadius();
    }

    private function drawDir():Void {
        _lDir.lineStyle(2.2, color, alpha);
        var s:Float = 20;
        var h:Float = 8;
        var d1:Float = 20;
        var d2:Float = 30;

        _lDir.moveTo(-s, -s, 0);
        _lDir.lineTo(-s, s, 0);
        _lDir.lineTo(s, s, 0);
        _lDir.lineTo(s, -s, 0);
        _lDir.lineTo(-s, -s, 0);

        _lDir.moveTo(0, 0, 0);
        _lDir.lineTo(0, 0, d1);

        _lDir.moveTo(-h, 0, d1);
        _lDir.lineTo(h, 0, d1);
        _lDir.lineTo(0, 0, d2);
        _lDir.lineTo(-h, 0, d1);
    }

    private function drawPointInfinite():Void {
        _lPointInfinite.lineStyle(1, color, alpha);
        var step = (Math.PI * 2) / 6;
        var r1:Float = 30 * 0.7;
        var r2:Float = 30;

        var b:Float = step;
        while (b <= Math.PI * 2 + step) {
            var a:Float = step;
            while (a <= Math.PI * 2 + step) {
                var vy = -Math.cos(b);
                var vx = Math.cos(a) * Math.sin(b);
                var vz = -Math.sin(a) * Math.sin(b);
                _lPointInfinite.moveTo(vx * r1, vy * r1, vz * r1);
                _lPointInfinite.lineTo(vx * r2, vy * r2, vz * r2);
                a += step;
            }
            b += step;
        }
    }

    private function drawRadius(steps:Int = 24):Void {
        _lPoint.lineStyle(1, color, alpha);
        var inc = (Math.PI * 2) / steps;
        var r:Float = 1.0;

        // Circle 1: XZ plane
        _lPoint.moveTo(Math.cos(0) * r, 0, Math.sin(0) * r);
        var a:Float = inc;
        while (a <= Math.PI * 2 + inc * 0.5) {
            _lPoint.lineTo(Math.cos(a) * r, 0, Math.sin(a) * r);
            a += inc;
        }

        // Circle 2: YZ plane
        _lPoint.moveTo(0, Math.cos(0) * r, Math.sin(0) * r);
        a = inc;
        while (a <= Math.PI * 2 + inc * 0.5) {
            _lPoint.lineTo(0, Math.cos(a) * r, Math.sin(a) * r);
            a += inc;
        }

        // Circle 3: XY plane
        _lPoint.moveTo(Math.cos(0) * r, Math.sin(0) * r, 0);
        a = inc;
        while (a <= Math.PI * 2 + inc * 0.5) {
            _lPoint.lineTo(Math.cos(a) * r, Math.sin(a) * r, 0);
            a += inc;
        }
    }

    override public function render(camera:Camera3D = null, clearDepth:Bool = false, target:Dynamic = null):Void {
        if (!visible || light == null) return;
        var cam = camera != null ? camera : Device3D.camera;

        if (light.type == Light3D.DIRECTIONAL) {
            _lDir.world.copyFrom(world);
            _lDir.render(cam);
        } else if (light.infinite) {
            _lPointInfinite.world.copyFrom(world);
            _lPointInfinite.render(cam);
        } else {
            _lPoint.world.copyFrom(world);
            var r = (light.radius > 0) ? light.radius : 1.0;
            _lPoint.world.prependScale(r, r, r);
            _lPoint.render(cam);
        }
    }

    override public function draw(includeChildren:Bool = true, material:Material3D = null):Void {
        render(Device3D.camera);
        if (includeChildren) {
            for (c in children) {
                c.draw(true, material);
            }
        }
    }

    private function get_inView():Bool return true;
}
