package flare.collisions;

import openfl.geom.Vector3D;
import flare.core.Pivot3D;
import flare.core.Mesh3D;

class ColPoint {
    public var x:Float = 0;
    public var y:Float = 0;
    public var z:Float = 0;
    public function new() {}
}

class ColTriangle {
    public var ax:Float = 0; public var ay:Float = 0; public var az:Float = 0;
    public var bx:Float = 0; public var by:Float = 0; public var bz:Float = 0;
    public var cx:Float = 0; public var cy:Float = 0; public var cz:Float = 0;
    public var nx:Float = 0; public var ny:Float = 0; public var nz:Float = 0;
    public var minX:Float = 0; public var maxX:Float = 0;
    public var minY:Float = 0; public var maxY:Float = 0;
    public var minZ:Float = 0; public var maxZ:Float = 0;
    public var lastQueryTag:Int = 0;

    public function new() {}
}

/**
 * Spatial hash acceleration grid for accelerated sphere-triangle collision detection.
 */
class SpatialTriangleGrid {
    public var cellSize:Float = 64.0;
    public var cells:Map<String, Array<ColTriangle>> = new Map();
    public var triangles:Array<ColTriangle> = [];
    public var candidates:Array<ColTriangle> = [];
    public var queryTag:Int = 0;
    public var initialized:Bool = false;

    public function new() {}

    public function buildFromMeshes(meshes:Array<Mesh3D>):Void {
        cells = new Map();
        triangles = [];
        queryTag = 0;

        for (mesh in meshes) {
            if (mesh == null) continue;

            // Exclude dynamic moving elevator platforms from static collision grid
            var isDynamicPlatform = false;
            var pObj:Pivot3D = mesh;
            while (pObj != null) {
                if (pObj.name == "VBSP_Object_model_1" || pObj.name == "VBSP_Object_model_4") {
                    isDynamicPlatform = true;
                    break;
                }
                pObj = pObj.parent;
            }
            if (isDynamicPlatform) continue;

            mesh.updateWorldMatrix();
            var raw = mesh.world.rawData;

            if (mesh.surfaces == null) continue;
            for (surf in mesh.surfaces) {
                if (surf == null || surf.vertexData == null || surf.indexData == null) continue;
                var vData = surf.vertexData;
                var idxData = surf.indexData;
                var stride = surf.vertexStride > 0 ? surf.vertexStride : 8;
                if (idxData.length < 3 || vData.length < stride) continue;

                var numTris = Std.int(idxData.length / 3);
                for (t in 0...numTris) {
                    var i0 = idxData[t * 3];
                    var i1 = idxData[t * 3 + 1];
                    var i2 = idxData[t * 3 + 2];

                    var b0 = i0 * stride;
                    var b1 = i1 * stride;
                    var b2 = i2 * stride;

                    if (b0 + 2 >= vData.length || b1 + 2 >= vData.length || b2 + 2 >= vData.length) continue;

                    // Transform vertex A to world coordinates
                    var p0x = vData[b0], p0y = vData[b0 + 1], p0z = vData[b0 + 2];
                    var vAx = raw[0] * p0x + raw[4] * p0y + raw[8] * p0z + raw[12];
                    var vAy = raw[1] * p0x + raw[5] * p0y + raw[9] * p0z + raw[13];
                    var vAz = raw[2] * p0x + raw[6] * p0y + raw[10] * p0z + raw[14];

                    // Transform vertex B to world coordinates
                    var p1x = vData[b1], p1y = vData[b1 + 1], p1z = vData[b1 + 2];
                    var vBx = raw[0] * p1x + raw[4] * p1y + raw[8] * p1z + raw[12];
                    var vBy = raw[1] * p1x + raw[5] * p1y + raw[9] * p1z + raw[13];
                    var vBz = raw[2] * p1x + raw[6] * p1y + raw[10] * p1z + raw[14];

                    // Transform vertex C to world coordinates
                    var p2x = vData[b2], p2y = vData[b2 + 1], p2z = vData[b2 + 2];
                    var vCx = raw[0] * p2x + raw[4] * p2y + raw[8] * p2z + raw[12];
                    var vCy = raw[1] * p2x + raw[5] * p2y + raw[9] * p2z + raw[13];
                    var vCz = raw[2] * p2x + raw[6] * p2y + raw[10] * p2z + raw[14];

                    // Triangle normal: (C - B) x (A - B)
                    var cb_x = vCx - vBx; var cb_y = vCy - vBy; var cb_z = vCz - vBz;
                    var ab_x = vAx - vBx; var ab_y = vAy - vBy; var ab_z = vAz - vBz;
                    var nx = cb_y * ab_z - cb_z * ab_y;
                    var ny = cb_z * ab_x - cb_x * ab_z;
                    var nz = cb_x * ab_y - cb_y * ab_x;
                    var nLenSq = nx * nx + ny * ny + nz * nz;
                    if (nLenSq < 1e-8) continue;
                    var invN = 1.0 / Math.sqrt(nLenSq);
                    nx *= invN; ny *= invN; nz *= invN;

                    var tri = new ColTriangle();
                    tri.ax = vAx; tri.ay = vAy; tri.az = vAz;
                    tri.bx = vBx; tri.by = vBy; tri.bz = vBz;
                    tri.cx = vCx; tri.cy = vCy; tri.cz = vCz;
                    tri.nx = nx;  tri.ny = ny;  tri.nz = nz;

                    var minX = Math.min(vAx, Math.min(vBx, vCx));
                    var maxX = Math.max(vAx, Math.max(vBx, vCx));
                    var minY = Math.min(vAy, Math.min(vBy, vCy));
                    var maxY = Math.max(vAy, Math.max(vBy, vCy));
                    var minZ = Math.min(vAz, Math.min(vBz, vCz));
                    var maxZ = Math.max(vAz, Math.max(vBz, vCz));

                    tri.minX = minX; tri.maxX = maxX;
                    tri.minY = minY; tri.maxY = maxY;
                    tri.minZ = minZ; tri.maxZ = maxZ;

                    triangles.push(tri);

                    var minCx = Math.floor(minX / cellSize);
                    var maxCx = Math.floor(maxX / cellSize);
                    var minCy = Math.floor(minY / cellSize);
                    var maxCy = Math.floor(maxY / cellSize);
                    var minCz = Math.floor(minZ / cellSize);
                    var maxCz = Math.floor(maxZ / cellSize);

                    for (cx in minCx...maxCx + 1) {
                        for (cy in minCy...maxCy + 1) {
                            for (cz in minCz...maxCz + 1) {
                                var cellKey = cx + "_" + cy + "_" + cz;
                                var list = cells.get(cellKey);
                                if (list == null) {
                                    list = [];
                                    cells.set(cellKey, list);
                                }
                                list.push(tri);
                            }
                        }
                    }
                }
            }
        }
        initialized = true;
    }

