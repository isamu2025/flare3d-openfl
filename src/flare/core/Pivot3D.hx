package flare.core;

import openfl.events.EventDispatcher;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import openfl.geom.Orientation3D;
import flare.core.Camera3D;

/**
 * Pivot3D is the core hierarchical scene graph node in Flare3D.
 * It manages 3D transforms, parent-child relationships, and spatial calculations.
 */
class Pivot3D extends EventDispatcher {
    public static inline var ADDED_EVENT:String = "added";
    public static inline var ADDED_TO_SCENE_EVENT:String = "addedToScene";
    public static inline var ANIMATION_COMPLETE_EVENT:String = "animationComplete";
    public static inline var ENTER_DRAW_EVENT:String = "enterDraw";
    public static inline var ENTER_FRAME_EVENT:String = "enterFrame";
    public static inline var EXIT_DRAW_EVENT:String = "exitDraw";
    public static inline var EXIT_FRAME_EVENT:String = "exitFrame";
    public static inline var REMOVED_EVENT:String = "removed";
    public static inline var REMOVED_FROM_SCENE_EVENT:String = "removedFromScene";
    public static inline var SORT_CENTER:Int = 1;
    public static inline var SORT_FAR:Int = 4;
    public static inline var SORT_NEAR:Int = 2;
    public static inline var SORT_NONE:Int = 0;
    public static inline var ENTER_DRAG_EVENT:String = "enterDrag";
    public static inline var EXIT_DRAG_EVENT:String = "exitDrag";
    public static inline var UNLOAD_EVENT:String = "unload";
    public static inline var UPDATE_TRANSFORM_EVENT:String = "updateTransform";

    public var hasDrawListeners:Bool = false;

    override public function dispatchEvent(event:openfl.events.Event):Bool {
        var result = super.dispatchEvent(event);
        if (event.bubbles && _parentNode != null && !event.isDefaultPrevented()) {
            _parentNode.dispatchEvent(event);
        }
        return result;
    }

    override public function addEventListener<T>(type:String, listener:T->Void, useCapture:Bool = false, priority:Int = 0, useWeakReference:Bool = false):Void {
        if (type == ENTER_DRAW_EVENT || type == EXIT_DRAW_EVENT) {
            hasDrawListeners = true;
        }
        super.addEventListener(type, listener, useCapture, priority, useWeakReference);
    }

    public var name(default, set):String;
    private function set_name(value:String):String {
        name = value;
        onNameChanged();
        return value;
    }
    public function onNameChanged():Void {}
    public var parent(get, set):Pivot3D;
    private var _parentNode:Pivot3D;
    private inline function get_parent():Pivot3D return _parentNode;
    private function set_parent(value:Pivot3D):Pivot3D {
        if (_parentNode == value) return value;
        if (value == null) {
            if (_parentNode != null) {
                var p = _parentNode;
                _parentNode = null;
                p.removeChild(this);
            }
        } else {
            value.addChild(this);
        }
        return _parentNode;
    }
    public var children:Array<Pivot3D>;
    public var visible:Bool = true;
    public var layer:Int = 0;
    public var useHandCursor:Bool = false;

    public function setLayer(val:Int, includeChildren:Bool = true):Void {
        this.layer = val;
        if (includeChildren) {
            for (c in children) c.setLayer(val, true);
        }
    }
    
    /** Local transform matrix */
    public var matrix:Matrix3D;
    /** World transform matrix in global space */
    public var world:Matrix3D;
    
    public var transform(get, set):Matrix3D;
    private inline function get_transform():Matrix3D return matrix;
    private inline function set_transform(v:Matrix3D):Matrix3D { matrix = v; _dirty = true; return matrix; }

    public function setTransform(v:Matrix3D):Void {
        transform = v;
    }

    public var scene:flare.basic.Scene3D;
    
    /** User data dictionary */
    public var userData:Dynamic;
    
    private var _dirty:Bool = true;
    private static var _tempVec:Vector3D = new Vector3D();
    private static var _upAxis:Vector3D = new Vector3D(0, 1, 0);

    public function new(name:String = "") {
        super();
        this.name = name;
        this.children = [];
        this.matrix = new Matrix3D();
        this.world = new Matrix3D();
        this.userData = {};
    }

    public var x(get, set):Float;
    private inline function get_x():Float {
        return matrix.rawData[12];
    }
    private function set_x(value:Float):Float {
        var raw = matrix.rawData;
        raw[12] = value;
        matrix.copyRawDataFrom(raw);
        _dirty = true;
        return value;
    }

