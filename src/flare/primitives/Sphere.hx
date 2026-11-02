package flare.primitives;

import openfl.Vector;
import flare.core.Mesh3D;
import flare.core.Surface3D;
import flare.materials.Material3D;

/**
 * Sphere generates a procedural UV sphere mesh.
 */
class Sphere extends Mesh3D {
    public var radius:Float = 50;

    public function new(name:String = "sphere", radius:Float = 50, segments:Dynamic = 16, arg4:Dynamic = null, arg5:Dynamic = null) {
        super(name);
        this.radius = radius;

        var segmentsW:Int = 16;
        var segmentsH:Int = 12;
        var mat:Material3D = null;

        if (Std.isOfType(arg4, Int)) {
            segmentsW = Std.int(segments);
            segmentsH = cast arg4;
            if (Std.isOfType(arg5, Material3D)) mat = cast arg5;
        } else {
            segmentsW = Std.int(segments);
            segmentsH = Std.int(segments);
            if (Std.isOfType(arg4, Material3D)) mat = cast arg4;
            else if (Std.isOfType(arg5, Material3D)) mat = cast arg5;
        }

        if (segmentsW < 3) segmentsW = 3;
        if (segmentsH < 2) segmentsH = 2;

        var surface = new Surface3D(name + "_surf");
        var vData = surface.vertexData;
        var iData = surface.indexData;

        for (j in 0...(segmentsH + 1)) {
            var v = j / segmentsH;
            var theta = v * Math.PI;

            for (i in 0...(segmentsW + 1)) {
                var u = i / segmentsW;
                var phi = u * Math.PI * 2.0;

                var x = -radius * Math.sin(theta) * Math.sin(phi);
                var y = radius * Math.cos(theta);
                var z = -radius * Math.sin(theta) * Math.cos(phi);

                var nx = x / radius;
                var ny = y / radius;
                var nz = z / radius;

                // Pos(3)
                vData.push(x); vData.push(y); vData.push(z);
                // UV(2)
                vData.push(u); vData.push(v);
                // Normal(3)
                vData.push(nx); vData.push(ny); vData.push(nz);
            }
        }

        var rowStride = segmentsW + 1;
        for (j in 0...segmentsH) {
            for (i in 0...segmentsW) {
                var i0:UInt = j * rowStride + i;
                var i1:UInt = (j + 1) * rowStride + i;
                var i2:UInt = (j + 1) * rowStride + (i + 1);
                var i3:UInt = j * rowStride + (i + 1);

                iData.push(i0);
                iData.push(i2);
                iData.push(i1);

                iData.push(i0);
                iData.push(i3);
                iData.push(i2);
            }
        }

        if (mat == null) {
            mat = Mesh3D.getDefaultMaterial();
        }
        mat.twoSided = true;
        addSurface(surface, mat);
    }

    override public function cloneBasic():flare.core.Pivot3D {
        var s = new Sphere(name, radius);
        s.surfaces = [];
        s.materials = [];
        copyTo(s);
        return s;
    }

    override public function copyTo(target:flare.core.Pivot3D):Void {
        super.copyTo(target);
        if (Std.isOfType(target, Sphere)) {
            var s:Sphere = cast target;
            s.radius = this.radius;
        }
    }
}
