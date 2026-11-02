package flare.primitives;

import flare.core.Mesh3D;
import flare.core.Surface3D;
import flare.materials.Material3D;
import flare.materials.Shader3D;
import flare.materials.filters.ColorFilter;

/**
 * Capsule generates a 3D capsule primitive (cylinder with hemispherical caps).
 */
class Capsule extends Mesh3D {
    public function new(name:String = "capsule", radius:Float = 3, height:Float = 10, segments:Int = 12, material:Material3D = null) {
        super(name);

        var surf = new Surface3D(name + "_surf");
        var halfH = height * 0.5;

        // Generate cylinder body + hemisphere caps
        var rings = segments;
        for (i in 0...(rings + 1)) {
            var phi = (i / rings) * Math.PI;
            var yOffset = (i <= rings / 2) ? halfH : -halfH;
            var y = Math.cos(phi) * radius + yOffset;
            var r = Math.sin(phi) * radius;

            for (j in 0...(segments + 1)) {
                var theta = (j / segments) * Math.PI * 2;
                var x = Math.cos(theta) * r;
                var z = Math.sin(theta) * r;
                var u = j / segments;
                var v = i / rings;

                var nx = x / radius;
                var ny = (y - yOffset) / radius;
                var nz = z / radius;

                surf.vertexData.push(x);
                surf.vertexData.push(y);
                surf.vertexData.push(z);
                surf.vertexData.push(nx);
                surf.vertexData.push(ny);
                surf.vertexData.push(nz);
                surf.vertexData.push(u);
                surf.vertexData.push(v);
            }
        }

        var stride = segments + 1;
        for (i in 0...rings) {
            for (j in 0...segments) {
                var p0 = i * stride + j;
                var p1 = p0 + 1;
                var p2 = (i + 1) * stride + j;
                var p3 = p2 + 1;

                surf.indexData.push(p0);
                surf.indexData.push(p2);
                surf.indexData.push(p1);

                surf.indexData.push(p1);
                surf.indexData.push(p2);
                surf.indexData.push(p3);
            }
        }

        var mat = material != null ? material : new Shader3D(name + "_mat", [new ColorFilter(0xCCCCCC)]);
        addSurface(surf, mat);
    }
}