    public var y(get, set):Float;
    private inline function get_y():Float {
        return matrix.rawData[13];
    }
    private function set_y(value:Float):Float {
        var raw = matrix.rawData;
        raw[13] = value;
        matrix.copyRawDataFrom(raw);
        _dirty = true;
        return value;
    }

    public var z(get, set):Float;
    private inline function get_z():Float {
        return matrix.rawData[14];
    }
    private function set_z(value:Float):Float {
        var raw = matrix.rawData;
        raw[14] = value;
        matrix.copyRawDataFrom(raw);
        _dirty = true;
        return value;
    }

    public function updateWorldMatrix():Void {
        if (parent != null) {
            parent.updateWorldMatrix();
            world.copyFrom(matrix);
            world.append(parent.world);
        } else {
            world.copyFrom(matrix);
        }
        _dirty = false;
    }

    public function localToGlobal(point:Vector3D, out:Vector3D = null):Vector3D {
        if (out == null) out = new Vector3D();
        updateWorldMatrix();
        var raw = world.rawData;
        var px = point.x, py = point.y, pz = point.z;
        out.x = raw[0] * px + raw[4] * py + raw[8] * pz + raw[12];
        out.y = raw[1] * px + raw[5] * py + raw[9] * pz + raw[13];
        out.z = raw[2] * px + raw[6] * py + raw[10] * pz + raw[14];
        return out;
    }

    public function globalToLocal(point:Vector3D, out:Vector3D = null):Vector3D {
        if (out == null) out = new Vector3D();
        updateWorldMatrix();
        var inv = world.clone();
        inv.invert();
        var res = inv.transformVector(point);
        out.x = res.x; out.y = res.y; out.z = res.z;
        return out;
    }

    public function getPosition(local:Bool = false, out:Vector3D = null):Vector3D {
        if (out == null) out = new Vector3D();
        if (local) {
            out.x = matrix.rawData[12];
            out.y = matrix.rawData[13];
            out.z = matrix.rawData[14];
        } else {
            updateWorldMatrix();
            out.x = world.rawData[12];
            out.y = world.rawData[13];
            out.z = world.rawData[14];
        }
        return out;
    }

    public function getDir(local:Bool = false, out:Vector3D = null):Vector3D {
        if (out == null) out = new Vector3D();
        if (!local) updateWorldMatrix();
        var m = local ? matrix : world;
        out.x = m.rawData[8];
        out.y = m.rawData[9];
        out.z = m.rawData[10];
        out.normalize();
        return out;
    }

    public function setPosition(px:Float, py:Float, pz:Float):Void {
        var raw = matrix.rawData;
        raw[12] = px;
        raw[13] = py;
        raw[14] = pz;
        matrix.copyRawDataFrom(raw);
        _dirty = true;
    }

    public function setOrientation(dir:Vector3D, up:Vector3D = null, smooth:Float = 1):Void {
        flare.utils.Matrix3DUtils.setOrientation(matrix, dir, up, smooth);
        _dirty = true;
    }

    public function setScale(sx:Float, sy:Float, sz:Float):Void {
        var comps = matrix.decompose(Orientation3D.EULER_ANGLES);
        comps[2].x = sx;
        comps[2].y = sy;
        comps[2].z = sz;
        matrix.recompose(comps, Orientation3D.EULER_ANGLES);
        _dirty = true;
    }

    public function setRotation(rx:Float, ry:Float, rz:Float):Void {
        var comps = matrix.decompose(Orientation3D.EULER_ANGLES);
        comps[1].x = rx * Math.PI / 180.0;
        comps[1].y = ry * Math.PI / 180.0;
        comps[1].z = rz * Math.PI / 180.0;
        matrix.recompose(comps, Orientation3D.EULER_ANGLES);
        _dirty = true;
    }

    public function translate(tx:Float, ty:Float, tz:Float, local:Bool = true):Void {
        if (local) {
            matrix.prependTranslation(tx, ty, tz);
        } else {
            matrix.appendTranslation(tx, ty, tz);
        }
        _dirty = true;
    }

    public inline function translateX(dist:Float):Void {
        matrix.prependTranslation(dist, 0, 0);
        _dirty = true;
    }

    public inline function translateY(dist:Float):Void {
        matrix.prependTranslation(0, dist, 0);
        _dirty = true;
    }

    public inline function translateZ(dist:Float):Void {
        matrix.prependTranslation(0, 0, dist);
        _dirty = true;
    }

    public function rotateX(angleDeg:Float, local:Bool = true, pivotPoint:Vector3D = null):Void {
        rotateAxis(Vector3D.X_AXIS, angleDeg, local, pivotPoint);
    }

