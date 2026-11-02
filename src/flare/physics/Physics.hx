package flare.physics;

import openfl.geom.Vector3D;
import flare.physics.colliders.BoxCollider;
import flare.physics.colliders.Collider;
import flare.physics.colliders.SphereCollider;

/**
 * Physics is the rigid body dynamics world simulator in Flare3D.
 */
class Physics {
    public var gravity:Vector3D;
    public var colliders:Array<Collider>;
    public var contacts:Array<Contact>;

    public function new() {
        this.gravity = new Vector3D(0, -9.8, 0);
        this.colliders = [];
        this.contacts = [];
    }

    public function addCollider(collider:Collider):Collider {
        if (collider == null) return null;
        if (colliders.indexOf(collider) == -1) {
            colliders.push(collider);
        }
        return collider;
    }

    public function removeCollider(collider:Collider):Void {
        var idx = colliders.indexOf(collider);
        if (idx != -1) {
            colliders.splice(idx, 1);
        }
    }

    public function step(iterations:Int = 3, timeStep:Float = 0.016666):Void {
        // 1. Integrate forces and gravity
        for (c in colliders) {
            if (!c.isStatic && c.enabled && !c.sleeping) {
                c.syncFromPivot();
                var g = c.gravity != null ? c.gravity : gravity;
                c.linearVelocity.x += g.x * timeStep;
                c.linearVelocity.y += g.y * timeStep;
                c.linearVelocity.z += g.z * timeStep;
            }
        }

        // 2. Collision detection & impulse resolution
        contacts = [];
        var numColliders = colliders.length;
        for (i in 0...numColliders) {
            var c0 = colliders[i];
            if (!c0.enabled) continue;

            for (j in (i + 1)...numColliders) {
                var c1 = colliders[j];
                if (!c1.enabled || (c0.isStatic && c1.isStatic)) continue;

                solveCollision(c0, c1);
            }
        }

        // 3. Integrate positions
        for (c in colliders) {
            c.update(timeStep);
        }
    }

    private function solveCollision(c0:Collider, c1:Collider):Void {
        // Sphere vs Sphere
        if (c0.shape == Collider.SHAPE_SPHERE && c1.shape == Collider.SHAPE_SPHERE) {
            var s0:SphereCollider = cast c0;
            var s1:SphereCollider = cast c1;
            var dx = s1.position.x - s0.position.x;
            var dy = s1.position.y - s0.position.y;
            var dz = s1.position.z - s0.position.z;
            var distSq = dx * dx + dy * dy + dz * dz;
            var minDist = s0.radius + s1.radius;

            if (distSq < minDist * minDist && distSq > 0.00001) {
                var dist = Math.sqrt(distSq);
                var nx = dx / dist;
                var ny = dy / dist;
                var nz = dz / dist;
                var pen = minDist - dist;

                // Position separation
                var totalInvMass = c0.invMass + c1.invMass;
                if (totalInvMass > 0) {
                    var sep0 = (c0.invMass / totalInvMass) * pen;
                    var sep1 = (c1.invMass / totalInvMass) * pen;
                    if (!c0.isStatic) {
                        c0.position.x -= nx * sep0;
                        c0.position.y -= ny * sep0;
                        c0.position.z -= nz * sep0;
                    }
                    if (!c1.isStatic) {
                        c1.position.x += nx * sep1;
                        c1.position.y += ny * sep1;
                        c1.position.z += nz * sep1;
                    }

                    // Velocity impulse
                    var relVx = c1.linearVelocity.x - c0.linearVelocity.x;
                    var relVy = c1.linearVelocity.y - c0.linearVelocity.y;
                    var relVz = c1.linearVelocity.z - c0.linearVelocity.z;
                    var velAlongNormal = relVx * nx + relVy * ny + relVz * nz;

                    if (velAlongNormal < 0) {
                        var e = Math.min(c0.restitution, c1.restitution);
                        var j = -(1.0 + e) * velAlongNormal / totalInvMass;
                        if (!c0.isStatic) {
                            c0.linearVelocity.x -= nx * j * c0.invMass;
                            c0.linearVelocity.y -= ny * j * c0.invMass;
                            c0.linearVelocity.z -= nz * j * c0.invMass;
                        }
                        if (!c1.isStatic) {
                            c1.linearVelocity.x += nx * j * c1.invMass;
                            c1.linearVelocity.y += ny * j * c1.invMass;
                            c1.linearVelocity.z += nz * j * c1.invMass;
                        }
                    }
                }
            }
        }
        // Box vs Sphere
        else if (c0.shape == Collider.SHAPE_BOX && c1.shape == Collider.SHAPE_SPHERE) {
            solveBoxSphere(cast c0, cast c1);
        } else if (c0.shape == Collider.SHAPE_SPHERE && c1.shape == Collider.SHAPE_BOX) {
            solveBoxSphere(cast c1, cast c0);
        }
    }

    private function solveBoxSphere(box:BoxCollider, sphere:SphereCollider):Void {
        var dx = sphere.position.x - box.position.x;
        var dy = sphere.position.y - box.position.y;
        var dz = sphere.position.z - box.position.z;

        // Closest point on box
        var cx = Math.max(-box.halfWidth, Math.min(box.halfWidth, dx));
        var cy = Math.max(-box.halfHeight, Math.min(box.halfHeight, dy));
        var cz = Math.max(-box.halfDepth, Math.min(box.halfDepth, dz));

        var distVectorX = dx - cx;
        var distVectorY = dy - cy;
        var distVectorZ = dz - cz;
        var distSq = distVectorX * distVectorX + distVectorY * distVectorY + distVectorZ * distVectorZ;

        if (distSq < sphere.radius * sphere.radius && distSq > 0.00001) {
            var dist = Math.sqrt(distSq);
            var nx = distVectorX / dist;
            var ny = distVectorY / dist;
            var nz = distVectorZ / dist;
            var pen = sphere.radius - dist;

            if (!sphere.isStatic) {
                sphere.position.x += nx * pen;
                sphere.position.y += ny * pen;
                sphere.position.z += nz * pen;

                var vDotN = sphere.linearVelocity.x * nx + sphere.linearVelocity.y * ny + sphere.linearVelocity.z * nz;
                if (vDotN < 0) {
                    var impulse = -(1.0 + sphere.restitution) * vDotN;
                    sphere.linearVelocity.x += nx * impulse;
                    sphere.linearVelocity.y += ny * impulse;
                    sphere.linearVelocity.z += nz * impulse;
                }
            }
        }
    }

    public function rayCast(pos:Vector3D, dir:Vector3D, target:Collider = null, maxDistance:Float = 1000):Contact {
        var contact = new Contact();
        contact.point.setTo(pos.x + dir.x * maxDistance, pos.y + dir.y * maxDistance, pos.z + dir.z * maxDistance);
        contact.distance = maxDistance;
        return contact;
    }
}
