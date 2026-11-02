package flare.core;

import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import openfl.geom.Rectangle;
import openfl.geom.Point;
import flare.basic.Scene3D;
import flare.system.Device3D;

/**
 * Camera3D represents the perspective or orthographic viewpoint in 3D space.
 */
class Camera3D extends Pivot3D {
    public static inline var FOV_HORIZONTAL:Int = 0;
    public static inline var FOV_VERTICAL:Int = 1;

    public var fovMode:Int = FOV_VERTICAL;
    public var fieldOfView:Float = 75.0;
    public var zoom(get, set):Float;
    private function get_zoom():Float {
        var fovRad = fieldOfView * Math.PI / 180.0;
        return Math.tan(fovRad * 0.5);
    }
    private function set_zoom(val:Float):Float {
        if (val <= 0) val = 0.0001;
        fieldOfView = (2.0 * Math.atan(val)) * 180.0 / Math.PI;
        updateProjection();
        return val;
    }
    public var near:Float = 1.0;
    public var far:Float = 5000.0;
    public var aspectRatio:Float = 4.0 / 3.0;
    public var orthographic:Bool = false;
    public var orthoWidth:Float = 800.0;
    public var orthoHeight:Float = 600.0;
    public var viewPort:Rectangle = null;
    public var clipRectangle:Bool = true;
    public var canvasSize:Point = null;

    public var view:Matrix3D;
    public var customProjection:Bool = false;
    public var projection(get, set):Matrix3D;
    private var _projection:Matrix3D;
    private inline function get_projection():Matrix3D return _projection;
    private inline function set_projection(m:Matrix3D):Matrix3D {
        _projection = m;
        customProjection = (m != null);
        return _projection;
    }
    public var viewProjection:Matrix3D;

    public var fov(get, set):Float;
    private inline function get_fov():Float return fieldOfView;
    private inline function set_fov(v:Float):Float { fieldOfView = v; updateProjection(); return v; }

    public function new(name:String = "camera", fov:Float = 75.0) {
        super(name);
        this.fieldOfView = fov;
        view = new Matrix3D();
        _projection = new Matrix3D();
        customProjection = false;
        viewProjection = new Matrix3D();
        updateProjection();
    }

    public function updateProjectionMatrix():Void {
        updateProjection();
    }

    public function updateProjection(viewportWidth:Float = -1, viewportHeight:Float = -1):Void {
        if (customProjection && _projection != null) return;
        // Stage 1: determine local viewport width and height for aspectRatio calculation
        var localW:Float = viewportWidth;
        var localH:Float = viewportHeight;

        if (viewPort != null) {
            localW = viewPort.width;
            localH = viewPort.height;
        } else if (localW <= 0 || localH <= 0) {
            if (scene != null && scene.viewPort != null) {
                localW = scene.viewPort.width;
                localH = scene.viewPort.height;
            } else if (scene != null && scene.stage != null && scene.stage.stageWidth > 0) {
                localW = scene.stage.stageWidth;
                localH = scene.stage.stageHeight;
            } else if (Device3D.scene != null && Device3D.scene.viewPort != null) {
                localW = Device3D.scene.viewPort.width;
                localH = Device3D.scene.viewPort.height;
            } else {
                localW = 1024;
                localH = 525;
            }
        }

        if (localH > 0) {
            aspectRatio = localW / localH;
        }

        var raw = new openfl.Vector<Float>(16);
        for (i in 0...16) raw[i] = 0;

        if (!orthographic) {
            var fovRad = fieldOfView * Math.PI / 180.0;
            var tanHalfFov = Math.tan(fovRad * 0.5);
            var xScale:Float;
            var yScale:Float;
            if (fovMode == FOV_HORIZONTAL) {
                xScale = 1.0 / tanHalfFov;
                yScale = xScale * aspectRatio;
            } else {
                yScale = 1.0 / tanHalfFov;
                xScale = yScale / aspectRatio;
            }
            var range = far - near;

            raw[0] = xScale;
            raw[5] = yScale;
            raw[10] = far / range;
            raw[11] = 1.0;
            raw[14] = (-near * far) / range;
        } else {
            raw[0] = 2.0 / orthoWidth;
            raw[5] = 2.0 / orthoHeight;
            raw[10] = 1.0 / (far - near);
            raw[14] = -near / (far - near);
            raw[15] = 1.0;
        }

        // Stage 2: sub-viewport mapping within full screen / backbuffer
        if (viewPort != null) {
            var sceneW:Float;
            var sceneH:Float;

            if (canvasSize != null) {
                sceneW = canvasSize.x;
                sceneH = canvasSize.y;
            } else if (scene != null && scene.viewPort != null) {
                sceneW = scene.viewPort.width;
                sceneH = scene.viewPort.height;
            } else if (scene != null && scene.stage != null && scene.stage.stageWidth > 0) {
                sceneW = scene.stage.stageWidth;
                sceneH = scene.stage.stageHeight;
            } else if (Device3D.scene != null && Device3D.scene.viewPort != null) {
                sceneW = Device3D.scene.viewPort.width;
                sceneH = Device3D.scene.viewPort.height;
            } else {
                sceneW = 1024;
                sceneH = 525;
            }

            if (sceneW <= 0) sceneW = 1024;
            if (sceneH <= 0) sceneH = 525;

            raw[0] = raw[0] / (sceneW / viewPort.width);
            raw[5] = raw[5] / (sceneH / viewPort.height);
            raw[8] = -1.0 + (viewPort.width / sceneW) + (2.0 * viewPort.x / sceneW);
            raw[9] = 1.0 - (viewPort.height / sceneH) - (2.0 * viewPort.y / sceneH);
        }

        if (_projection == null) _projection = new Matrix3D();
        _projection.copyRawDataFrom(raw);
    }

    public function updateViewProjection():Void {
        view.copyFrom(world);
        view.invert();
        viewProjection.copyFrom(view);
        viewProjection.append(projection);
    }

    public function project(point:Vector3D, out:Vector3D = null):Vector3D {
        if (out == null) out = new Vector3D();
        var v = viewProjection.transformVector(point);
        if (v.w != 0) {
            out.x = v.x / v.w;
            out.y = v.y / v.w;
            out.z = v.z / v.w;
        } else {
            out.x = v.x;
            out.y = v.y;
            out.z = v.z;
        }
        return out;
    }
}