    public function rotateY(angleDeg:Float, local:Bool = true, pivotPoint:Vector3D = null):Void {
        rotateAxis(Vector3D.Y_AXIS, angleDeg, local, pivotPoint);
    }

    public function rotateZ(angleDeg:Float, local:Bool = true, pivotPoint:Vector3D = null):Void {
        rotateAxis(Vector3D.Z_AXIS, angleDeg, local, pivotPoint);
    }

    public function rotateAxis(axis:Vector3D, angleDeg:Float, local:Bool = true, pivotPoint:Vector3D = null):Void {
        if (pivotPoint != null) {
            var rotAxis = local ? matrix.deltaTransformVector(axis) : axis;
            matrix.appendTranslation(-pivotPoint.x, -pivotPoint.y, -pivotPoint.z);
            matrix.appendRotation(angleDeg, rotAxis);
            matrix.appendTranslation(pivotPoint.x, pivotPoint.y, pivotPoint.z);
        } else {
            if (local) {
                matrix.prependRotation(angleDeg, axis);
            } else {
                matrix.appendRotation(angleDeg, axis);
            }
        }
        _dirty = true;
    }

    public static var activeDragPivot(get, never):Pivot3D;
    private static inline function get_activeDragPivot():Pivot3D return _activeDragPivot;
    private static var _activeDragPivot:Pivot3D = null;
    private static var _dragPlanePoint:Vector3D;
    private static var _dragPlaneNormal:Vector3D;
    private static var _dragOffset:Vector3D;
    private static var _dragLockCenter:Bool;

    public function startDrag(lockCenter:Bool = false, refPlaneNormal:Vector3D = null):Void {
        if (_activeDragPivot != null && _activeDragPivot != this) {
            _activeDragPivot.stopDrag();
        }

        var rootScene = scene;
        if (rootScene == null) {
            var p:Pivot3D = this;
            while (p != null) {
                if (p.scene != null) { rootScene = p.scene; break; }
                if (Std.isOfType(p, flare.basic.Scene3D)) { rootScene = cast p; break; }
                p = p.parent;
            }
        }

        if (rootScene == null || rootScene.camera == null) return;

        var cam = rootScene.camera;
        var planeNormal:Vector3D;
        if (refPlaneNormal != null) {
            planeNormal = refPlaneNormal.clone();
            planeNormal.normalize();
        } else {
            planeNormal = cam.getDir(false);
            planeNormal.negate();
        }

        var pivotWorldPos = getPosition(false);
        _dragPlanePoint = pivotWorldPos.clone();
        _dragPlaneNormal = planeNormal;
        _dragLockCenter = lockCenter;

        var stage = openfl.Lib.current.stage;
        var stageX:Float = (stage != null) ? stage.mouseX : 400.0;
        var stageY:Float = (stage != null) ? stage.mouseY : 300.0;

        _dragOffset = new Vector3D(0, 0, 0);
        if (!lockCenter) {
            var ray = rootScene.getScreenRay(stageX, stageY);
            if (ray != null) {
                var denom = ray.dir.dotProduct(_dragPlaneNormal);
                if (Math.abs(denom) > 0.00001) {
                    var toPoint = new Vector3D(_dragPlanePoint.x - ray.origin.x, _dragPlanePoint.y - ray.origin.y, _dragPlanePoint.z - ray.origin.z);
                    var t = toPoint.dotProduct(_dragPlaneNormal) / denom;
                    var hitPoint = new Vector3D(ray.origin.x + ray.dir.x * t, ray.origin.y + ray.dir.y * t, ray.origin.z + ray.dir.z * t);
                    _dragOffset.setTo(pivotWorldPos.x - hitPoint.x, pivotWorldPos.y - hitPoint.y, pivotWorldPos.z - hitPoint.z);
                }
            }
        }

        _activeDragPivot = this;
        if (stage != null) {
            stage.addEventListener(openfl.events.MouseEvent.MOUSE_MOVE, onDragMouseMove);
        }

        dispatchEvent(new openfl.events.Event(ENTER_DRAG_EVENT));
    }

