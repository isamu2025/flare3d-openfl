package flare.utils;

import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;

/**
 * Matrix3DUtils provides highly optimized spatial transformations, projections, and matrix calculations.
 */
class Matrix3DUtils {
    private static var _raw:openfl.Vector<Float> = new openfl.Vector<Float>(16, true);
    private static var _v:Vector3D = new Vector3D();

    public static function getPosition(m:Matrix3D, out:Vector3D = null):Vector3D {
        if (out == null) out = new Vector3D();
        m.copyColumnTo(3, out);
        return out;
    }

    public static function setPosition(m:Matrix3D, x:Float, y:Float, z:Float, smooth:Float = 1):Void {
        m.copyColumnTo(3, _v);
        _v.x += (x - _v.x) * smooth;
        _v.y += (y - _v.y) * smooth;
        _v.z += (z - _v.z) * smooth;
        m.copyColumnFrom(3, _v);
    }

    public static function setTranslation(m:Matrix3D, x:Float, y:Float, z:Float):Void {
        _v.setTo(x, y, z);
        _v.w = 1;
        m.copyColumnFrom(3, _v);
    }

    public static function getDir(m:Matrix3D, out:Vector3D = null):Vector3D {
        if (out == null) out = new Vector3D();
        m.copyColumnTo(2, out);
        out.normalize();
        return out;
    }

    public static function getUp(m:Matrix3D, out:Vector3D = null):Vector3D {
        if (out == null) out = new Vector3D();
        m.copyColumnTo(1, out);
        out.normalize();
        return out;
    }

    public static function getRight(m:Matrix3D, out:Vector3D = null):Vector3D {
        if (out == null) out = new Vector3D();
        m.copyColumnTo(0, out);
        out.normalize();
        return out;
    }

    public static function getLeft(m:Matrix3D, out:Vector3D = null):Vector3D {
        var v = getRight(m, out);
        v.negate();
        return v;
    }

    public static function getBackward(m:Matrix3D, out:Vector3D = null):Vector3D {
        var v = getDir(m, out);
        v.negate();
        return v;
    }

    public static function getDown(m:Matrix3D, out:Vector3D = null):Vector3D {
        var v = getUp(m, out);
        v.negate();
        return v;
    }

    public static function getScale(m:Matrix3D, out:Vector3D = null):Vector3D {
        if (out == null) out = new Vector3D();
        m.copyColumnTo(0, _v);
        out.x = _v.length;
        m.copyColumnTo(1, _v);
        out.y = _v.length;
        m.copyColumnTo(2, _v);
        out.z = _v.length;
        return out;
    }

    public static function setScale(m:Matrix3D, x:Float, y:Float, z:Float, smooth:Float = 1):Void {
        var s = getScale(m);
        x = s.x + (x - s.x) * smooth;
        y = s.y + (y - s.y) * smooth;
        z = s.z + (z - s.z) * smooth;

        m.copyColumnTo(0, _v);
        _v.normalize();
        _v.scaleBy(x);
        m.copyColumnFrom(0, _v);

        m.copyColumnTo(1, _v);
        _v.normalize();
        _v.scaleBy(y);
        m.copyColumnFrom(1, _v);

        m.copyColumnTo(2, _v);
        _v.normalize();
        _v.scaleBy(z);
        m.copyColumnFrom(2, _v);
    }

    public static function getRotation(m:Matrix3D, out:Vector3D = null):Vector3D {
        if (out == null) out = new Vector3D();
        var vec = m.decompose();
        if (vec.length > 1) {
            out.x = vec[1].x * 180 / Math.PI;
            out.y = vec[1].y * 180 / Math.PI;
            out.z = vec[1].z * 180 / Math.PI;
        }
        return out;
    }

