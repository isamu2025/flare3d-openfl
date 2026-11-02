package flare.utils;

import openfl.geom.Vector3D;
import openfl.Vector;
import flare.core.Boundings3D;
import flare.core.Mesh3D;
import flare.core.Pivot3D;
import flare.core.Label3D;
import flare.modifiers.SkinModifier;

/**
 * Utility functions for Pivot3D node trees, bounds calculation, animations, and coordinates.
 */
class Pivot3DUtils {
    public static function abs(a:Vector<Float>):Void {
        if (a == null) return;
        for (i in 0...a.length) {
            if (a[i] < 0) a[i] = -a[i];
        }
    }

    private static var _added:Map<Pivot3D, Bool> = null;

    /**
     * Add animation frames and labels to source pivot from another pivot, including children.
     * The pivot names and hierarchy must be the same.
     */
    public static function appendAnimation(dest:Pivot3D, animation:Pivot3D, label:String = null, includeMaterials:Bool = false):Void {
        if (dest == null || animation == null) return;

        var from:Int = getAnimationLength(dest);
        var length:Int = getAnimationLength(animation);
        var label3D:Label3D = null;
        if (label != null) {
            label3D = new Label3D(label, from, from + length - 1);
        }

        _added = new Map<Pivot3D, Bool>();
        appendAnimationAux(dest, animation, label3D, from, length, includeMaterials);
        normalizeFrames(dest, from + length);
        dest.totalFrames = from + length;
        dest.play();
        _added = null;
    }

    public static function appendAnimationAux(dest:Pivot3D, animation:Pivot3D, label:Dynamic, from:Int, length:Int, includeMaterials:Bool = false):Void {
        if (dest == null || animation == null) return;

        var label3D:Label3D = null;
        if (label != null) {
            if (Std.isOfType(label, Label3D)) {
                label3D = cast label;
            } else if (Std.isOfType(label, String)) {
                label3D = new Label3D(cast label, from, from + length - 1);
            }
        }

        var source:Pivot3D = getChildByNameAux(animation, dest.name);
        if (source != null && source.frames != null) {
            if (dest.frames == null) {
                dest.frames = new openfl.Vector<flare.core.Frame3D>();
            }
            if (_added != null && !_added.exists(dest)) {
                _added.set(dest, true);
                for (f in source.frames) {
                    dest.frames.push(f);
                }
                dest.totalFrames = dest.frames.length;
            }
        }

        if (source != null && source.labels != null) {
            for (l in source.labels) {
                if (l != null) {
                    dest.addLabel(new Label3D(l.name, l.from + from, l.to + from));
                }
            }
        }

        if (label3D != null) {
            var exists = false;
            for (l in dest.labels) {
                if (l != null && l.name == label3D.name) {
                    exists = true;
                    break;
                }
            }
            if (!exists) {
                dest.labels.push(label3D);
            }
        }

        if (Std.isOfType(dest, Mesh3D)) {
            var mesh:Mesh3D = cast dest;
            if (mesh.modifier != null && Std.isOfType(mesh.modifier, SkinModifier)) {
                var skin:SkinModifier = cast mesh.modifier;
                if (dest.frames == null) {
                    dest.frames = new openfl.Vector<flare.core.Frame3D>();
                }
                if (dest.frames.length == 0) {
                    dest.frames.push(new flare.core.Frame3D(dest.transform.rawData));
                }
                while (dest.frames.length < from + length) {
                    dest.frames.push(dest.frames[0]);
                }
                dest.totalFrames = dest.frames.length;
                skin.totalFrames = dest.frames.length;
                if (skin.root != null) {
                    appendAnimationAux(skin.root, animation, label3D, from, length, includeMaterials);
                }
            }
        }

        for (child in dest.children) {
            appendAnimationAux(child, animation, label3D, from, length, includeMaterials);
        }
    }

