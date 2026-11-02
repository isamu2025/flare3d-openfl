package flare.primitives;

import flare.core.Camera3D;
import flare.core.Lines3D;

/**
 * DebugCamera renders a frustum wireframe visualization of a Camera3D.
 */
class DebugCamera extends Lines3D {
    public var camera:Camera3D;

    public function new(camera:Camera3D, color:Int = 0xffcb00, alpha:Float = 1.0) {
        super(camera != null ? camera.name + "_debug" : "camera_debug", color, 1.0);
        this.camera = camera;

        var w = 10.0;
        var h = 7.5;
        var d = 15.0;

        // Frustum lines
        lineTo(0, 0, 0, -w, -h, d);
        lineTo(0, 0, 0, w, -h, d);
        lineTo(0, 0, 0, w, h, d);
        lineTo(0, 0, 0, -w, h, d);

        // Rectangular face
        lineTo(-w, -h, d, w, -h, d);
        lineTo(w, -h, d, w, h, d);
        lineTo(w, h, d, -w, h, d);
        lineTo(-w, h, d, -w, -h, d);
    }
}
