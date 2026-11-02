package flare.primitives;

import flare.core.Lines3D;

/**
 * Spring renders a 3D helical coil spring wireframe primitive.
 */
class Spring extends Lines3D {
    public function new(name:String = "spring", radius:Float = 5, length:Float = 5, count:Float = 5, color:Int = 0xffffff, alpha:Float = 1.0, steps:Int = 24) {
        super(name, color, 1.0);

        var totalSteps = Std.int(steps * count);
        var stepLength = length / totalSteps;

        for (i in 0...totalSteps) {
            var theta0 = (i / steps) * Math.PI * 2;
            var theta1 = ((i + 1) / steps) * Math.PI * 2;
            var y0 = i * stepLength;
            var y1 = (i + 1) * stepLength;

            var x0 = Math.cos(theta0) * radius;
            var z0 = Math.sin(theta0) * radius;
            var x1 = Math.cos(theta1) * radius;
            var z1 = Math.sin(theta1) * radius;

            lineTo(x0, y0, z0, x1, y1, z1);
        }
    }
}
