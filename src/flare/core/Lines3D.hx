package flare.core;

import openfl.geom.Vector3D;
import flare.materials.Material3D;
import flare.materials.Shader3D;
import flare.materials.filters.ColorFilter;

/**
 * Lines3D renders segmented 3D lines, paths, and debug vectors.
 */
class Lines3D extends Mesh3D {
    private var _surface:Surface3D;
    private var _colorFilter:ColorFilter;
    private var _shader:Shader3D;

    private var _thickness:Float = 1.0;
    private var _color:Int = 0xffffff;
    private var _alpha:Float = 1.0;

    private var _currX:Float = 0.0;
    private var _currY:Float = 0.0;
    private var _currZ:Float = 0.0;

    public function new(name:String = "lines", color:Int = 0xffffff, alpha:Float = 1.0, thickness:Float = 1.0) {
        super(name);

        _color = color;
        _alpha = alpha;
        _thickness = (thickness > 0) ? thickness : 1.0;

        _surface = new Surface3D(name + "_surf");
        _colorFilter = new ColorFilter(_color, _alpha);
        _shader = new Shader3D(name + "_mat", [_colorFilter]);
        _shader.twoSided = true;
        _shader.enableLights = false;
        addSurface(_surface, _shader);
    }

    public function lineStyle(thickness:Float = 1.0, color:Int = 0xffffff, alpha:Float = 1.0):Void {
        _thickness = (thickness > 0) ? thickness : 1.0;
        _color = color;
        _alpha = alpha;
        _colorFilter.setColor(_color);
        _colorFilter.alpha = _alpha;
    }

    public function setColor(r:Float, g:Float, b:Float, a:Float = 1.0):Void {
        _colorFilter.r = r;
        _colorFilter.g = g;
        _colorFilter.b = b;
        _colorFilter.alpha = a;
    }

    public function moveTo(x:Float, y:Float, z:Float):Void {
        _currX = x;
        _currY = y;
        _currZ = z;
        _surface.invalidate();
    }

    public function lineTo(x:Float, y:Float, z:Float, ?x1:Float, ?y1:Float, ?z1:Float, ?thickness:Float):Void {
        if (x1 != null && y1 != null && z1 != null) {
            if (thickness != null && thickness > 0) {
                _thickness = thickness;
            }
            moveTo(x, y, z);
            _drawLineSegment(x1, y1, z1);
        } else {
            _drawLineSegment(x, y, z);
        }
    }

    private function _drawLineSegment(x:Float, y:Float, z:Float):Void {
        var dx = x - _currX;
        var dy = y - _currY;
        var dz = z - _currZ;
        var len = Math.sqrt(dx * dx + dy * dy + dz * dz);
        if (len < 0.00001) {
            _currX = x;
            _currY = y;
            _currZ = z;
            return;
        }

        var nx = dx / len;
        var ny = dy / len;
        var nz = dz / len;

        // Choose up vector not parallel to direction
        var ux:Float = 0;
        var uy:Float = 1;
        var uz:Float = 0;
        if (Math.abs(ny) > 0.95) {
            ux = 1;
            uy = 0;
            uz = 0;
        }

        // Cross product P = N x U
        var px = ny * uz - nz * uy;
        var py = nz * ux - nx * uz;
        var pz = nx * uy - ny * ux;
        var pLen = Math.sqrt(px * px + py * py + pz * pz);
        if (pLen > 0.00001) {
            px /= pLen;
            py /= pLen;
            pz /= pLen;
        }

        var hw = _thickness * 0.75;
        var p1x = px * hw;
        var p1y = py * hw;
        var p1z = pz * hw;

        // Cross product Q = N x P
        var qx = ny * pz - nz * py;
        var qy = nz * px - nx * pz;
        var qz = nx * py - ny * px;
        var q1x = qx * hw;
        var q1y = qy * hw;
        var q1z = qz * hw;

        var vData = _surface.vertexData;
        var iData = _surface.indexData;
        var baseIdx:UInt = Std.int(vData.length / 8);

        // Quad 1 (along P)
        vData.push(_currX - p1x); vData.push(_currY - p1y); vData.push(_currZ - p1z);
        vData.push(0); vData.push(0); vData.push(0); vData.push(1); vData.push(0);

        vData.push(_currX + p1x); vData.push(_currY + p1y); vData.push(_currZ + p1z);
        vData.push(1); vData.push(0); vData.push(0); vData.push(1); vData.push(0);

        vData.push(x + p1x); vData.push(y + p1y); vData.push(z + p1z);
        vData.push(1); vData.push(1); vData.push(0); vData.push(1); vData.push(0);

        vData.push(x - p1x); vData.push(y - p1y); vData.push(z - p1z);
        vData.push(0); vData.push(1); vData.push(0); vData.push(1); vData.push(0);

        iData.push(baseIdx + 0); iData.push(baseIdx + 1); iData.push(baseIdx + 2);
        iData.push(baseIdx + 0); iData.push(baseIdx + 2); iData.push(baseIdx + 3);

        // Quad 2 (along Q)
        vData.push(_currX - q1x); vData.push(_currY - q1y); vData.push(_currZ - q1z);
        vData.push(0); vData.push(0); vData.push(0); vData.push(1); vData.push(0);

        vData.push(_currX + q1x); vData.push(_currY + q1y); vData.push(_currZ + q1z);
        vData.push(1); vData.push(0); vData.push(0); vData.push(1); vData.push(0);

        vData.push(x + q1x); vData.push(y + q1y); vData.push(z + q1z);
        vData.push(1); vData.push(1); vData.push(0); vData.push(1); vData.push(0);

        vData.push(x - q1x); vData.push(y - q1y); vData.push(z - q1z);
        vData.push(0); vData.push(1); vData.push(0); vData.push(1); vData.push(0);

        iData.push(baseIdx + 4); iData.push(baseIdx + 5); iData.push(baseIdx + 6);
        iData.push(baseIdx + 4); iData.push(baseIdx + 6); iData.push(baseIdx + 7);

        _currX = x;
        _currY = y;
        _currZ = z;
    }

    public function clear():Void {
        _surface.vertexData.length = 0;
        _surface.indexData.length = 0;
        _surface.invalidate();
    }
}