    public function getCandidateTriangles(cx:Float, cy:Float, cz:Float, radius:Float):Array<ColTriangle> {
        var minCx = Math.floor((cx - radius) / cellSize);
        var maxCx = Math.floor((cx + radius) / cellSize);
        var minCy = Math.floor((cy - radius) / cellSize);
        var maxCy = Math.floor((cy + radius) / cellSize);
        var minCz = Math.floor((cz - radius) / cellSize);
        var maxCz = Math.floor((cz + radius) / cellSize);

        queryTag++;
        candidates.resize(0);

        for (x in minCx...maxCx + 1) {
            for (y in minCy...maxCy + 1) {
                for (z in minCz...maxCz + 1) {
                    var cellKey = x + "_" + y + "_" + z;
                    var list = cells.get(cellKey);
                    if (list != null) {
                        for (i in 0...list.length) {
                            var tri = list[i];
                            if (tri.lastQueryTag != queryTag) {
                                tri.lastQueryTag = queryTag;
                                candidates.push(tri);
                            }
                        }
                    }
                }
            }
        }
        return candidates;
    }
}

/**
 * SphereCollision provides robust 3D sphere sliding collision detection against polygon meshes.
 * Matches Flare3D AS3 and TypeScript implementation.
 */
class SphereCollision {
    public var source:Pivot3D;
    public var target(get, set):Pivot3D;
    private inline function get_target():Pivot3D return source;
    private inline function set_target(v:Pivot3D):Pivot3D return source = v;

    public var radius:Float = 25.0;
    public var offset:Vector3D = new Vector3D(0, 0, 0);
    public var colliders:Array<Pivot3D> = [];
    public var data:Array<CollisionInfo> = [];

    private var _grid:SpatialTriangleGrid = new SpatialTriangleGrid();
    private var _closestPoint:ColPoint = new ColPoint();
    private var _tempVec:Vector3D = new Vector3D();