    private static function onDragMouseMove(e:openfl.events.MouseEvent):Void {
        if (_activeDragPivot == null) return;
        var pivot = _activeDragPivot;
        var rootScene = pivot.scene;
        if (rootScene == null) {
            var p:Pivot3D = pivot;
            while (p != null) {
                if (p.scene != null) { rootScene = p.scene; break; }
                if (Std.isOfType(p, flare.basic.Scene3D)) { rootScene = cast p; break; }
                p = p.parent;
            }
        }
        if (rootScene == null || rootScene.camera == null) return;

        var ray = rootScene.getScreenRay(e.stageX, e.stageY);
        if (ray == null) return;

        var denom = ray.dir.dotProduct(_dragPlaneNormal);
        if (Math.abs(denom) < 0.00001) return;

        var toPoint = new Vector3D(_dragPlanePoint.x - ray.origin.x, _dragPlanePoint.y - ray.origin.y, _dragPlanePoint.z - ray.origin.z);
        var t = toPoint.dotProduct(_dragPlaneNormal) / denom;
        var hitPoint = new Vector3D(ray.origin.x + ray.dir.x * t, ray.origin.y + ray.dir.y * t, ray.origin.z + ray.dir.z * t);

        var targetWorldPos = hitPoint;
        if (!_dragLockCenter) {
            targetWorldPos.x += _dragOffset.x;
            targetWorldPos.y += _dragOffset.y;
            targetWorldPos.z += _dragOffset.z;
        }

        if (pivot.parent != null && pivot.parent != rootScene) {
            var localPos = pivot.parent.globalToLocal(targetWorldPos);
            pivot.setPosition(localPos.x, localPos.y, localPos.z);
        } else {
            pivot.setPosition(targetWorldPos.x, targetWorldPos.y, targetWorldPos.z);
        }
    }

    public function stopDrag():Void {
        if (_activeDragPivot == this) {
            var stage = openfl.Lib.current.stage;
            if (stage != null) {
                stage.removeEventListener(openfl.events.MouseEvent.MOUSE_MOVE, onDragMouseMove);
            }
            _activeDragPivot = null;
            dispatchEvent(new openfl.events.Event(EXIT_DRAG_EVENT));
        }
    }

    public function lookAt(tx:Float, ty:Float, tz:Float, up:Vector3D = null, smooth:Float = 0):Void {
        if (up == null) up = _upAxis;
        
        var pos = new Vector3D(x, y, z);
        var dir = new Vector3D(tx - pos.x, ty - pos.y, tz - pos.z);
        if (dir.lengthSquared < 0.00001) return;
        dir.normalize();

        var right = up.crossProduct(dir);
        if (right.lengthSquared < 0.00001) {
            var alt = Math.abs(up.y) > 0.9 ? Vector3D.Z_AXIS : Vector3D.Y_AXIS;
            right = alt.crossProduct(dir);
        }
        right.normalize();
        
        var trueUp = dir.crossProduct(right);
        trueUp.normalize();

        var raw = matrix.rawData;
        raw[0] = right.x;  raw[1] = right.y;  raw[2] = right.z;  raw[3] = 0;
        raw[4] = trueUp.x; raw[5] = trueUp.y; raw[6] = trueUp.z; raw[7] = 0;
        raw[8] = dir.x;    raw[9] = dir.y;    raw[10] = dir.z;   raw[11] = 0;
        raw[12] = pos.x;   raw[13] = pos.y;   raw[14] = pos.z;   raw[15] = 1;
        if (smooth > 0 && smooth < 1.0) {
            var oldRaw = matrix.rawData;
            for (i in 0...16) {
                raw[i] = oldRaw[i] + (raw[i] - oldRaw[i]) * smooth;
            }
        }
        matrix.copyRawDataFrom(raw);
        _dirty = true;
    }

    public function getForward(local:Bool = false):Vector3D {
        if (!local) updateWorldMatrix();
        var raw = local ? matrix.rawData : world.rawData;
        var fwd = new Vector3D(raw[8], raw[9], raw[10]);
        fwd.normalize();
        return fwd;
    }

    public function getUp(local:Bool = false, out:Vector3D = null):Vector3D {
        if (out == null) out = new Vector3D();
        if (!local) updateWorldMatrix();
        var raw = local ? matrix.rawData : world.rawData;
        out.x = raw[4]; out.y = raw[5]; out.z = raw[6];
        out.normalize();
        return out;
    }

    public function getRight(local:Bool = false, out:Vector3D = null):Vector3D {
        if (out == null) out = new Vector3D();
        if (!local) updateWorldMatrix();
        var raw = local ? matrix.rawData : world.rawData;
        out.x = raw[0]; out.y = raw[1]; out.z = raw[2];
        out.normalize();
        return out;
    }

    public function setScene(sc:flare.basic.Scene3D):Void {
        this.scene = sc;
        for (c in children) {
            c.setScene(sc);
        }
    }

    public function addChild(child:Pivot3D):Pivot3D {
        if (child == null || child == this) return child;
        if (child._parentNode == this && children.indexOf(child) != -1) return child;
        if (child._parentNode != null && child._parentNode != this) {
            child._parentNode.removeChild(child);
        }
        child._parentNode = this;
        if (children.indexOf(child) == -1) {
            children.push(child);
        }
        child._dirty = true;
        if (this.scene != null) {
            child.setScene(this.scene);
        }
        return child;
    }