    public static function getAnimationLength(animation:Pivot3D, length:Int = 0):Int {
        if (animation == null) return length;
        if (animation.frames != null && animation.frames.length > length) {
            length = animation.frames.length;
        }
        if (animation.totalFrames > length) {
            length = animation.totalFrames;
        }
        if (Std.isOfType(animation, Mesh3D)) {
            var mesh:Mesh3D = cast animation;
            if (mesh.modifier != null && Std.isOfType(mesh.modifier, SkinModifier)) {
                var skin:SkinModifier = cast mesh.modifier;
                if (skin.root != null) {
                    var l = getAnimationLength(skin.root, length);
                    if (l > length) length = l;
                }
            }
        }
        if (animation.children != null) {
            for (child in animation.children) {
                var l = getAnimationLength(child, length);
                if (l > length) length = l;
            }
        }
        return length;
    }

    public static function normalizeFrames(source:Pivot3D, length:Int):Void {
        if (source == null) return;
        if (source.totalFrames < length) {
            source.totalFrames = length;
        }
        if (Std.isOfType(source, Mesh3D)) {
            var mesh:Mesh3D = cast source;
            if (mesh.modifier != null && Std.isOfType(mesh.modifier, SkinModifier)) {
                var skin:SkinModifier = cast mesh.modifier;
                if (skin.root != null) {
                    normalizeSkinFrames(skin.root, length);
                }
                skin.totalFrames = length;
            }
        }
        for (child in source.children) {
            normalizeFrames(child, length);
        }
    }

    public static function normalizeSkinFrames(source:Pivot3D, length:Int):Void {
        if (source == null) return;
        if (source.frames == null) {
            source.frames = new openfl.Vector<flare.core.Frame3D>();
            source.frames.push(new flare.core.Frame3D(source.transform.rawData));
        }
        while (source.frames.length < length) {
            source.frames.push(source.frames[0]);
        }
        source.totalFrames = source.frames.length;
        for (child in source.children) {
            normalizeSkinFrames(child, length);
        }
    }

    public static function removeAnimations(pivot:Pivot3D, includeChildren:Bool = true):Void {
        if (pivot == null) return;
        pivot.frames = null;
        pivot.labels = new flare.core.Label3D.Labels();
        pivot.totalFrames = 0;
        if (Std.isOfType(pivot, Mesh3D)) {
            var mesh:Mesh3D = cast pivot;
            if (mesh.modifier != null && Std.isOfType(mesh.modifier, SkinModifier)) {
                var skin:SkinModifier = cast mesh.modifier;
                skin.totalFrames = 0;
            }
        }
        if (includeChildren) {
            for (child in pivot.children) {
                removeAnimations(child, true);
            }
        }
    }

    public static function setAnimations(dest:Pivot3D, source:Pivot3D):Void {
        if (dest == null || source == null) return;
        if (dest.name == source.name) {
            dest.frames = source.frames;
            dest.labels = source.labels;
            dest.totalFrames = source.totalFrames;
        }
        for (child in dest.children) {
            var s = getChildByNameAux(source, child.name);
            if (s != null) {
                setAnimations(child, s);
            }
        }
    }

    public static function getBounds(pivot:Pivot3D, out:Boundings3D = null, relativeTo:Pivot3D = null, includeChildren:Bool = true):Boundings3D {
        if (out == null) out = new Boundings3D();
        out.reset();

        growBounds(pivot, pivot, out, includeChildren);
        return out;
    }

    public static function growBounds(parent:Pivot3D, pivot:Pivot3D, out:Boundings3D, includeChildren:Bool = true):Void {
        if (pivot == null) return;

        if (Std.isOfType(pivot, Mesh3D)) {
            var mesh:Mesh3D = cast pivot;
            for (surf in mesh.surfaces) {
                var v = surf.vertexData;
                var len = v.length;
                var i = 0;
                while (i < len) {
                    var x = v[i];
                    var y = v[i + 1];
                    var z = v[i + 2];
                    if (x < out.min.x) out.min.x = x;
                    if (y < out.min.y) out.min.y = y;
                    if (z < out.min.z) out.min.z = z;
                    if (x > out.max.x) out.max.x = x;
                    if (y > out.max.y) out.max.y = y;
                    if (z > out.max.z) out.max.z = z;
                    i += 8;
                }
            }
            out.update(out.min.x, out.min.y, out.min.z, out.max.x, out.max.y, out.max.z);
        }

        if (includeChildren) {
            for (child in pivot.children) {
                growBounds(parent, child, out, includeChildren);
            }
        }
    }

