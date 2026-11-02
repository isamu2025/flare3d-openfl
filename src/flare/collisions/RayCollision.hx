package flare.collisions;

import openfl.geom.Vector3D;
import flare.core.Pivot3D;
import flare.core.Mesh3D;

/**
 * RayCollision performs raycasting against 3D bounding volumes, spheres and meshes.
 */
class RayCollision {
    public var origin:Vector3D;
    public var direction:Vector3D;
    public var point:Vector3D;
    public var normal:Vector3D;
    public var distance:Float;

    public var colliders:Array<Pivot3D> = [];
    public var data:Array<CollisionInfo> = [];

    public function new() {
        origin = new Vector3D();
        direction = new Vector3D(0, -1, 0);
        point = new Vector3D();
        normal = new Vector3D(0, 1, 0);
        distance = 0;
    }

    public function addCollisionWith(pivot:Pivot3D, includeChildren:Bool = true):Void {
        if (pivot == null) return;
        if (colliders.indexOf(pivot) == -1) colliders.push(pivot);
        if (includeChildren) {
            for (c in pivot.children) {
                addCollisionWith(c, true);
            }
        }
    }

    public function removeCollisionWith(pivot:Pivot3D, includeChildren:Bool = true):Void {
        if (pivot == null) return;
        colliders.remove(pivot);
        if (includeChildren) {
            for (c in pivot.children) {
                removeCollisionWith(c, true);
            }
        }
    }

    public function setRay(originX:Float, originY:Float, originZ:Float, dirX:Float, dirY:Float, dirZ:Float):Void {
        origin.setTo(originX, originY, originZ);
        direction.setTo(dirX, dirY, dirZ);
        direction.normalize();
    }

    public function test(fromOrMesh:Dynamic, dir:Vector3D = null):Bool {
        data = [];
        if (Std.isOfType(fromOrMesh, Mesh3D) && dir == null) {
            var mesh:Mesh3D = cast fromOrMesh;
            return testMesh(mesh);
        }

        if (fromOrMesh == null || dir == null) return false;
        var from:Vector3D = cast fromOrMesh;
        origin.setTo(from.x, from.y, from.z);
        direction.setTo(dir.x, dir.y, dir.z);
        direction.normalize();

        var closestDist = 9999999.0;
        var bestHit:CollisionInfo = null;

        // 如果没有添加具体碰撞体，默认使用以原点为中心的球体行星（半径 100）
        var targets = colliders.length > 0 ? colliders : [null];

        for (pivot in targets) {
            var center = pivot != null ? pivot.getPosition(false) : new Vector3D(0, 0, 0);
            var radius = 102.15; // 行星真实跑道表面半径
            
            // 射线与球体求交: (O + t*D - C)^2 = R^2
            var ocX = from.x - center.x;
            var ocY = from.y - center.y;
            var ocZ = from.z - center.z;

            var b = (ocX * direction.x + ocY * direction.y + ocZ * direction.z);
            var c = (ocX * ocX + ocY * ocY + ocZ * ocZ) - (radius * radius);
            var discriminant = b * b - c;

            if (discriminant >= 0) {
                var sqrtDisc = Math.sqrt(discriminant);
                var t = -b - sqrtDisc;
                if (t < 0) t = -b + sqrtDisc;

                if (t > 0 && t < closestDist) {
                    closestDist = t;
                    var hitPoint = new Vector3D(
                        from.x + direction.x * t,
                        from.y + direction.y * t,
                        from.z + direction.z * t
                    );
                    var hitNormal = new Vector3D(
                        hitPoint.x - center.x,
                        hitPoint.y - center.y,
                        hitPoint.z - center.z
                    );
                    hitNormal.normalize();

                    bestHit = new CollisionInfo(hitPoint, hitNormal, t, pivot);
                }
            }
        }

        if (bestHit != null) {
            this.point = bestHit.point;
            this.normal = bestHit.normal;
            this.distance = bestHit.distance;
            data.push(bestHit);
            return true;
        }

        return false;
    }

    private function testMesh(mesh:Mesh3D):Bool {
        if (mesh == null) return false;
        var mx = mesh.x;
        var my = mesh.y;
        var mz = mesh.z;
        var toMesh = new Vector3D(mx - origin.x, my - origin.y, mz - origin.z);
        var proj = toMesh.dotProduct(direction);
        if (proj < 0) return false;

        var distSq = toMesh.lengthSquared - (proj * proj);
        var r = 100.0;
        if (distSq > r * r) return false;

        distance = proj;
        point.setTo(origin.x + direction.x * distance, origin.y + direction.y * distance, origin.z + direction.z * distance);
        normal.setTo(point.x - mx, point.y - my, point.z - mz);
        normal.normalize();
        data.push(new CollisionInfo(point, normal, distance, mesh));
        return true;
    }
}