    public function removeChild(child:Pivot3D):Pivot3D {
        if (child == null) return null;
        var idx = children.indexOf(child);
        if (idx != -1) {
            children.splice(idx, 1);
            child._parentNode = null;
            child.setScene(null);
            child._dirty = true;
        }
        return child;
    }

    public function getChildByName(targetName:String):Pivot3D {
        for (c in children) {
            if (c.name == targetName) return c;
            var found = c.getChildByName(targetName);
            if (found != null) return found;
        }
        return null;
    }

    public function updateTransforms(param1:Dynamic = null, param2:Dynamic = false):Void {
        var parentWorld:Matrix3D = null;
        var parentDirty:Bool = false;
        var includeChildren:Bool = true;

        if (param1 != null) {
            if (Std.isOfType(param1, Bool)) {
                includeChildren = cast param1;
                if (parent != null && !Std.isOfType(parent, flare.basic.Scene3D)) {
                    parentWorld = parent.world;
                }
                parentDirty = true;
            } else if (Std.isOfType(param1, Matrix3D)) {
                parentWorld = cast param1;
                if (param2 != null && Std.isOfType(param2, Bool)) {
                    parentDirty = cast param2;
                }
            }
        } else {
            if (parent != null && !Std.isOfType(parent, flare.basic.Scene3D)) {
                parentWorld = parent.world;
            }
        }

        var isDirty = _dirty || parentDirty;
        if (isDirty) {
            world.copyFrom(matrix);
            if (parentWorld != null) {
                world.append(parentWorld);
            }
            _dirty = false;
        }
        if (includeChildren) {
            for (child in children) {
                child.updateTransforms(world, isDirty);
            }
        }
    }

    public function getChildrenByClass<T>(c:Class<T>, out:Array<T> = null):Array<T> {
        if (out == null) out = [];
        forEach(function(p:Dynamic) {
            if (p != this && Std.isOfType(p, c)) {
                out.push(cast p);
            }
        }, c, null, true);
        return out;
    }

    public function forEach(callback:Dynamic->Void, filterClass:Class<Dynamic> = null, params:Dynamic = null, includeChildren:Bool = true):Void {
        if (filterClass == null || Std.isOfType(this, filterClass)) {
            callback(this);
        }
        if (includeChildren) {
            for (child in children) {
                child.forEach(callback, filterClass, params, includeChildren);
            }
        }
    }

    // Component support
    public var components:Array<IComponent> = [];

    public function addComponent(component:IComponent):IComponent {
        if (component != null && components.indexOf(component) == -1) {
            components.push(component);
            component.added(this);
        }
        return component;
    }

    public function removeComponent(component:IComponent):IComponent {
        var idx = components.indexOf(component);
        if (idx != -1) {
            components.splice(idx, 1);
            component.removed();
        }
        return component;
    }

    // Animation timeline support
    public var currentFrame(get, set):Float;
    private var _currentFrame:Float = 0;
    private inline function get_currentFrame():Float return _currentFrame;
    private function set_currentFrame(v:Float):Float {
        _currentFrame = v;
        applyCurrentFrame();
        for (c in children) {
            c.currentFrame = v;
        }
        return _currentFrame;
    }
    public var totalFrames:Int = 0;
    public var isPlaying:Bool = false;
    public var animationSpeed:Float = 1.0;
    public var frameSpeed(get, set):Float;
    private inline function get_frameSpeed():Float return animationSpeed;
    private inline function set_frameSpeed(v:Float):Float {
        animationSpeed = v;
        for (c in children) c.set_frameSpeed(v);
        return animationSpeed;
    }
    public var labels:flare.core.Label3D.Labels = new flare.core.Label3D.Labels();
    public var frames:openfl.Vector<flare.core.Frame3D>;
    
    private var _startFrame:Float = 0;
    private var _endFrame:Float = 0;

    public function addLabel(label:Label3D):Void {
        labels.push(label);
        for (c in children) {
            c.addLabel(label);
        }
    }

    public function getLabelByName(targetName:String):Label3D {
        for (l in labels) {
            if (l.name == targetName) return l;
        }
        return null;
    }

    public function play(includeChildren:Bool = true):Void {
        isPlaying = true;
        if (includeChildren) {
            for (c in children) c.play(true);
        }
    }

    public function stop(includeChildren:Bool = true):Void {
        isPlaying = false;
        if (includeChildren) {
            for (c in children) c.stop(true);
        }
    }

