package flare.primitives;

import openfl.Vector;
import flare.core.Mesh3D;
import flare.core.Surface3D;
import flare.materials.Material3D;

/**
 * Cone generates a procedural 3D cone mesh.
 */
class Cone extends Mesh3D {
    public function new(name:String = "cone", radius:Float = 25, height:Float = 100, segments:Int = 16, material:Material3D = null) {
        super(name);

        var surface = new Surface3D(name + "_surf");
        var vData = surface.vertexData;
        var iData = surface.indexData;

        var hh = height * 0.5;

        // Base center
        var baseCenterIdx:UInt = Std.int(vData.length / 8);
        vData.push(0); vData.push(-hh); vData.push(0);
        vData.push(0.5); vData.push(0.5);
        vData.push(0); vData.push(-1); vData.push(0);

        // Apex top
        var apexIdx:UInt = Std.int(vData.length / 8);
        vData.push(0); vData.push(hh); vData.push(0);
        vData.push(0.5); vData.push(0);
        vData.push(0); vData.push(1); vData.push(0);

        var startRing:UInt = Std.int(vData.length / 8);
        for (i in 0...(segments + 1)) {
            var u = i / segments;
            var angle = u * Math.PI * 2.0;
            var x = radius * Math.cos(angle);
            var z = radius * Math.sin(angle);

            vData.push(x); vData.push(-hh); vData.push(z);
            vData.push(u); vData.push(1);
            vData.push(x / radius); vData.push(0.5); vData.push(z / radius);
        }

        for (i in 0...segments) {
            var i0:UInt = startRing + i;
            var i1:UInt = startRing + (i + 1);

            // Apex triangle
            iData.push(apexIdx); iData.push(i0); iData.push(i1);

            // Base triangle
            iData.push(baseCenterIdx); iData.push(i1); iData.push(i0);
        }

        addSurface(surface, material);
    }
}