    public static function setRotation(m:Matrix3D, x:Float, y:Float, z:Float):Void {
        var pos = getPosition(m);
        var scale = getScale(m);
        m.identity();
        m.appendRotation(x, Vector3D.X_AXIS);
        m.appendRotation(y, Vector3D.Y_AXIS);
        m.appendRotation(z, Vector3D.Z_AXIS);
        setScale(m, scale.x, scale.y, scale.z);
        setPosition(m, pos.x, pos.y, pos.z);
    }

    public static function lookAt(m:Matrix3D, x:Float, y:Float, z:Float, up:Vector3D = null, smooth:Float = 1):Void {
        if (up == null) up = Vector3D.Y_AXIS;
        var pos = getPosition(m);
        var dir = new Vector3D(x - pos.x, y - pos.y, z - pos.z);
        if (dir.lengthSquared < 0.00001) return;
        dir.normalize();
        var right = up.crossProduct(dir);
        if (right.lengthSquared < 0.00001) {
            var alt = Math.abs(up.y) > 0.9 ? Vector3D.Z_AXIS : Vector3D.Y_AXIS;
            right = alt.crossProduct(dir);
        }
        right.normalize();
        var realUp = dir.crossProduct(right);
        realUp.normalize();

        right.w = 0; realUp.w = 0; dir.w = 0; pos.w = 1;
        m.copyColumnFrom(0, right);
        m.copyColumnFrom(1, realUp);
        m.copyColumnFrom(2, dir);
        m.copyColumnFrom(3, pos);
    }

    public static function setOrientation(m:Matrix3D, dir:Vector3D, up:Vector3D = null, smooth:Float = 1):Void {
        var pos = getPosition(m);
        lookAt(m, pos.x + dir.x, pos.y + dir.y, pos.z + dir.z, up, smooth);
    }

    private static var _norm:Vector3D = new Vector3D();
    private static var _curUp:Vector3D = new Vector3D();
    private static var _curDir:Vector3D = new Vector3D();
    private static var _fwd:Vector3D = new Vector3D();
    private static var _right:Vector3D = new Vector3D();
    private static var _alt:Vector3D = new Vector3D();

    public static function setNormalOrientation(m:Matrix3D, normal:Vector3D, smooth:Float = 1):Void {
        if (normal == null) return;
        _norm.x = normal.x; _norm.y = normal.y; _norm.z = normal.z;
        if (_norm.lengthSquared < 0.00001) return;
        _norm.normalize();

        var raw = m.rawData;
        _curUp.x = raw[4]; _curUp.y = raw[5]; _curUp.z = raw[6];
        _curUp.normalize();
        if (smooth > 0 && smooth < 1.0) {
            _norm.x = _curUp.x + (_norm.x - _curUp.x) * smooth;
            _norm.y = _curUp.y + (_norm.y - _curUp.y) * smooth;
            _norm.z = _curUp.z + (_norm.z - _curUp.z) * smooth;
            _norm.normalize();
        }

        _curDir.x = raw[8]; _curDir.y = raw[9]; _curDir.z = raw[10];
        _curDir.normalize();

        // Project curDir onto plane perpendicular to norm: forward = curDir - norm * (curDir . norm)
        var dot = _curDir.x * _norm.x + _curDir.y * _norm.y + _curDir.z * _norm.z;
        _fwd.x = _curDir.x - _norm.x * dot;
        _fwd.y = _curDir.y - _norm.y * dot;
        _fwd.z = _curDir.z - _norm.z * dot;
        if (_fwd.lengthSquared < 0.00001) {
            if (Math.abs(_norm.y) > 0.9) {
                _alt.x = 0; _alt.y = 0; _alt.z = 1;
            } else {
                _alt.x = 0; _alt.y = 1; _alt.z = 0;
            }
            var dotAlt = _alt.x * _norm.x + _alt.y * _norm.y + _alt.z * _norm.z;
            _fwd.x = _alt.x - _norm.x * dotAlt;
            _fwd.y = _alt.y - _norm.y * dotAlt;
            _fwd.z = _alt.z - _norm.z * dotAlt;
        }
        _fwd.normalize();

        // Right = norm x forward
        _right.x = _norm.y * _fwd.z - _norm.z * _fwd.y;
        _right.y = _norm.z * _fwd.x - _norm.x * _fwd.z;
        _right.z = _norm.x * _fwd.y - _norm.y * _fwd.x;
        _right.normalize();

        // Recalculate true forward = right x norm
        _fwd.x = _right.y * _norm.z - _right.z * _norm.y;
        _fwd.y = _right.z * _norm.x - _right.x * _norm.z;
        _fwd.z = _right.x * _norm.y - _right.y * _norm.x;
        _fwd.normalize();

        var px = raw[12];
        var py = raw[13];
        var pz = raw[14];

        raw[0] = _right.x; raw[1] = _right.y; raw[2] = _right.z; raw[3] = 0;
        raw[4] = _norm.x;  raw[5] = _norm.y;  raw[6] = _norm.z;  raw[7] = 0;
        raw[8] = _fwd.x;   raw[9] = _fwd.y;   raw[10] = _fwd.z; raw[11] = 0;
        raw[12] = px;      raw[13] = py;      raw[14] = pz;     raw[15] = 1;
        m.copyRawDataFrom(raw);
    }