    public function gotoAndPlay(labelOrFrame:Dynamic, blendFrames:Float = 0, includeChildren:Bool = true):Void {
        var found = false;
        if (Std.isOfType(labelOrFrame, String)) {
            var label = getLabelByName(cast labelOrFrame);
            if (label != null) {
                _startFrame = label.from;
                _endFrame = label.to;
                _currentFrame = label.from;
                found = true;
            }
        } else if (labelOrFrame != null) {
            var f:Float = cast labelOrFrame;
            _startFrame = f;
            _endFrame = totalFrames > 0 ? totalFrames : f;
            _currentFrame = f;
            found = true;
        }

        if (found || (frames != null && frames.length > 0)) {
            isPlaying = true;
            applyCurrentFrame();
        } else {
            isPlaying = false;
        }

        if (includeChildren) {
            for (c in children) {
                if (found) {
                    c.setFrameRange(_startFrame, _endFrame, _currentFrame);
                } else {
                    c.gotoAndPlay(labelOrFrame, blendFrames, true);
                }
            }
        }
    }

    public function setFrameRange(startF:Float, endF:Float, currentF:Float):Void {
        _startFrame = startF;
        _endFrame = endF;
        _currentFrame = currentF;
        isPlaying = true;
        applyCurrentFrame();
        for (c in children) {
            c.setFrameRange(startF, endF, currentF);
        }
    }

    public function gotoAndStop(labelOrFrame:Dynamic, blendFrames:Float = 0, includeChildren:Bool = true):Void {
        gotoAndPlay(labelOrFrame, blendFrames, includeChildren);
        stop(includeChildren);
    }

    public function applyCurrentFrame():Void {
        if (frames != null && frames.length > 0) {
            var fIdx = Std.int(Math.floor(_currentFrame)) % frames.length;
            if (fIdx < 0) fIdx += frames.length;
            var frame = frames[fIdx];
            if (frame != null && frame.type != Frame3D.TYPE_NULL && frame.type != 255) {
                var r = frame.rawData;
                if (!Math.isNaN(r[0]) && !Math.isNaN(r[5]) && !Math.isNaN(r[10]) && !Math.isNaN(r[12])) {
                    matrix.copyFrom(frame);
                    _dirty = true;
                }
            }
        }
    }

    public function syncAnimationToChildren():Void {
        for (child in children) {
            child._currentFrame = this._currentFrame;
            child.isPlaying = this.isPlaying;
            child.animationSpeed = this.animationSpeed;
            child._startFrame = this._startFrame;
            child._endFrame = this._endFrame;
            child.applyCurrentFrame();
            child.syncAnimationToChildren();
        }
    }

    public function updateAnimation(dt:Float = 1.0):Void {
        var hasOwnFrames = (frames != null && frames.length > 0) || (labels != null && labels.length > 0) || totalFrames > 0;
        if (isPlaying && hasOwnFrames) {
            _currentFrame += dt * animationSpeed;
            if (_endFrame > _startFrame) {
                if (_currentFrame >= _endFrame) {
                    _currentFrame = _startFrame + (_currentFrame - _endFrame) % (_endFrame - _startFrame);
                    if (hasEventListener(ANIMATION_COMPLETE_EVENT)) {
                        dispatchEvent(new openfl.events.Event(ANIMATION_COMPLETE_EVENT));
                    }
                } else if (_currentFrame < _startFrame) {
                    _currentFrame = _startFrame;
                }
            } else if (totalFrames > 0) {
                if (_currentFrame >= totalFrames) {
                    _currentFrame = _currentFrame % totalFrames;
                    if (hasEventListener(ANIMATION_COMPLETE_EVENT)) {
                        dispatchEvent(new openfl.events.Event(ANIMATION_COMPLETE_EVENT));
                    }
                }
            }
            applyCurrentFrame();
        }

        for (child in children) {
            var childHasOwnAnim = (child.frames != null && child.frames.length > 0) || (child.labels != null && child.labels.length > 0);
            if (childHasOwnAnim) {
                child.updateAnimation(dt);
            } else if (this.isPlaying && hasOwnFrames) {
                child._currentFrame = this._currentFrame;
                child.isPlaying = true;
                child.animationSpeed = this.animationSpeed;
                child._startFrame = this._startFrame;
                child._endFrame = this._endFrame;
                child.applyCurrentFrame();
                child.updateAnimation(dt);
            } else {
                child.updateAnimation(dt);
            }
        }
    }

    public function render(camera:Camera3D = null, clearDepth:Bool = false, target:Dynamic = null):Void {
        // Base Pivot3D does not draw geometry directly
    }

