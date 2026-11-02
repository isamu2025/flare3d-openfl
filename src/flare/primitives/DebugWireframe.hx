package flare.primitives;

import flare.core.Mesh3D;
import flare.core.Lines3D;

/**
 * DebugWireframe overlays a wireframe rendering on top of a 3D mesh.
 */
class DebugWireframe extends Lines3D {
    public var mesh:Mesh3D;

    public function new(mesh:Mesh3D = null, color:Int = 0xffffff, alpha:Float = 1.0) {
        super(mesh != null ? mesh.name + "_wireframe" : "wireframe", color, alpha);
        this.mesh = mesh;

        if (mesh != null) {
            buildFromMesh(mesh);
        }
    }

    public function buildFromMesh(mesh:Mesh3D):Void {
        clear();
        lineStyle(1, _color, _alpha);

        for (surf in mesh.surfaces) {
            var vData = surf.vertexData;
            var iData = surf.indexData;
            var stride = surf.vertexStride > 0 ? surf.vertexStride : 8;
            var numTris = Std.int(iData.length / 3);
            for (t in 0...numTris) {
                var i0 = iData[t * 3] * stride;
                var i1 = iData[t * 3 + 1] * stride;
                var i2 = iData[t * 3 + 2] * stride;

                var x0 = vData[i0]; var y0 = vData[i0 + 1]; var z0 = vData[i0 + 2];
                var x1 = vData[i1]; var y1 = vData[i1 + 1]; var z1 = vData[i1 + 2];
                var x2 = vData[i2]; var y2 = vData[i2 + 1]; var z2 = vData[i2 + 2];

                moveTo(x0, y0, z0);
                lineTo(x1, y1, z1);
                lineTo(x2, y2, z2);
                lineTo(x0, y0, z0);
            }
        }
    }
}