    public static function translateX(m:Matrix3D, distance:Float, local:Bool = true):Void {
        if (local) m.prependTranslation(distance, 0, 0);
        else m.appendTranslation(distance, 0, 0);
    }

    public static function translateY(m:Matrix3D, distance:Float, local:Bool = true):Void {
        if (local) m.prependTranslation(0, distance, 0);
        else m.appendTranslation(0, distance, 0);
    }

    public static function translateZ(m:Matrix3D, distance:Float, local:Bool = true):Void {
        if (local) m.prependTranslation(0, 0, distance);
        else m.appendTranslation(0, 0, distance);
    }

    public static function rotateX(m:Matrix3D, angle:Float, local:Bool = true):Void {
        if (local) m.prependRotation(angle, Vector3D.X_AXIS);
        else m.appendRotation(angle, Vector3D.X_AXIS);
    }

    public static function rotateY(m:Matrix3D, angle:Float, local:Bool = true):Void {
        if (local) m.prependRotation(angle, Vector3D.Y_AXIS);
        else m.appendRotation(angle, Vector3D.Y_AXIS);
    }

    public static function rotateZ(m:Matrix3D, angle:Float, local:Bool = true):Void {
        if (local) m.prependRotation(angle, Vector3D.Z_AXIS);
        else m.appendRotation(angle, Vector3D.Z_AXIS);
    }

    public static function buildOrthoProjection(left:Float, right:Float, bottom:Float, top:Float, near:Float, far:Float, out:Matrix3D = null):Matrix3D {
        if (out == null) out = new Matrix3D();
        var vals = [
            2 / (right - left), 0, 0, 0,
            0, 2 / (top - bottom), 0, 0,
            0, 0, 1 / (far - near), 0,
            -(right + left) / (right - left), -(top + bottom) / (top - bottom), -near / (far - near), 1
        ];
        out.copyRawDataFrom(openfl.Vector.ofArray([for (v in vals) (v:Float)]));
        return out;
    }

    public static function transformVector(m:Matrix3D, v:Vector3D, out:Vector3D = null):Vector3D {
        if (out == null) out = new Vector3D();
        var res = m.transformVector(v);
        out.x = res.x; out.y = res.y; out.z = res.z; out.w = res.w;
        return out;
    }

    public static function deltaTransformVector(m:Matrix3D, v:Vector3D, out:Vector3D = null):Vector3D {
        if (out == null) out = new Vector3D();
        var res = m.deltaTransformVector(v);
        out.x = res.x; out.y = res.y; out.z = res.z; out.w = res.w;
        return out;
    }

    public static function invert(m:Matrix3D):Void {
        m.invert();
    }
}
