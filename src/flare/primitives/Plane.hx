package flare.primitives;

import openfl.Vector;
import flare.core.Mesh3D;
import flare.core.Surface3D;
import flare.materials.Material3D;

/**
 * Plane generates a flat 2D procedural plane in 3D space.
 */
class Plane extends Mesh3D {
    public var width:Float = 100;
    public var depth:Float = 100;

    public function new(name:String = "plane", width:Float = 100, depth:Float = 100, segments:Dynamic = 1, arg5:Dynamic = null, arg6:Dynamic = null) {
        super(name);
        this.width = width;
        this.depth = depth;

        var segmentsW:Int = 1;
        var segmentsH:Int = 1;
        var mat:Material3D = null;
        var dir:String = "+xy";

        if (Std.isOfType(arg5, Int)) {
            segmentsW = Std.int(segments);
            segmentsH = cast arg5;
            if (Std.isOfType(arg6, Material3D)) mat = cast arg6;
            else if (Std.isOfType(arg6, String)) dir = cast arg6;
        } else {
            segmentsW = Std.int(segments);
            segmentsH = Std.int(segments);
            if (Std.isOfType(arg5, Material3D)) mat = cast arg5;
            if (Std.isOfType(arg6, String)) dir = cast arg6;
        }

        if (segmentsW < 1) segmentsW = 1;
        if (segmentsH < 1) segmentsH = 1;

        var surface = new Surface3D(name + "_surf");
        var vData = surface.vertexData;
        var iData = surface.indexData;

        var hw = width * 0.5;
        var hd = depth * 0.5;

        for (j in 0...(segmentsH + 1)) {
            var fraction = j / segmentsH;
            var v = 1.0 - fraction;
            var d = -hd + fraction * depth;

            for (i in 0...(segmentsW + 1)) {
                var u = i / segmentsW;
                var w = -hw + u * width;

                if (dir == "+xz") {
                    vData.push(w); vData.push(0); vData.push(d);
                    vData.push(u); vData.push(v);
                    vData.push(0); vData.push(1); vData.push(0);
                } else if (dir == "-xz") {
                    vData.push(w); vData.push(0); vData.push(d);
                    vData.push(u); vData.push(v);
                    vData.push(0); vData.push(-1); vData.push(0);
                } else if (dir == "+yz") {
                    vData.push(0); vData.push(d); vData.push(w);
                    vData.push(u); vData.push(v);
                    vData.push(1); vData.push(0); vData.push(0);
                } else if (dir == "-yz") {
                    vData.push(0); vData.push(d); vData.push(w);
                    vData.push(u); vData.push(v);
                    vData.push(-1); vData.push(0); vData.push(0);
                } else if (dir == "-xy") {
                    vData.push(w); vData.push(d); vData.push(0);
                    vData.push(u); vData.push(v);
                    vData.push(0); vData.push(0); vData.push(-1);
                } else {
                    // "+xy" default
                    vData.push(w); vData.push(d); vData.push(0);
                    vData.push(u); vData.push(v);
                    vData.push(0); vData.push(0); vData.push(1);
                }
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

                // Two-sided indices so plane is visible from both top and bottom
                iData.push(i0);
                iData.push(i1);
                iData.push(i2);

                iData.push(i0);
                iData.push(i2);
                iData.push(i3);
            }
        }

        addSurface(surface, mat);
    }

    override public function cloneBasic():flare.core.Pivot3D {
        var p = new Plane(name, width, depth);
        p.surfaces = [];
        p.materials = [];
        copyTo(p);
        return p;
    }

    override public function copyTo(target:flare.core.Pivot3D):Void {
        super.copyTo(target);
        if (Std.isOfType(target, Plane)) {
            var p:Plane = cast target;
            p.width = this.width;
            p.depth = this.depth;
        }
    }
}
