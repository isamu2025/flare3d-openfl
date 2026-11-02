package flare.basic;

import openfl.display.DisplayObjectContainer;
import openfl.display.Stage;
import openfl.events.MouseEvent;
import openfl.geom.Vector3D;
import flare.core.Camera3D;

/**
 * Viewer3D extends Scene3D with mouse orbital camera navigation.
 */
class Viewer3D extends Scene3D {
    public var target:Vector3D;
    public var radius(default, set):Float = 30.0;
    private function set_radius(v:Float):Float {
        radius = v;
        _orbitDirty = true;
        updateCameraOrbit();
        return v;
    }

    public function setTarget(tx:Float, ty:Float, tz:Float):Void {
        if (target == null) target = new Vector3D();
        target.setTo(tx, ty, tz);
        syncOrbitFromCamera();
    }
    public var minRadius:Float = 0.2;
    public var maxRadius:Float = 50000.0;
    public var orbitSensitivity:Float = 0.8;
    public var zoomSensitivity:Float = 0.35;

    private var _pitch:Float = 25.0;
    private var _yaw:Float = -45.0;

    private var _isMouseDown:Bool = false;
    private var _lastMouseX:Float = 0;
    private var _lastMouseY:Float = 0;
    private var _orbitDirty:Bool = true;

    public function new(container:DisplayObjectContainer = null, scene:Scene3D = null, sensitivity:Float = 0.8, button:Int = 0, progress:Dynamic = null) {
        if (sensitivity > 0) this.orbitSensitivity = sensitivity;
        target = new Vector3D(0, 0, 0);
        super(container);
        syncOrbitFromCamera();
        _orbitDirty = false;
    }

    override private function initStage(st:Stage):Void {
        super.initStage(st);

        st.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
        st.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
        st.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
        st.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
    }

    public function syncOrbitFromCamera():Void {
        if (camera == null) return;
        if (target == null) target = new Vector3D(0, 0, 0);
        var pos = camera.getPosition(false);
        var dx = pos.x - target.x;
        var dy = pos.y - target.y;
        var dz = pos.z - target.z;
        var dist = Math.sqrt(dx * dx + dy * dy + dz * dz);
        if (dist > 0.0001) {
            _pitch = Math.asin(Math.max(-0.999, Math.min(0.999, dy / dist))) * 180.0 / Math.PI;
            _yaw = Math.atan2(dx, -dz) * 180.0 / Math.PI;
            @:bypassAccessor radius = dist;
        }
        _orbitDirty = false;
    }

    private function onMouseDown(e:MouseEvent):Void {
        // Allow orbit on drag even if hovering meshes
        // if (_hoveredPivot != null) return;
        syncOrbitFromCamera();
        _isMouseDown = true;
        _lastMouseX = e.stageX;
        _lastMouseY = e.stageY;
    }

    private function onMouseUp(e:MouseEvent):Void {
        _isMouseDown = false;
    }

    private function onMouseMove(e:MouseEvent):Void {
        if (!_isMouseDown) return;

        var dx = e.stageX - _lastMouseX;
        var dy = e.stageY - _lastMouseY;
        _lastMouseX = e.stageX;
        _lastMouseY = e.stageY;

        _yaw -= dx * orbitSensitivity;
        _pitch += dy * orbitSensitivity;

        if (_pitch > 89.0) _pitch = 89.0;
        if (_pitch < -89.0) _pitch = -89.0;

        _orbitDirty = true;
        updateCameraOrbit();
    }

    private function onMouseWheel(e:MouseEvent):Void {
        syncOrbitFromCamera();
        var step = Math.max(radius * 0.08, 0.05);
        radius -= e.delta * zoomSensitivity * step;
        if (radius < minRadius) radius = minRadius;
        if (radius > maxRadius) radius = maxRadius;

        _orbitDirty = true;
        updateCameraOrbit();
    }

    override private function set_camera(v:Camera3D):Camera3D {
        var ret = super.set_camera(v);
        syncOrbitFromCamera();
        _orbitDirty = false;
        return ret;
    }

    override public function render(camera:Camera3D = null, clearDepth:Bool = false, target:Dynamic = null):Void {
        if (_orbitDirty && _isMouseDown) {
            updateCameraOrbit();
            _orbitDirty = false;
        }
        super.render(camera, clearDepth, target);
    }

    public function updateCameraOrbit():Void {

        if (camera == null) return;

        var pitchRad = _pitch * Math.PI / 180.0;
        var yawRad = _yaw * Math.PI / 180.0;

        var cosPitch = Math.cos(pitchRad);
        var sinPitch = Math.sin(pitchRad);
        var cosYaw = Math.cos(yawRad);
        var sinYaw = Math.sin(yawRad);

        var cx = target.x + radius * cosPitch * sinYaw;
        var cy = target.y + radius * sinPitch;
        var cz = target.z - radius * cosPitch * cosYaw;

        camera.setPosition(cx, cy, cz);
        camera.lookAt(target.x, target.y, target.z);
    }
}