    public function new(sourceOrRadius:Dynamic = null, radius:Float = 25.0, offset:Vector3D = null) {
        if (Std.isOfType(sourceOrRadius, Pivot3D)) {
            this.source = cast sourceOrRadius;
            this.radius = radius;
            this.offset = (offset != null) ? offset : new Vector3D(0, 0, 0);
        } else if (Std.isOfType(sourceOrRadius, Float) || Std.isOfType(sourceOrRadius, Int)) {
            this.radius = cast(sourceOrRadius, Float);
            this.offset = (offset != null) ? offset : new Vector3D(0, 0, 0);
        } else {
            this.radius = radius;
            this.offset = (offset != null) ? offset : new Vector3D(0, 0, 0);
        }
    }

    public function addCollisionWith(pivot:Pivot3D, includeChildren:Bool = true):Void {
        if (pivot == null) return;
        if (colliders.indexOf(pivot) == -1) {
            colliders.push(pivot);
            _grid.initialized = false;
        }
    }

    public function removeCollisionWith(pivot:Pivot3D, includeChildren:Bool = true):Void {
        if (pivot == null) return;
        var idx = colliders.indexOf(pivot);
        if (idx != -1) {
            colliders.splice(idx, 1);
            _grid.initialized = false;
        }
    }

    public function reset():Void {
        data = [];
    }

    /**
     * Computes closest point on triangle ABC to point P using Christer Ericson's algorithm.
     */
    private static function closestPointOnTriangle(
        px:Float, py:Float, pz:Float,
        ax:Float, ay:Float, az:Float,
        bx:Float, by:Float, bz:Float,
        cx:Float, cy:Float, cz:Float,
        out:ColPoint
    ):Void {
        var ab_x = bx - ax; var ab_y = by - ay; var ab_z = bz - az;
        var ac_x = cx - ax; var ac_y = cy - ay; var ac_z = cz - az;
        var ap_x = px - ax; var ap_y = py - ay; var ap_z = pz - az;

        var d1 = ab_x * ap_x + ab_y * ap_y + ab_z * ap_z;
        var d2 = ac_x * ap_x + ac_y * ap_y + ac_z * ap_z;
        if (d1 <= 0 && d2 <= 0) {
            out.x = ax; out.y = ay; out.z = az;
            return;
        }

        var bp_x = px - bx; var bp_y = py - by; var bp_z = pz - bz;
        var d3 = ab_x * bp_x + ab_y * bp_y + ab_z * bp_z;
        var d4 = ac_x * bp_x + ac_y * bp_y + ac_z * bp_z;
        if (d3 >= 0 && d4 <= d3) {
            out.x = bx; out.y = by; out.z = bz;
            return;
        }

        var vc = d1 * d4 - d3 * d2;
        if (vc <= 0 && d1 >= 0 && d3 <= 0) {
            var denom = d1 - d3;
            var v = (denom > 1e-8) ? (d1 / denom) : 0.0;
            out.x = ax + v * ab_x;
            out.y = ay + v * ab_y;
            out.z = az + v * ab_z;
            return;
        }

        var cp_x = px - cx; var cp_y = py - cy; var cp_z = pz - cz;
        var d5 = ab_x * cp_x + ab_y * cp_y + ab_z * cp_z;
        var d6 = ac_x * cp_x + ac_y * cp_y + ac_z * cp_z;
        if (d6 >= 0 && d5 <= d6) {
            out.x = cx; out.y = cy; out.z = cz;
            return;
        }

        var vb = d5 * d2 - d1 * d6;
        if (vb <= 0 && d2 >= 0 && d6 <= 0) {
            var denom = d2 - d6;
            var w = (denom > 1e-8) ? (d2 / denom) : 0.0;
            out.x = ax + w * ac_x;
            out.y = ay + w * ac_y;
            out.z = az + w * ac_z;
            return;
        }

        var va = d3 * d6 - d5 * d4;
        if (va <= 0 && (d4 - d3) >= 0 && (d5 - d6) >= 0) {
            var denom = (d4 - d3) + (d5 - d6);
            var w = (denom > 1e-8) ? ((d4 - d3) / denom) : 0.0;
            out.x = bx + w * (cx - bx);
            out.y = by + w * (cy - by);
            out.z = bz + w * (cz - bz);
            return;
        }

        var denom = va + vb + vc;
        if (denom > 1e-8) {
            var invDenom = 1.0 / denom;
            var v = vb * invDenom;
            var w = vc * invDenom;
            out.x = ax + ab_x * v + ac_x * w;
            out.y = ay + ab_y * v + ac_y * w;
            out.z = az + ab_z * v + ac_z * w;
        } else {
            out.x = ax; out.y = ay; out.z = az;
        }
    }

