package flare.primitives;

import openfl.Vector;
import flare.core.Mesh3D;
import flare.core.Surface3D;
import flare.materials.Material3D;

/**
 * Torus generates a procedural 3D ring (donut) mesh.
 */
class Torus extends Mesh3D {
    public function new(name:String = "torus", radius:Float = 40, tubeRadius:Float = 12, segmentsR:Int = 16, segmentsT:Int = 12, material:Material3D = null) {
        super(name);

        var surface = new Surface3D(name + "_surf");
        var vData = surface.vertexData;
        var iData = surface.indexData;

        for (j in 0...(segmentsT + 1)) {
            var v = j / segmentsT;
            var phi = v * Math.PI * 2.0;

            for (i in 0...(segmentsR + 1)) {
                var u = i / segmentsR;
                var theta = u * Math.PI * 2.0;

                var x = (radius + tubeRadius * Math.cos(phi)) * Math.cos(theta);
                var y = tubeRadius * Math.sin(phi);
                var z = (radius + tubeRadius * Math.cos(phi)) * Math.sin(theta);

                var nx = Math.cos(phi) * Math.cos(theta);
                var ny = Math.sin(phi);
                var nz = Math.cos(phi) * Math.sin(theta);

                vData.push(x); vData.push(y); vData.push(z);
                vData.push(u); vData.push(v);
                vData.push(nx); vData.push(ny); vData.push(nz);
            }
        }

        var rowStride = segmentsR + 1;
        for (j in 0...segmentsT) {
            for (i in 0...segmentsR) {
                var i0:UInt = j * rowStride + i;
                var i1:UInt = (j + 1) * rowStride + i;
                var i2:UInt = (j + 1) * rowStride + (i + 1);
                var i3:UInt = j * rowStride + (i + 1);

                iData.push(i0); iData.push(i1); iData.push(i2);
                iData.push(i0); iData.push(i2); iData.push(i3);
            }
        }

        addSurface(surface, material);
    }
}
