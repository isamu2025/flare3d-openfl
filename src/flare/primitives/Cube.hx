package flare.primitives;

import openfl.Vector;
import flare.core.Mesh3D;
import flare.core.Surface3D;
import flare.materials.Material3D;

/**
 * Cube generates a procedural 6-sided 3D rectangular cuboid.
 * Also known as Box in some engines.
 */
class Cube extends Mesh3D {
    public var width:Float;
    public var height:Float;
    public var depth:Float;
    public var segments:Int;

    public function new(name:String = "cube", width:Float = 10, height:Float = 10, depth:Float = 10, segments:Int = 1, material:Material3D = null) {
        super(name);

        this.width = width;
        this.height = height;
        this.depth = depth;
        this.segments = segments;

        var surface = new Surface3D(name + "_surf");
        var vData = surface.vertexData;
        var iData = surface.indexData;

        var hw = width * 0.5;
        var hh = height * 0.5;
        var hd = depth * 0.5;

        // Helper to add a quad face
        function addFace(
            x0:Float, y0:Float, z0:Float, u0:Float, v0:Float,
            x1:Float, y1:Float, z1:Float, u1:Float, v1:Float,
            x2:Float, y2:Float, z2:Float, u2:Float, v2:Float,
            x3:Float, y3:Float, z3:Float, u3:Float, v3:Float,
            nx:Float, ny:Float, nz:Float
        ) {
            var baseIndex:UInt = Std.int(vData.length / 8);

            // Vertex 0
            vData.push(x0); vData.push(y0); vData.push(z0);
            vData.push(u0); vData.push(v0);
            vData.push(nx); vData.push(ny); vData.push(nz);

            // Vertex 1
            vData.push(x1); vData.push(y1); vData.push(z1);
            vData.push(u1); vData.push(v1);
            vData.push(nx); vData.push(ny); vData.push(nz);

            // Vertex 2
            vData.push(x2); vData.push(y2); vData.push(z2);
            vData.push(u2); vData.push(v2);
            vData.push(nx); vData.push(ny); vData.push(nz);

            // Vertex 3
            vData.push(x3); vData.push(y3); vData.push(z3);
            vData.push(u3); vData.push(v3);
            vData.push(nx); vData.push(ny); vData.push(nz);

            // 2 triangles
            iData.push(baseIndex + 0);
            iData.push(baseIndex + 1);
            iData.push(baseIndex + 2);

            iData.push(baseIndex + 0);
            iData.push(baseIndex + 2);
            iData.push(baseIndex + 3);
        }

        // Front Face (+Z)
        addFace(-hw, -hh,  hd, 0, 1,   hw, -hh,  hd, 1, 1,   hw,  hh,  hd, 1, 0,  -hw,  hh,  hd, 0, 0,   0, 0, 1);
        // Back Face (-Z)
        addFace( hw, -hh, -hd, 0, 1,  -hw, -hh, -hd, 1, 1,  -hw,  hh, -hd, 1, 0,   hw,  hh, -hd, 0, 0,   0, 0, -1);
        // Top Face (+Y)
        addFace(-hw,  hh,  hd, 0, 1,   hw,  hh,  hd, 1, 1,   hw,  hh, -hd, 1, 0,  -hw,  hh, -hd, 0, 0,   0, 1, 0);
        // Bottom Face (-Y)
        addFace(-hw, -hh, -hd, 0, 1,   hw, -hh, -hd, 1, 1,   hw, -hh,  hd, 1, 0,  -hw, -hh,  hd, 0, 0,   0, -1, 0);
        // Right Face (+X)
        addFace( hw, -hh,  hd, 0, 1,   hw, -hh, -hd, 1, 1,   hw,  hh, -hd, 1, 0,   hw,  hh,  hd, 0, 0,   1, 0, 0);
        // Left Face (-X)
        addFace(-hw, -hh, -hd, 0, 1,  -hw, -hh,  hd, 1, 1,  -hw,  hh,  hd, 1, 0,  -hw,  hh, -hd, 0, 0,  -1, 0, 0);

        addSurface(surface, material);
    }
}
