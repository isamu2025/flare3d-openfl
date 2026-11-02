package flare.primitives;

import flare.core.Lines3D;

/**
 * Dome renders a hemispherical wireframe dome primitive.
 */
class Dome extends Lines3D {
    public function new(name:String = "dome", radius:Float = 5, color:Int = 0xffffff, alpha:Float = 1.0, steps:Int = 24) {
        super(name, color, 1.0);

        // Latitude rings (hemisphere)
        var rings = Std.int(steps / 4);
        for (i in 0...rings) {
            var phi = (i / rings) * (Math.PI * 0.5);
            var y = Math.sin(phi) * radius;
            var r = Math.cos(phi) * radius;

            for (j in 0...steps) {
                var a0 = (j / steps) * Math.PI * 2;
                var a1 = ((j + 1) / steps) * Math.PI * 2;
                lineTo(Math.cos(a0) * r, y, Math.sin(a0) * r, Math.cos(a1) * r, y, Math.sin(a1) * r);
            }
        }

        // Longitude arcs
        var arcs = 8;
        for (a in 0...arcs) {
            var angle = (a / arcs) * Math.PI * 2;
            var ca = Math.cos(angle);
            var sa = Math.sin(angle);

            for (s in 0...steps) {
                var p0 = (s / steps) * (Math.PI * 0.5);
                var p1 = ((s + 1) / steps) * (Math.PI * 0.5);
                var r0 = Math.cos(p0) * radius;
                var y0 = Math.sin(p0) * radius;
                var r1 = Math.cos(p1) * radius;
                var y1 = Math.sin(p1) * radius;
                lineTo(ca * r0, y0, sa * r0, ca * r1, y1, sa * r1);
            }
        }
    }
}