    public function draw(includeChildren:Bool = true, material:flare.materials.Material3D = null):Void {
        if (_dirty || parent == null) updateTransforms(true);
        render(flare.system.Device3D.camera);
        if (includeChildren) {
            for (c in children) {
                c.draw(includeChildren, material);
            }
        }
    }

    public function copyTransformFrom(pivot:Pivot3D):Void {
        if (pivot == null) return;
        this.matrix.copyFrom(pivot.matrix);
        this.x = matrix.rawData[12];
        this.y = matrix.rawData[13];
        this.z = matrix.rawData[14];
        this._dirty = true;
    }

    public function getDown(local:Bool = false):Vector3D {
        var up = getUp(local);
        up.negate();
        return up;
    }

    public function hide():Void {
        visible = false;
    }

    public function show():Void {
        visible = true;
    }

    public var scaleX(get, set):Float;
    private function get_scaleX():Float {
        var raw = matrix.rawData;
        return Math.sqrt(raw[0] * raw[0] + raw[1] * raw[1] + raw[2] * raw[2]);
    }
    private function set_scaleX(v:Float):Float {
        setScale(v, scaleY, scaleZ);
        return v;
    }

    public var scaleY(get, set):Float;
    private function get_scaleY():Float {
        var raw = matrix.rawData;
        return Math.sqrt(raw[4] * raw[4] + raw[5] * raw[5] + raw[6] * raw[6]);
    }
    private function set_scaleY(v:Float):Float {
        setScale(scaleX, v, scaleZ);
        return v;
    }

    public var scaleZ(get, set):Float;
    private function get_scaleZ():Float {
        var raw = matrix.rawData;
        return Math.sqrt(raw[8] * raw[8] + raw[9] * raw[9] + raw[10] * raw[10]);
    }
    private function set_scaleZ(v:Float):Float {
        setScale(scaleX, scaleY, v);
        return v;
    }

    public function setNormalOrientation(normal:Vector3D, smooth:Float = 1.0):Void {
        flare.utils.Matrix3DUtils.setNormalOrientation(matrix, normal, smooth);
        _dirty = true;
    }

    public function getScreenCoords(camera:Camera3D = null, out:Vector3D = null):Vector3D {
        if (out == null) out = new Vector3D();
        var cam = camera;
        if (cam == null && scene != null) cam = scene.camera;
        if (cam == null) cam = flare.system.Device3D.camera;
        if (cam == null) return out;
        var p = getPosition(false, out);
        var proj = cam.viewProjection.transformVector(p);
        out.w = proj.w;
        out.z = proj.z;
        if (proj.w > 0) {
            var vp = (cam != null && cam.viewPort != null) ? cam.viewPort : (scene != null ? scene.viewPort : new openfl.geom.Rectangle(0, 0, 800, 450));
            var halfW = vp.width * 0.5;
            var halfH = vp.height * 0.5;
            out.x = (proj.x / proj.w) * halfW + halfW + vp.x;
            out.y = (-proj.y / proj.w) * halfH + halfH + vp.y;
        }
        return out;
    }

    public function getScreenRect(out:openfl.geom.Rectangle = null, camera:Camera3D = null, viewPort:openfl.geom.Rectangle = null):Bool {
        return false;
    }

    public function setMaterial(mat:flare.materials.Material3D, includeChildren:Bool = true):Void {
        if (includeChildren) {
            for (c in children) {
                c.setMaterial(mat, true);
            }
        }
    }

    public function getMaterialByName(matName:String):flare.materials.Material3D {
        if (matName == null || matName == "") return null;
        if (Std.isOfType(this, flare.core.Mesh3D)) {
            var mesh:flare.core.Mesh3D = cast this;
            if (mesh.materials != null) {
                for (m in mesh.materials) {
                    if (m != null && m.name == matName) return m;
                }
            }
            if (mesh.surfaces != null) {
                for (s in mesh.surfaces) {
                    if (s != null && s.material != null && s.material.name == matName) return s.material;
                }
            }
        }
        for (c in children) {
            var m = c.getMaterialByName(matName);
            if (m != null) return m;
        }
        return null;
    }

    public function getMaterials():Array<flare.materials.Material3D> {
        var list:Array<flare.materials.Material3D> = [];
        collectMaterials(list);
        return list;
    }