    /**
     * Tests 3D sphere collision against all collider meshes and adjusts target position to slide along surfaces.
     * Returns true if any collision occurred.
     */
    public function slider():Bool {
        data = [];
        if (source == null) return false;

        // Initialize spatial acceleration grid if needed
        if (!_grid.initialized) {
            var meshes:Array<Mesh3D> = [];
            for (collider in colliders) {
                if (collider == null) continue;
                collider.forEach(function(node:Dynamic) {
                    if (Std.isOfType(node, Mesh3D)) {
                        meshes.push(cast node);
                    }
                });
            }
            if (meshes.length > 0) {
                _grid.buildFromMeshes(meshes);
            }
        }

        var hasOffset = (offset != null && (offset.x != 0 || offset.y != 0 || offset.z != 0));
        var pX = source.x;
        var pY = source.y;
        var pZ = source.z;

        var curX:Float, curY:Float, curZ:Float;
        if (hasOffset) {
            source.localToGlobal(offset, _tempVec);
            curX = _tempVec.x; curY = _tempVec.y; curZ = _tempVec.z;
        } else {
            curX = pX; curY = pY; curZ = pZ;
        }

        if (!_grid.initialized || _grid.triangles.length == 0) {
            // Fallback ground plane collision at y = 0
            if (curY <= radius) {
                var pen = radius - curY;
                curY = radius;
                if (hasOffset) {
                    source.setPosition(pX, pY + pen, pZ);
                } else {
                    source.setPosition(curX, curY, curZ);
                }
                data.push(new CollisionInfo(new Vector3D(curX, 0, curZ), new Vector3D(0, 1, 0), pen, source));
                return true;
            }
            return false;
        }

        var collided = false;
        var rSq = radius * radius;

        // Iterate 3 sliding passes to resolve corner seams and multi-surface intersections
        for (pass in 0...3) {
            var candidates = _grid.getCandidateTriangles(curX, curY, curZ, radius);
            for (i in 0...candidates.length) {
                var tri = candidates[i];

                // Fast AABB rejection
                if (tri.maxX < curX - radius || tri.minX > curX + radius ||
                    tri.maxY < curY - radius || tri.minY > curY + radius ||
                    tri.maxZ < curZ - radius || tri.minZ > curZ + radius) {
                    continue;
                }

                closestPointOnTriangle(
                    curX, curY, curZ,
                    tri.ax, tri.ay, tri.az,
                    tri.bx, tri.by, tri.bz,
                    tri.cx, tri.cy, tri.cz,
                    _closestPoint
                );

                var dx = curX - _closestPoint.x;
                var dy = curY - _closestPoint.y;
                var dz = curZ - _closestPoint.z;
                var distSq = dx * dx + dy * dy + dz * dz;

                if (distSq < rSq) {
                    var dist = Math.sqrt(distSq);
                    var normX:Float, normY:Float, normZ:Float;
                    var pen:Float;

                    if (dist > 1e-4) {
                        var invDist = 1.0 / dist;
                        normX = dx * invDist;
                        normY = dy * invDist;
                        normZ = dz * invDist;
                        pen = radius - dist;
                    } else {
                        normX = tri.nx;
                        normY = tri.ny;
                        normZ = tri.nz;
                        pen = radius;
                    }

                    // Push sphere out along normal
                    curX += normX * pen;
                    curY += normY * pen;
                    curZ += normZ * pen;

                    data.push(new CollisionInfo(
                        new Vector3D(_closestPoint.x, _closestPoint.y, _closestPoint.z),
                        new Vector3D(normX, normY, normZ),
                        dist,
                        source
                    ));
                    collided = true;
                }
            }
        }

        if (collided) {
            if (hasOffset) {
                var deltaX = curX - _tempVec.x;
                var deltaY = curY - _tempVec.y;
                var deltaZ = curZ - _tempVec.z;
                source.setPosition(pX + deltaX, pY + deltaY, pZ + deltaZ);
            } else {
                source.setPosition(curX, curY, curZ);
            }
        }

        return collided;
    }
}
