package flare.primitives;

import openfl.Vector;
import flare.core.Mesh3D;
import flare.core.Surface3D;
import flare.materials.Material3D;

/**
 * Cylinder generates a procedural 3D cylinder.
 */
class Cylinder extends Mesh3D {
    public function new(name:String = "cylinder", radius:Float = 25, height:Float = 100, segments:Int = 16, material:Material3D = null) {
        super(name);

        var surface = new Surface3D(name + "_surf");
        var vData = surface.vertexData;
        var iData = surface.indexData;

        var hh = height * 0.5;

        // Side vertices
        for (j in 0...2) {
            var y = j == 0 ? -hh : hh;
            var v = j == 0 ? 1.0 : 0.0;

            for (i in 0...(segments + 1)) {
                var u = i / segments;
                var angle = u * Math.PI * 2.0;
                var x = radius * Math.cos(angle);
                var z = radius * Math.sin(angle);

                vData.push(x); vData.push(y); vData.push(z);
                vData.push(u); vData.push(v);
                vData.push(x / radius); vData.push(0); vData.push(z / radius);
            }
        }

        var rowStride = segments + 1;
        for (i in 0...segments) {
            var i0:UInt = i;
            var i1:UInt = rowStride + i;
            var i2:UInt = rowStride + (i + 1);
            var i3:UInt = i + 1;

            iData.push(i0); iData.push(i1); iData.push(i2);
            iData.push(i0); iData.push(i2); iData.push(i3);
        }

        addSurface(surface, material);
    }
}
