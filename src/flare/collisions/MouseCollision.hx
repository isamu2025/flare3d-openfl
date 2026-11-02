package flare.collisions;

import openfl.geom.Vector3D;
import flare.core.Camera3D;
import flare.core.Mesh3D;

/**
 * MouseCollision casts rays from 2D screen coordinates into 3D world space.
 */
class MouseCollision {
    public var ray:RayCollision;

    public function new() {
        ray = new RayCollision();
    }

    /**
     * Casts a ray from screen coordinates through the camera into world space.
     */
    public function getRayFromScreen(mouseX:Float, mouseY:Float, viewWidth:Float, viewHeight:Float, camera:Camera3D):RayCollision {
        if (camera == null || viewWidth <= 0 || viewHeight <= 0) return ray;

        // Convert 2D screen coords to normalized device coords [-1, 1]
        var ndcX = (mouseX / viewWidth) * 2.0 - 1.0;
        var ndcY = 1.0 - (mouseY / viewHeight) * 2.0;

        var origin = new Vector3D(camera.x, camera.y, camera.z);
        
        // Direction from camera position
        var dir = new Vector3D(ndcX * camera.aspectRatio, ndcY, 1.0);
        dir.normalize();

        var worldDir = camera.world.deltaTransformVector(dir);
        worldDir.normalize();

        ray.setRay(origin.x, origin.y, origin.z, worldDir.x, worldDir.y, worldDir.z);
        return ray;
    }

    public function testMesh(mouseX:Float, mouseY:Float, viewWidth:Float, viewHeight:Float, camera:Camera3D, mesh:Mesh3D):Bool {
        var r = getRayFromScreen(mouseX, mouseY, viewWidth, viewHeight, camera);
        return r.test(mesh);
    }
}