    private function collectMaterials(out:Array<flare.materials.Material3D>):Void {
        if (Std.isOfType(this, flare.core.Mesh3D)) {
            var mesh:flare.core.Mesh3D = cast this;
            if (mesh.materials != null) {
                for (m in mesh.materials) {
                    if (m != null && out.indexOf(m) == -1) out.push(m);
                }
            }
            if (mesh.surfaces != null) {
                for (s in mesh.surfaces) {
                    if (s != null && s.material != null && out.indexOf(s.material) == -1) out.push(s.material);
                }
            }
        }
        for (c in children) {
            c.collectMaterials(out);
        }
    }

    public function copyTo(target:Pivot3D):Void {
        target.name = this.name;
        target.matrix.copyFrom(this.matrix);
        target.world.copyFrom(this.world);
        target.visible = this.visible;
        target.totalFrames = this.totalFrames;
        target.isPlaying = this.isPlaying;
        target.animationSpeed = this.animationSpeed;
        target._startFrame = this._startFrame;
        target._endFrame = this._endFrame;
        target._currentFrame = this._currentFrame;
        target.frames = this.frames;
        if (this.labels != null) {
            target.labels = [];
            for (l in this.labels) {
                target.labels.push(new Label3D(l.name, l.from, l.to));
            }
        }
        target.userData = this.userData;
    }

    public function cloneBasic():Pivot3D {
        var p = new Pivot3D(name);
        copyTo(p);
        return p;
    }

    public function clone():Pivot3D {
        var p = cloneBasic();
        cloneChildren(p);
        return p;
    }

    private function cloneChildren(target:Pivot3D):Void {
        var oldToNew = new Map<Pivot3D, Pivot3D>();
        oldToNew.set(this, target);

        var hasPrebakedSkin = false;
        this.forEach(function(p:Dynamic) {
            if (Std.isOfType(p, flare.core.Mesh3D)) {
                var m:flare.core.Mesh3D = cast p;
                if (m.modifier != null && Std.isOfType(m.modifier, flare.modifiers.SkinModifier)) {
                    var s:flare.modifiers.SkinModifier = cast m.modifier;
                    if (s.cachedFrames.keys().hasNext() || s.cachedGpuBuffers.keys().hasNext()) {
                        hasPrebakedSkin = true;
                    }
                }
            }
        });

        function cloneSubtree(src:Pivot3D, dst:Pivot3D):Void {
            for (c in src.children) {
                if (hasPrebakedSkin && StringTools.startsWith(c.name, "CATRig") && !Std.isOfType(c, flare.core.Mesh3D)) {
                    continue;
                }
                var childClone = c.cloneBasic();
                dst.addChild(childClone);
                oldToNew.set(c, childClone);
                cloneSubtree(c, childClone);
            }
        }

        cloneSubtree(this, target);
        remapSkins(target, oldToNew);
    }

    private function remapSkins(rootNode:Pivot3D, oldToNew:Map<Pivot3D, Pivot3D>):Void {
        rootNode.forEach(function(p:Dynamic) {
            if (Std.isOfType(p, flare.core.Mesh3D)) {
                var m:flare.core.Mesh3D = cast p;
                if (m.modifier != null && Std.isOfType(m.modifier, flare.modifiers.SkinModifier)) {
                    var oldSkin:flare.modifiers.SkinModifier = cast m.modifier;
                    var newSkin = new flare.modifiers.SkinModifier(m);
                    newSkin.bindTransform.copyFrom(oldSkin.bindTransform);
                    newSkin.numVertices = oldSkin.numVertices;
                    newSkin.totalFrames = oldSkin.totalFrames;
                    newSkin.origPositions = oldSkin.origPositions;
                    newSkin.origNormals = oldSkin.origNormals;
                    newSkin.weights = oldSkin.weights;
                    newSkin.boneIndices = oldSkin.boneIndices;
                    newSkin.skinData = oldSkin.skinData;
                    newSkin.cachedFrames = oldSkin.cachedFrames;
                    newSkin.cachedGpuBuffers = oldSkin.cachedGpuBuffers;

                    if (oldSkin.root != null && oldToNew.exists(oldSkin.root)) {
                        newSkin.root = oldToNew.get(oldSkin.root);
                    } else {
                        newSkin.root = rootNode;
                    }

                    for (i in 0...oldSkin.bones.length) {
                        var oldBone = oldSkin.bones[i];
                        var newBone = oldToNew.exists(oldBone) ? oldToNew.get(oldBone) : oldBone;
                        var invM = (i < oldSkin.invBoneMatrix.length) ? oldSkin.invBoneMatrix[i] : null;
                        newSkin.addBone(newBone, invM);
                    }
                    m.modifier = newSkin;
                }
            }
        });
    }

    public function dispose():Void {
        for (c in children) {
            c.dispose();
        }
        children = [];
    }
}