    public static function getChildByNameAux(source:Pivot3D, name:String):Pivot3D {
        if (source == null || name == null || name == "") return null;
        if (source.name == name) return source;

        if (Std.isOfType(source, Mesh3D)) {
            var mesh:Mesh3D = cast source;
            if (mesh.modifier != null && Std.isOfType(mesh.modifier, SkinModifier)) {
                var skin:SkinModifier = cast mesh.modifier;
                if (skin.root != null) {
                    var found = getChildByNameAux(skin.root, name);
                    if (found != null) return found;
                }
            }
        }

        for (child in source.children) {
            var found = getChildByNameAux(child, name);
            if (found != null) return found;
        }
        return null;
    }

    public static function getDistance(pivot1:Pivot3D, pivot2:Pivot3D):Float {
        if (pivot1 == null || pivot2 == null) return 0;
        var p1 = pivot1.getPosition(false);
        var p2 = pivot2.getPosition(false);
        var dx = p1.x - p2.x;
        var dy = p1.y - p2.y;
        var dz = p1.z - p2.z;
        return Math.sqrt(dx * dx + dy * dy + dz * dz);
    }

    private static var _lookInVec:Vector3D = new Vector3D();
    private static var _lookTargetVec:Vector3D = new Vector3D();

    public static function lookAtWithReference(pivot:Pivot3D, x:Float, y:Float, z:Float, reference:Pivot3D = null, up:Vector3D = null, smooth:Float = 0):Void {
        if (pivot == null) return;
        var tx = x, ty = y, tz = z;
        if (reference != null) {
            _lookInVec.x = x; _lookInVec.y = y; _lookInVec.z = z;
            reference.localToGlobal(_lookInVec, _lookTargetVec);
            tx = _lookTargetVec.x; ty = _lookTargetVec.y; tz = _lookTargetVec.z;
        }
        pivot.lookAt(tx, ty, tz, up, smooth);
    }

    private static var _refInVec:Vector3D = new Vector3D();
    private static var _refOutVec:Vector3D = new Vector3D();
    private static var _refCurVec:Vector3D = new Vector3D();

    public static function setPositionWithReference(pivot:Pivot3D, x:Float, y:Float, z:Float, reference:Pivot3D = null, smooth:Float = 0):Void {
        if (pivot == null) return;
        var tx = x, ty = y, tz = z;
        if (reference != null) {
            _refInVec.x = x; _refInVec.y = y; _refInVec.z = z;
            reference.localToGlobal(_refInVec, _refOutVec);
            tx = _refOutVec.x; ty = _refOutVec.y; tz = _refOutVec.z;
        }
        if (smooth > 0 && smooth < 1.0) {
            pivot.getPosition(false, _refCurVec);
            var nx = _refCurVec.x + (tx - _refCurVec.x) * smooth;
            var ny = _refCurVec.y + (ty - _refCurVec.y) * smooth;
            var nz = _refCurVec.z + (tz - _refCurVec.z) * smooth;
            pivot.setPosition(nx, ny, nz);
        } else {
            pivot.setPosition(tx, ty, tz);
        }
    }

    public static function traceChild(pivot:Pivot3D, level:Int = 0, includeMaterials:Bool = false, includeChildren:Bool = true):Void {
        if (pivot == null) return;
        var indent = "";
        for (i in 0...level) indent += "  ";
        trace(indent + "- " + pivot.name + " (" + Type.getClassName(Type.getClass(pivot)) + ")");
        if (includeChildren) {
            for (child in pivot.children) {
                traceChild(child, level + 1, includeMaterials, includeChildren);
            }
        }
    }

    public static function traceInfo(pivot:Pivot3D, includeMaterials:Bool = false, includeChildren:Bool = true):Void {
        traceChild(pivot, 0, includeMaterials, includeChildren);
    }
}
