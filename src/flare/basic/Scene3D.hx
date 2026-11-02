package flare.basic;

import openfl.display.DisplayObjectContainer;
import openfl.display.Stage;
import openfl.display.Stage3D;
import openfl.display3D.Context3D;
import openfl.events.Event;
import flare.core.Camera3D;
import flare.core.Light3D;
import flare.core.Pivot3D;
import flare.system.Device3D;

import flare.physics.Physics;

/**
 * Scene3D manages the Stage3D viewport, 3D scene graph root, and the main render loop.
 * Inherits Pivot3D as the top-level spatial container.
 */
class Scene3D extends Pivot3D {
    public static inline var SORT_NONE:Int = 0;
    public static inline var SORT_FRONT_TO_BACK:Int = 1;
    public static inline var SORT_BACK_TO_FRONT:Int = 2;

    private var _layerSortModes:Map<Int, Int> = new Map<Int, Int>();

    public function registerClass(c:Dynamic):Void {}

    public function setLayerSortMode(layer:Int, mode:Int):Void {
        _layerSortModes.set(layer, mode);
    }

    private function getSortedChildren(camera:Camera3D):Array<flare.core.Pivot3D> {
        var sorted = children.copy();
        var cRaw = camera.world.rawData;
        var cx = cRaw[12], cy = cRaw[13], cz = cRaw[14];
        sorted.sort(function(a, b) {
            if (a.layer != b.layer) return a.layer - b.layer;
            var mode = _layerSortModes.exists(a.layer) ? _layerSortModes.get(a.layer) : SORT_NONE;
            if (mode == SORT_NONE) return 0;
            var aRaw = a.world.rawData, bRaw = b.world.rawData;
            var dxa = aRaw[12] - cx, dya = aRaw[13] - cy, dza = aRaw[14] - cz;
            var dxb = bRaw[12] - cx, dyb = bRaw[13] - cy, dzb = bRaw[14] - cz;
            var distA = dxa * dxa + dya * dya + dza * dza;
            var distB = dxb * dxb + dyb * dyb + dzb * dzb;
            if (mode == SORT_FRONT_TO_BACK) {
                return (distA < distB) ? -1 : ((distA > distB) ? 1 : 0);
            } else if (mode == SORT_BACK_TO_FRONT) {
                return (distA > distB) ? -1 : ((distA < distB) ? 1 : 0);
            }
            return 0;
        });
        return sorted;
    }

    public var container:DisplayObjectContainer;
    public var stage:Stage;
    public var stage3D:Stage3D;
    public var context:Context3D;

    public var camera(default, set):Camera3D;
    private function set_camera(v:Camera3D):Camera3D {
        camera = v;
        if (camera != null) {
            flare.system.Device3D.camera = camera;
            camera.updateProjection(viewWidth, viewHeight);
        }
        return camera;
    }
    public var lights:flare.materials.filters.LightFilter;
    public var physics:Physics;
    public var library:flare.system.Library3D;
    public var allowImportSettings:Bool = true;

    
    public var targetTexture:flare.core.Texture3D = null;
    public var targetFilters:Array<flare.materials.Material3D> = [];
    private var _targetQuad:flare.primitives.Quad = null;

    private var _renderList:Array<flare.core.Pivot3D> = [];
    public var renderList(get, null):Array<flare.core.Pivot3D>;
    private function get_renderList():Array<flare.core.Pivot3D> {
        if (_renderList.length > 0) return _renderList;
        var list:Array<flare.core.Pivot3D> = [];
        collectMeshes(this, list);
        return list;
    }
    private function collectMeshes(node:flare.core.Pivot3D, out:Array<flare.core.Pivot3D>):Void {
        if (node == null) return;
        if (Std.isOfType(node, flare.core.Mesh3D)) out.push(node);
        for (c in node.children) collectMeshes(c, out);
    }

    public var clearColor:openfl.geom.Vector3D = new openfl.geom.Vector3D(0.25, 0.25, 0.25, 1.0);
    public var clearAlpha:Float = 1.0;
    public var backgroundColor(get, set):Int;
    private function get_backgroundColor():Int {
        var r = Math.round(clearColor.x * 255);
        var g = Math.round(clearColor.y * 255);
        var b = Math.round(clearColor.z * 255);
        return (r << 16) | (g << 8) | b;
    }
    private function set_backgroundColor(c:Int):Int {
        var r = ((c >> 16) & 0xff) / 255.0;
        var g = ((c >> 8) & 0xff) / 255.0;
        var b = (c & 0xff) / 255.0;
        clearColor.setTo(r, g, b);
        return c;
    }
    public var autoResize:Bool = true;
    public var antialiasing:Int = 2;
    public var paused:Bool = false;
    public var skipFrames:Bool = false;

    public var viewPort:openfl.geom.Rectangle = new openfl.geom.Rectangle(0, 0, 800, 600);
    public var antialias(get, set):Int;
    private function get_antialias():Int return antialiasing;
    private function set_antialias(v:Int):Int return antialiasing = v;

    public var frameRate(get, set):Float;
    private function get_frameRate():Float return (stage != null ? stage.frameRate : 60.0);
    private function set_frameRate(v:Float):Float {
        if (stage != null) stage.frameRate = v;
        return v;
    }

    public var viewWidth:Int = 800;
    public var viewHeight:Int = 600;
    private var _lastConfigW:Int = -1;
    private var _lastConfigH:Int = -1;
    private var _lastConfigAA:Int = -1;
    private var _inRenderEvent:Bool = false;
    private var _quadTextureMap:Map<flare.core.Texture3D, flare.primitives.Quad> = new Map();

    public function new(container:DisplayObjectContainer = null) {
        super("scene");
        this.scene = this;

        flare.system.DebugLog.log("[Scene3D] new() called, container=" + container + ", container.stage=" + (container != null ? container.stage : null) + ", Lib.current=" + openfl.Lib.current);

        this.container = container;
        this.lights = new flare.materials.filters.LightFilter();
        this.lights.scene = this;
        this.physics = new Physics();
        this.library = new flare.system.Library3D();
        this.library.scene = this;
        this.camera = new Camera3D("defaultCamera");
        this.camera.setPosition(0, 100, -300);
        this.camera.lookAt(0, 0, 0);

        Device3D.camera = this.camera;
        Device3D.defaultCamera = this.camera;

        var st:Stage = null;
        if (container != null && container.stage != null) {
            st = container.stage;
        } else if (openfl.Lib.current != null && openfl.Lib.current.stage != null) {
            st = openfl.Lib.current.stage;
        }

        if (st != null) {
            initStage(st);
        } else if (container != null) {
            container.addEventListener(Event.ADDED_TO_STAGE, onContainerAddedToStage);
        }
    }

    private function onContainerAddedToStage(e:Event):Void {
        if (container != null) {
            container.removeEventListener(Event.ADDED_TO_STAGE, onContainerAddedToStage);
            initStage(container.stage);
        }
    }

    private function initStage(st:Stage):Void {
        this.stage = st;
        Device3D.stage = st;
        if (st != null && st.stageWidth > 0 && st.stageHeight > 0) {
            viewWidth = st.stageWidth;
            viewHeight = st.stageHeight;
            viewPort.setTo(0, 0, viewWidth, viewHeight);
        }
        flare.system.Input3D.initialize(st);

        flare.system.DebugLog.log("[Scene3D] initStage: stage3Ds=" + (st != null ? st.stage3Ds.length : 0));

        if (st != null && st.stage3Ds.length > 0) {
            stage3D = st.stage3Ds[0];
            stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
            stage3D.requestContext3D(openfl.display3D.Context3DRenderMode.AUTO, openfl.display3D.Context3DProfile.BASELINE_EXTENDED);

            st.addEventListener(Event.RESIZE, onStageResize);
            st.addEventListener(Event.ENTER_FRAME, onEnterFrame);
            st.addEventListener(openfl.events.MouseEvent.MOUSE_MOVE, onStageMouseMove);
            st.addEventListener(openfl.events.MouseEvent.MOUSE_DOWN, onStageMouseDown);
            st.addEventListener(openfl.events.MouseEvent.MOUSE_UP, onStageMouseUp);
            st.addEventListener(openfl.events.MouseEvent.CLICK, onStageMouseClick);
        }
    }

    private function onContextCreated(e:Event):Void {
        if (stage3D == null) return;
        context = stage3D.context3D;
        Device3D.context = context;

        flare.system.DebugLog.log("[Scene3D] Context created: " + (context != null ? context.driverInfo : "null"));

        updateBackBuffer();
    }

    private function onStageResize(e:Event):Void {
        if (autoResize) {
            updateBackBuffer();
        }
    }

    public function update(delta:Float = 1.0):Void {
        flare.system.Input3D.update();
        if (physics != null) {
            physics.step(3, 1.0 / 60.0);
        }
        updateAnimation(delta);
        updateTransforms();
        if (camera != null) {
            camera.updateWorldMatrix();
            camera.updateViewProjection();
        }
        if (_updateEvt == null) _updateEvt = new openfl.events.Event(UPDATE_EVENT);
        dispatchEvent(_updateEvt);
        dispatchEnterFrameRecursive(this);
    }

    public function updateBackBuffer():Void {
        if (context == null || stage == null) return;

        var newW = stage.stageWidth > 0 ? stage.stageWidth : 800;
        var newH = stage.stageHeight > 0 ? stage.stageHeight : 450;
        if (newW <= 0 || newH <= 0) return;

        viewWidth = newW;
        viewHeight = newH;
        viewPort.setTo(0, 0, viewWidth, viewHeight);

        if (newW != _lastConfigW || newH != _lastConfigH || antialiasing != _lastConfigAA) {
            _lastConfigW = newW;
            _lastConfigH = newH;
            _lastConfigAA = antialiasing;
            #if html5
            context.configureBackBuffer(viewWidth, viewHeight, antialiasing, true, true, true);
            #else
            context.configureBackBuffer(viewWidth, viewHeight, antialiasing, true);
            #end
        }
        if (camera != null) {
            camera.updateProjection(viewWidth, viewHeight);
        }
    }

    private function onEnterFrame(e:Event):Void {
        if (!paused) {
            render();
        }
    }

    public static var profUpdate:Float = 0;
    public static var profAnim:Float = 0;
    public static var profTrans:Float = 0;
    public static var profRender:Float = 0;
    public static var profPresent:Float = 0;

    override public function render(camera:Camera3D = null, clearDepth:Bool = false, target:Dynamic = null):Void {
        if (context == null) return;
        if (camera == null) camera = this.camera;
        if (camera == null) return;

        Device3D.scene = this;
        Device3D.camera = camera;
        Device3D.resetStats();

        if (target != null) {
            var tex3D:flare.core.Texture3D = null;
            if (Std.isOfType(target, flare.core.Texture3D)) {
                tex3D = cast target;
            }
            if (tex3D != null) {
                if (tex3D.scene == null || tex3D.texture == null) {
                    tex3D.upload(this);
                }
                if (tex3D.texture != null) {
                    context.setRenderToTexture(tex3D.texture, true);
                }
                context.setScissorRectangle(null);
                if (camera.viewPort != null) {
                    camera.updateProjection(camera.viewPort.width, camera.viewPort.height);
                }
            }

            context.clear(0, 0, 0, 0, 1.0, 0);

            camera.updateWorldMatrix();
            camera.updateViewProjection();

            Device3D.camera = camera;
            Device3D.cameraGlobal.copyFrom(camera.world);
            Device3D.viewProj.copyFrom(camera.viewProjection);
            Device3D.proj.copyFrom(camera.projection);
            Device3D.view.copyFrom(camera.view);
            Device3D.currentMesh = null;
            Device3D.lastMaterial = null;
            Device3D.currentProgram = null;

            var cRaw = camera.world.rawData;
            Device3D.camX = cRaw[12];
            Device3D.camY = cRaw[13];
            Device3D.camZ = cRaw[14];

            var sortedChildren = getSortedChildren(camera);
for (child in sortedChildren) {
                renderNode(child, camera);
            }

            if (tex3D != null) {
                context.setRenderToBackBuffer();
                context.setScissorRectangle(null);
                if (this.camera != null && this.camera != camera) {
                    setupFrame(this.camera);
                }
            }
            return;
        }

        if (clearDepth) {
            // Secondary camera (e.g. PiP / surveillance camera)
            if (camera.viewPort != null) {
                context.setScissorRectangle(camera.viewPort);
                context.clear(0, 0, 0, 0, 1.0, 0, openfl.display3D.Context3DClearMask.DEPTH);
                camera.updateProjection(camera.viewPort.width, camera.viewPort.height);
            }
            camera.updateWorldMatrix();
            camera.updateViewProjection();

            var cRaw = camera.world.rawData;
            Device3D.camX = cRaw[12];
            Device3D.camY = cRaw[13];
            Device3D.camZ = cRaw[14];

            var sortedChildren = getSortedChildren(camera);
            for (child in sortedChildren) {
                renderNode(child, camera);
            }

            if (camera.viewPort != null) {
                context.setScissorRectangle(null);
            }
            return;
        }

        _renderList = [];

        var isOffscreen = (targetTexture != null);
        if (isOffscreen) {
            targetTexture.scene = this;
            if (targetTexture.texture == null) {
                targetTexture.upload(this);
            }
            if (targetTexture.texture != null) {
                context.setRenderToTexture(targetTexture.texture, true);
            }
        }

        if (_clipped) {
            context.setScissorRectangle(null);
            _clipped = false;
        }

        // 1. Clear frame buffer
        var cr = clearColor.x > 1.0 ? clearColor.x / 255.0 : clearColor.x;
        var cg = clearColor.y > 1.0 ? clearColor.y / 255.0 : clearColor.y;
        var cb = clearColor.z > 1.0 ? clearColor.z / 255.0 : clearColor.z;
        var ca = (clearColor.w != 1.0) ? clearColor.w : clearAlpha;
        context.clear(cr, cg, cb, ca, 1.0, 0);

        // Dispatch update event
        var t0 = openfl.Lib.getTimer();
        if (_updateEvt == null) _updateEvt = new openfl.events.Event(UPDATE_EVENT);
        dispatchEvent(_updateEvt);
        dispatchEnterFrameRecursive(this);
        var tUp = openfl.Lib.getTimer();
        profUpdate += (tUp - t0);

        // 2. Update physics, animation & transforms
        if (physics != null) {
            physics.step(3, 1.0 / 60.0);
        }
        var tPhys = openfl.Lib.getTimer();
        updateAnimation(1.0);
        var tAnim = openfl.Lib.getTimer();
        profAnim += (tAnim - tPhys);

        updateTransforms();
        camera.updateWorldMatrix();
        camera.updateViewProjection();
        var tTrans = openfl.Lib.getTimer();
        profTrans += (tTrans - tAnim);

        setupFrame(camera);

        var isIntercepted = false;
        if (!_inRenderEvent) {
            _inRenderEvent = true;
            if (_renderEvt == null) _renderEvt = new openfl.events.Event(RENDER_EVENT, false, true);
            dispatchEvent(_renderEvt);
            isIntercepted = _renderEvt.isDefaultPrevented();
            _inRenderEvent = false;
        }

        if (isIntercepted) {
            if (_postRenderEvt == null) _postRenderEvt = new openfl.events.Event(POSTRENDER_EVENT);
            dispatchEvent(_postRenderEvt);
            context.present();
            var tPresent = openfl.Lib.getTimer();
            profPresent += (tPresent - tTrans);
            flare.system.Input3D.update();
            Device3D.frame++;
            return;
        }

        // 3. Render scene nodes
        var sortedChildren = getSortedChildren(camera);
        for (child in sortedChildren) {
            renderNode(child, camera);
        }
        var tRender = openfl.Lib.getTimer();
        profRender += (tRender - tTrans);

        if (isOffscreen) {
            context.setRenderToBackBuffer();
            if (targetFilters != null && targetFilters.length > 0) {
                for (tf in targetFilters) {
                    if (Std.isOfType(tf, flare.flsl.FLSLMaterial)) {
                        var flslMat:flare.flsl.FLSLMaterial = cast tf;
                        flslMat.setTargetTexture(targetTexture);
                    }
                    if (_targetQuad == null) {
                        _targetQuad = new flare.primitives.Quad("targetQuad", 0, 0, 0, 0, true, tf);
                    } else {
                        _targetQuad.setMaterial(tf);
                    }
                    _targetQuad.scene = this;
                    _targetQuad.draw(false, tf);
                }
            } else {
                if (_targetQuad == null) {
                    _targetQuad = new flare.primitives.Quad("targetQuad", 0, 0, 0, 0, true, new flare.materials.Shader3D("targetMat", [new flare.materials.filters.TextureMapFilter(targetTexture)]));
                }
                _targetQuad.scene = this;
                _targetQuad.draw(false);
            }
        }

        if (_postRenderEvt == null) _postRenderEvt = new openfl.events.Event(POSTRENDER_EVENT);
        dispatchEvent(_postRenderEvt);


        // 4. Present
        if (!_inRenderEvent) {
            context.present();
            var tPresent = openfl.Lib.getTimer();
            profPresent += (tPresent - tRender);

            if (Device3D.frame % 30 == 0) {
                profUpdate = 0; profAnim = 0; profTrans = 0; profRender = 0; profPresent = 0;
            }
            flare.system.Input3D.update();
            Device3D.frame++;
        }
    }

    public static inline var PROGRESS_EVENT:String = "progress";
    public static inline var COMPLETE_EVENT:String = "complete";
    public static inline var UPDATE_EVENT:String = "update";
    public static inline var RENDER_EVENT:String = "render";
    public static inline var POSTRENDER_EVENT:String = "postRender";
    private static var _postRenderEvt:Event = null;

    public function setupConstants():Void {
        if (context == null) return;
        var w = (viewPort != null) ? viewPort.width : (stage != null ? stage.stageWidth : 800.0);
        var h = (viewPort != null) ? viewPort.height : (stage != null ? stage.stageHeight : 600.0);
        Device3D.screen[0] = w;
        Device3D.screen[1] = h;
        Device3D.screen[2] = 1.0 / (w > 0 ? w : 1.0);
        Device3D.screen[3] = 1.0 / (h > 0 ? h : 1.0);

        Device3D.random[0] = Math.random();
        Device3D.random[1] = Math.random();
        Device3D.random[2] = Math.random();
        Device3D.random[3] = Math.random();

        Device3D.lastMaterial = null;
        Device3D.currentProgram = null;
    }

    private var _clipped:Bool = false;

    public function setupFrame(camera:Camera3D = null):Void {
        if (context == null) return;
        if (camera == null) camera = this.camera;
        if (camera == null) return;

        camera.scene = this;

        Device3D.scene = this;
        Device3D.camera = camera;
        Device3D.context = context;

        var vp = (camera.viewPort != null) ? camera.viewPort : this.viewPort;
        Device3D.viewPort = vp;

        if (camera.viewPort != null && camera.clipRectangle) {
            context.setScissorRectangle(camera.viewPort);
            _clipped = true;
        } else if (_clipped) {
            context.setScissorRectangle(null);
            _clipped = false;
        }

        camera.updateTransforms(true);
        camera.updateProjection();
        camera.updateViewProjection();

        Device3D.cameraGlobal.copyFrom(camera.world);
        Device3D.viewProj.copyFrom(camera.viewProjection);
        Device3D.proj.copyFrom(camera.projection);
        Device3D.view.copyFrom(camera.view);
        Device3D.currentMesh = null;
        Device3D.lastMaterial = null;
        Device3D.currentProgram = null;

        var cRaw = camera.world.rawData;
        Device3D.camX = cRaw[12];
        Device3D.camY = cRaw[13];
        Device3D.camZ = cRaw[14];
        
        Device3D.cam[0] = cRaw[12];
        Device3D.cam[1] = cRaw[13];
        Device3D.cam[2] = cRaw[14];
        Device3D.cam[3] = 1.0;

        Device3D.nearFar[0] = camera.near;
        Device3D.nearFar[1] = camera.far;
        Device3D.nearFar[2] = camera.far - camera.near;
        Device3D.nearFar[3] = (camera.far - camera.near != 0) ? (1.0 / (camera.far - camera.near)) : 0.0;

        setupConstants();
    }

        private static var _quadProgram:openfl.display3D.Program3D;
    private static var _alphaQuadProgram:openfl.display3D.Program3D;
    private static var _radialBlurProgram:openfl.display3D.Program3D;
    private static var _blurAndBlendProgram:openfl.display3D.Program3D;
    private static var _blurParams:openfl.Vector<Float> = new openfl.Vector<Float>(4);
    private static var _quadMvp:openfl.geom.Matrix3D = new openfl.geom.Matrix3D();
    private static var _quadSurf:flare.core.Surface3D;

    private function parseBlendFactor(factor:String, defaultFactor:openfl.display3D.Context3DBlendFactor):openfl.display3D.Context3DBlendFactor {
        if (factor == null) return defaultFactor;
        var f = factor.toLowerCase();
        if (f == "one") return openfl.display3D.Context3DBlendFactor.ONE;
        if (f == "zero") return openfl.display3D.Context3DBlendFactor.ZERO;
        if (f == "sourcealpha" || f == "source_alpha") return openfl.display3D.Context3DBlendFactor.SOURCE_ALPHA;
        if (f == "oneminussourcealpha" || f == "one_minus_source_alpha") return openfl.display3D.Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
        if (f == "destcolor" || f == "dest_color") return openfl.display3D.Context3DBlendFactor.DESTINATION_COLOR;
        if (f == "sourcecolor" || f == "source_color") return openfl.display3D.Context3DBlendFactor.SOURCE_COLOR;
        return defaultFactor;
    }

    public function drawQuadTexture(texture:flare.core.Texture3D, x:Float, y:Float, width:Float, height:Float, material:flare.materials.Material3D = null, sourceFactor:String = null, destFactor:String = null):Void {
        if (context == null) return;

        var flslMat:flare.flsl.FLSLMaterial = Std.isOfType(material, flare.flsl.FLSLMaterial) ? cast material : null;
        if (flslMat != null && flslMat.params != null) {
            if (flslMat.params.outputTexture != null && Std.isOfType(flslMat.params.outputTexture.value, flare.core.Texture3D)) {
                var outTex:flare.core.Texture3D = cast flslMat.params.outputTexture.value;
                if (outTex.texture == null) outTex.upload(this);
                if (outTex.texture != null) {
                    context.setRenderToTexture(outTex.texture, true);
                }
            }
            if (texture == null) {
                if (flslMat.params.inputTexture != null && Std.isOfType(flslMat.params.inputTexture.value, flare.core.Texture3D)) {
                    texture = cast flslMat.params.inputTexture.value;
                } else if (flslMat.params.texture != null && Std.isOfType(flslMat.params.texture.value, flare.core.Texture3D)) {
                    texture = cast flslMat.params.texture.value;
                }
            }
        }

        if (texture == null) return;
        if (texture.texture == null) {
            texture.upload(this);
        }
        if (texture.texture == null) return;

        var asm = new openfl.utils.AGALMiniAssembler();
        if (_quadProgram == null) {
            var vSrc = "m44 op, va0, vc0\nmov v0, va1\n";
            var fSrc = "tex ft0, v0, fs0 <2d,linear,mipnone,clamp>\nmov oc, ft0\n";
            _quadProgram = asm.assemble2(context, 1, vSrc, fSrc);
        }
        if (_alphaQuadProgram == null) {
            var vSrc = "m44 op, va0, vc0\nmov v0, va1\n";
            var fSrc = "tex ft0, v0, fs0 <2d,linear,mipnone,clamp>\nmov ft0.w, fc0.x\nmov oc, ft0\n";
            _alphaQuadProgram = asm.assemble2(context, 1, vSrc, fSrc);
        }
        if (_radialBlurProgram == null) {
            var vSrc = "m44 op, va0, vc0\nmov v0, va1\n";
            var fSrc = "sub ft1.xy, fc0.xy, v0.xy\n" +
                "tex ft0, v0, fs0 <2d,linear,clamp>\n" +
                "mul ft2.xy, ft1.xy, fc2.xxxx\nadd ft3.xy, v0.xy, ft2.xy\ntex ft4, ft3.xy, fs0 <2d,linear,clamp>\nadd ft0, ft0, ft4\n" +
                "mul ft2.xy, ft1.xy, fc2.yyyy\nadd ft3.xy, v0.xy, ft2.xy\ntex ft4, ft3.xy, fs0 <2d,linear,clamp>\nadd ft0, ft0, ft4\n" +
                "mul ft2.xy, ft1.xy, fc2.zzzz\nadd ft3.xy, v0.xy, ft2.xy\ntex ft4, ft3.xy, fs0 <2d,linear,clamp>\nadd ft0, ft0, ft4\n" +
                "mul ft2.xy, ft1.xy, fc2.wwww\nadd ft3.xy, v0.xy, ft2.xy\ntex ft4, ft3.xy, fs0 <2d,linear,clamp>\nadd ft0, ft0, ft4\n" +
                "mul ft2.xy, ft1.xy, fc3.xxxx\nadd ft3.xy, v0.xy, ft2.xy\ntex ft4, ft3.xy, fs0 <2d,linear,clamp>\nadd ft0, ft0, ft4\n" +
                "mul ft2.xy, ft1.xy, fc3.yyyy\nadd ft3.xy, v0.xy, ft2.xy\ntex ft4, ft3.xy, fs0 <2d,linear,clamp>\nadd ft0, ft0, ft4\n" +
                "mul ft2.xy, ft1.xy, fc3.zzzz\nadd ft3.xy, v0.xy, ft2.xy\ntex ft4, ft3.xy, fs0 <2d,linear,clamp>\nadd ft0, ft0, ft4\n" +
                "mul ft2.xy, ft1.xy, fc3.wwww\nadd ft3.xy, v0.xy, ft2.xy\ntex ft4, ft3.xy, fs0 <2d,linear,clamp>\nadd ft0, ft0, ft4\n" +
                "mul ft0.xyz, ft0.xyz, fc1.yyyy\n" +
                "mul ft0.xyz, ft0.xyz, fc1.zzzz\n" +
                "mov ft0.w, fc0.w\n" +
                "mov oc, ft0\n";
            _radialBlurProgram = asm.assemble2(context, 1, vSrc, fSrc);
        }
        if (_blurAndBlendProgram == null) {
            var vSrc = "m44 op, va0, vc0\nmov v0, va1\n";
            var fSrc = "sub ft1.xy, v0.xy, fc0.xy\ntex ft0, ft1.xy, fs0 <2d,linear,clamp>\n" +
                "add ft1.xy, v0.xy, fc0.xy\ntex ft2, ft1.xy, fs0 <2d,linear,clamp>\nadd ft0, ft0, ft2\n" +
                "sub ft1.xy, v0.xy, fc0.zw\ntex ft2, ft1.xy, fs0 <2d,linear,clamp>\nadd ft0, ft0, ft2\n" +
                "add ft1.xy, v0.xy, fc0.zw\ntex ft2, ft1.xy, fs0 <2d,linear,clamp>\nadd ft0, ft0, ft2\n" +
                "mul ft0.xyz, ft0.xyz, fc1.xxxx\nmov ft0.w, fc1.yyyy\nmov oc, ft0\n";
            _blurAndBlendProgram = asm.assemble2(context, 1, vSrc, fSrc);
        }

        if (_quadSurf == null) {
            _quadSurf = new flare.core.Surface3D("quad_surf");
            _quadSurf.addVertexData(flare.core.Surface3D.POSITION, 3);
            _quadSurf.addVertexData(flare.core.Surface3D.UV0, 2);
            var v = _quadSurf.vertexData;
            var i = _quadSurf.indexData;
            v.push(-1); v.push(1); v.push(0); v.push(0); v.push(0);
            v.push(1); v.push(1); v.push(0); v.push(1); v.push(0);
            v.push(-1); v.push(-1); v.push(0); v.push(0); v.push(1);
            v.push(1); v.push(-1); v.push(0); v.push(1); v.push(1);
            i.push(0); i.push(2); i.push(1);
            i.push(2); i.push(3); i.push(1);
            _quadSurf.upload(context);
        }

        var vpW = (viewPort != null && viewPort.width > 0) ? viewPort.width : (stage != null ? stage.stageWidth : 800.0);
        var vpH = (viewPort != null && viewPort.height > 0) ? viewPort.height : (stage != null ? stage.stageHeight : 450.0);

        var rx = x / vpW;
        var ry = y / vpH;
        var rw = width / vpW;
        var rh = height / vpH;
        _quadMvp.identity();
        _quadMvp.appendScale(rw != 0 ? rw : 0.00001, rh != 0 ? rh : 0.00001, 1);
        _quadMvp.appendTranslation(-1 + rw + rx * 2, 1 - rh - ry * 2, 0);

        var isRadial = (flslMat != null && (flslMat.name.indexOf("radialBlur") != -1 || (flslMat.source != null && Std.string(flslMat.source).indexOf("radialBlur") != -1)));
        var isBlurBlend = (flslMat != null && !isRadial && (flslMat.name.indexOf("blurAndBlend") != -1 || (flslMat.source != null && Std.string(flslMat.source).indexOf("blurAndBlend") != -1)));
        var isAlphaQuad = (flslMat != null && !isRadial && !isBlurBlend && (flslMat.name.indexOf("blurQuad") != -1 || flslMat.name == "blur" || (flslMat.source != null && Std.string(flslMat.source).indexOf("blurQuad") != -1)));

        var prog = _quadProgram;
        if (isRadial) {
            prog = _radialBlurProgram;
        } else if (isBlurBlend) {
            prog = _blurAndBlendProgram;
        } else if (isAlphaQuad) {
            prog = _alphaQuadProgram;
        }

        context.setProgram(prog);
        context.setProgramConstantsFromMatrix(openfl.display3D.Context3DProgramType.VERTEX, 0, _quadMvp, true);
        context.setTextureAt(0, texture.texture);

        if (isRadial) {
            context.setProgramConstantsFromVector(openfl.display3D.Context3DProgramType.FRAGMENT, 0, openfl.Vector.ofArray([0.5, 0.5, 0.0, 1.0]));
            context.setProgramConstantsFromVector(openfl.display3D.Context3DProgramType.FRAGMENT, 1, openfl.Vector.ofArray([0.6, 2.0, 0.1111, 0.0]));
            context.setProgramConstantsFromVector(openfl.display3D.Context3DProgramType.FRAGMENT, 2, openfl.Vector.ofArray([0.06, 0.12, 0.18, 0.24]));
            context.setProgramConstantsFromVector(openfl.display3D.Context3DProgramType.FRAGMENT, 3, openfl.Vector.ofArray([0.30, 0.36, 0.42, 0.48]));
        } else if (isBlurBlend) {
            context.setProgramConstantsFromVector(openfl.display3D.Context3DProgramType.FRAGMENT, 0, openfl.Vector.ofArray([1.0 / 512.0, 0.0, 0.0, 1.0 / 512.0]));
            context.setProgramConstantsFromVector(openfl.display3D.Context3DProgramType.FRAGMENT, 1, openfl.Vector.ofArray([0.25, 1.0, 0.0, 0.0]));
        } else if (isAlphaQuad) {
            var aVal:Float = (flslMat.params.alpha.value != null && flslMat.params.alpha.value.length > 0) ? flslMat.params.alpha.value[0] : 1.0;
            context.setProgramConstantsFromVector(openfl.display3D.Context3DProgramType.FRAGMENT, 0, openfl.Vector.ofArray([aVal, 0.0, 0.0, 1.0]));
        }

        context.setVertexBufferAt(0, _quadSurf.vertexBuffer, 0, openfl.display3D.Context3DVertexBufferFormat.FLOAT_3);
        context.setVertexBufferAt(1, _quadSurf.vertexBuffer, 3, openfl.display3D.Context3DVertexBufferFormat.FLOAT_2);
        context.setVertexBufferAt(2, null);
        context.setVertexBufferAt(3, null);
        context.setDepthTest(false, openfl.display3D.Context3DCompareMode.ALWAYS);
        context.setCulling(openfl.display3D.Context3DTriangleFace.NONE);

        var srcBlend = parseBlendFactor(sourceFactor, (isAlphaQuad ? openfl.display3D.Context3DBlendFactor.SOURCE_ALPHA : openfl.display3D.Context3DBlendFactor.ONE));
        var dstBlend = parseBlendFactor(destFactor, (isAlphaQuad ? openfl.display3D.Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA : openfl.display3D.Context3DBlendFactor.ZERO));
        context.setBlendFactors(srcBlend, dstBlend);

        context.drawTriangles(_quadSurf.indexBuffer, 0, 2);
        
        context.setTextureAt(0, null);
        for (a in 0...4) context.setVertexBufferAt(a, null);
        flare.system.Device3D.currentVertexBuffer = null;
        flare.system.Device3D.currentSurface = null;
        flare.system.Device3D.resetStats();
    }

    public function endFrame():Void {
        if (context == null) return;
        for (i in 0...8) {
            context.setTextureAt(i, null);
            context.setVertexBufferAt(i, null);
        }
        Device3D.resetStats();
    }

    public function setViewport(x:Float, y:Float, width:Float, height:Float, antialiasVal:Int = -1):Void {
        viewPort.setTo(x, y, width, height);
        viewWidth = Std.int(width);
        viewHeight = Std.int(height);
        if (antialiasVal >= 0) antialiasing = antialiasVal;
        if (context != null) {
            #if html5
            context.configureBackBuffer(viewWidth, viewHeight, antialiasing, true, true, true);
            #else
            context.configureBackBuffer(viewWidth, viewHeight, antialiasing, true);
            #end
        }
        if (camera != null) camera.updateProjection(viewWidth, viewHeight);
    }
    private static var _updateEvt:Event = null;
    private static var _renderEvt:Event = null;

    public var loadProgress:Float = 1.0;
    public var pendingLoads:Int = 0;

    public function notifyLoadComplete():Void {
        pendingLoads--;
        if (pendingLoads <= 0) {
            pendingLoads = 0;
            loadProgress = 1.0;
            var self = this;
            var onNextFrame:Event->Void = null;
            onNextFrame = function(e:Event) {
                var s = self.stage != null ? self.stage : (openfl.Lib.current != null ? openfl.Lib.current.stage : null);
                if (s != null) {
                    s.removeEventListener(Event.ENTER_FRAME, onNextFrame);
                }
                self.dispatchEvent(new Event(COMPLETE_EVENT));
            };
            var stg = stage != null ? stage : (openfl.Lib.current != null ? openfl.Lib.current.stage : null);
            if (stg != null) {
                stg.addEventListener(Event.ENTER_FRAME, onNextFrame);
            } else {
                haxe.Timer.delay(function() {
                    self.dispatchEvent(new Event(COMPLETE_EVENT));
                }, 30);
            }
        }
    }

    public function pause():Void {
        paused = true;
    }

    public function resume():Void {
        paused = false;
    }

    override public function addChild(child:flare.core.Pivot3D):flare.core.Pivot3D {
        super.addChild(child);
        child.setScene(this);
        if (Std.isOfType(child, flare.core.Light3D)) {
            var l:flare.core.Light3D = cast child;
            if (lights.list.indexOf(l) == -1) lights.list.push(l);
        }
        return child;
    }

    override public function removeChild(child:flare.core.Pivot3D):flare.core.Pivot3D {
        super.removeChild(child);
        if (Std.isOfType(child, flare.core.Light3D)) {
            lights.list.remove(cast child);
        }
        return child;
    }

    public function addChildFromFile(url:String, parent:Pivot3D = null, loaderClass:Dynamic = null):Pivot3D {
        pendingLoads++;
        var ext = haxe.io.Path.extension(url).toLowerCase();
        var targetParent = parent != null ? parent : this;
        if (ext == "obj") {
            var loader = new flare.loaders.OBJLoader(url);
            targetParent.addChild(loader);
            return loader;
        } else if (ext == "zf3d" || ext == "f3d") {
            var loader = new flare.loaders.ZF3DLoader();
            loader.url = url;
            loader.scene = this;
            targetParent.addChild(loader);
            loader.load();
            return loader;
        } else if (ext == "dae" || loaderClass == flare.loaders.ColladaLoader) {
            var loader = new flare.loaders.ColladaLoader(url, parent, this);
            targetParent.addChild(loader);
            return loader;
        } else {
            var loader = new flare.loaders.Flare3DLoader();
            loader.url = url;
            loader.scene = this;
            targetParent.addChild(loader);
            loader.load();
            return loader;
        }
    }

    public function addTextureFromFile(url:String):flare.core.Texture3D {
        var tex = new flare.core.Texture3D(url);
        return tex;
    }

    override public function updateAnimation(dt:Float = 1.0):Void {
        // Scene3D is the scene root container and should never overwrite child animation states!
        for (child in children) {
            child.updateAnimation(dt);
        }
    }

    override private function set_currentFrame(v:Float):Float {
        _currentFrame = v;
        return _currentFrame;
    }

    private function renderNode(node:Pivot3D, cam:Camera3D):Void {
        if (node == null || !node.visible) return;

        if (Std.isOfType(node, flare.core.Mesh3D)) {
            _renderList.push(node);
        }

                node.render(cam);

        for (child in node.children) {
            renderNode(child, cam);
        }
    }

    private var _hoveredPivot:Pivot3D = null;
    private var _lastHitInfo:flare.collisions.CollisionInfo = null;

    private function dispatchEnterFrameRecursive(pivot:Pivot3D):Void {
        if (pivot == null) return;
        if (pivot.hasEventListener(flare.core.Pivot3D.ENTER_FRAME_EVENT)) {
            pivot.dispatchEvent(new openfl.events.Event(flare.core.Pivot3D.ENTER_FRAME_EVENT));
        }
        for (c in pivot.children) {
            dispatchEnterFrameRecursive(c);
        }
    }

    public function getScreenRay(stageX:Float, stageY:Float):{origin:openfl.geom.Vector3D, dir:openfl.geom.Vector3D} {
        if (camera == null) return null;
        var w:Float = viewWidth > 0 ? viewWidth : 800.0;
        var h:Float = viewHeight > 0 ? viewHeight : 600.0;
        var ndcX = (stageX / w) * 2.0 - 1.0;
        var ndcY = 1.0 - (stageY / h) * 2.0;

        var fovRad = (camera.fieldOfView > 0 ? camera.fieldOfView : 45.0) * Math.PI / 180.0;
        var tanHalfFov = Math.tan(fovRad * 0.5);
        var aspect = (h > 0) ? (w / h) : (800.0 / 600.0);

        var dirView = new openfl.geom.Vector3D(ndcX * tanHalfFov * aspect, ndcY * tanHalfFov, 1.0);
        dirView.normalize();

        var origin = camera.getPosition(false);
        var dirWorld = camera.world.deltaTransformVector(dirView);
        dirWorld.normalize();

        return {origin: origin, dir: dirWorld};
    }

    private function testNodeIntersection(node:Pivot3D, origin:openfl.geom.Vector3D, dir:openfl.geom.Vector3D):flare.collisions.CollisionInfo {
        if (!node.visible) return null;
        if (!Std.isOfType(node, flare.core.Mesh3D)) return null;

        var mesh:flare.core.Mesh3D = cast node;
        // 忽略纯背面剔除描边材质物体 (例如 stroke)，避免遮挡交互模型
        if (mesh.material != null && mesh.material.cullFace == openfl.display3D.Context3DTriangleFace.FRONT) {
            return null;
        }

        node.updateWorldMatrix();

        var invWorld = node.world.clone();
        invWorld.invert();

        var localOrigin = invWorld.transformVector(origin);
        var localDir = invWorld.deltaTransformVector(dir);
        var dirLen = localDir.length;
        if (dirLen < 0.00001) return null;
        localDir.scaleBy(1.0 / dirLen);

        if (Std.isOfType(node, flare.primitives.Plane)) {
            var plane:flare.primitives.Plane = cast node;
            if (Math.abs(localDir.z) > 0.00001) {
                var t = -localOrigin.z / localDir.z;
                if (t > 0) {
                    var hx = localOrigin.x + localDir.x * t;
                    var hy = localOrigin.y + localDir.y * t;
                    var halfW = plane.width > 0 ? plane.width * 0.5 : 20.0;
                    var halfH = plane.depth > 0 ? plane.depth * 0.5 : 20.0;

                    if (Math.abs(hx) <= halfW && Math.abs(hy) <= halfH) {
                        var hitLocal = new openfl.geom.Vector3D(hx, hy, 0);
                        var hitWorld = node.localToGlobal(hitLocal);
                        var hitNormWorld = node.world.deltaTransformVector(new openfl.geom.Vector3D(0, 0, localDir.z < 0 ? 1 : -1));
                        hitNormWorld.normalize();
                        var worldDist = openfl.geom.Vector3D.distance(origin, hitWorld);
                        return new flare.collisions.CollisionInfo(hitWorld, hitNormWorld, worldDist, mesh);
                    }
                }
            }
            return null;
        }

        // 1. Broadphase: 包围盒 (AABB) 粗筛测试
        var bounds = mesh.getBounds();
        if (bounds != null && bounds.min != null && bounds.max != null && Math.isFinite(bounds.min.x)) {
            var tmin = -1e9;
            var tmax = 1e9;

            if (Math.abs(localDir.x) > 0.00001) {
                var tx1 = (bounds.min.x - localOrigin.x) / localDir.x;
                var tx2 = (bounds.max.x - localOrigin.x) / localDir.x;
                tmin = Math.max(tmin, Math.min(tx1, tx2));
                tmax = Math.min(tmax, Math.max(tx1, tx2));
            } else if (localOrigin.x < bounds.min.x || localOrigin.x > bounds.max.x) {
                return null;
            }

            if (Math.abs(localDir.y) > 0.00001) {
                var ty1 = (bounds.min.y - localOrigin.y) / localDir.y;
                var ty2 = (bounds.max.y - localOrigin.y) / localDir.y;
                tmin = Math.max(tmin, Math.min(ty1, ty2));
                tmax = Math.min(tmax, Math.max(ty1, ty2));
            } else if (localOrigin.y < bounds.min.y || localOrigin.y > bounds.max.y) {
                return null;
            }

            if (Math.abs(localDir.z) > 0.00001) {
                var tz1 = (bounds.min.z - localOrigin.z) / localDir.z;
                var tz2 = (bounds.max.z - localOrigin.z) / localDir.z;
                tmin = Math.max(tmin, Math.min(tz1, tz2));
                tmax = Math.min(tmax, Math.max(tz1, tz2));
            } else if (localOrigin.z < bounds.min.z || localOrigin.z > bounds.max.z) {
                return null;
            }

            if (tmax < tmin || tmax <= 0) {
                return null;
            }
        } else {
            // 包围球粗筛
            var radius = 50.0;
            if (bounds != null && bounds.radius > 0) radius = bounds.radius;
            var toCenter = new openfl.geom.Vector3D(-localOrigin.x, -localOrigin.y, -localOrigin.z);
            var proj = toCenter.x * localDir.x + toCenter.y * localDir.y + toCenter.z * localDir.z;
            if (proj <= 0) return null;
            var distSq = toCenter.lengthSquared - (proj * proj);
            if (distSq > radius * radius) return null;
        }

        // 2. Narrowphase: 真实多边形网格精确求交 (Möller–Trumbore 三角形相交算法)
        var closestT:Float = 1e9;
        var hitLocalX:Float = 0;
        var hitLocalY:Float = 0;
        var hitLocalZ:Float = 0;
        var hitNormX:Float = 0;
        var hitNormY:Float = 0;
        var hitNormZ:Float = 1;
        var hitU:Float = 0;
        var hitV:Float = 0;
        var hitFound:Bool = false;
        var bestSurface:flare.core.Surface3D = null;

        if (mesh.surfaces != null && mesh.surfaces.length > 0) {
            for (surf in mesh.surfaces) {
                if (surf == null || surf.vertexData == null) continue;
                var vData = surf.vertexData;
                var iData = surf.indexData;
                var stride = surf.vertexStride > 0 ? surf.vertexStride : 8;

                if (iData != null && iData.length >= 3) {
                    var numIndices = iData.length;
                    var k = 0;
                    while (k < numIndices) {
                        var idx0 = iData[k] * stride;
                        var idx1 = iData[k + 1] * stride;
                        var idx2 = iData[k + 2] * stride;
                        k += 3;

                        var v0x = vData[idx0]; var v0y = vData[idx0 + 1]; var v0z = vData[idx0 + 2];
                        var v1x = vData[idx1]; var v1y = vData[idx1 + 1]; var v1z = vData[idx1 + 2];
                        var v2x = vData[idx2]; var v2y = vData[idx2 + 1]; var v2z = vData[idx2 + 2];

                        var e1x = v1x - v0x; var e1y = v1y - v0y; var e1z = v1z - v0z;
                        var e2x = v2x - v0x; var e2y = v2y - v0y; var e2z = v2z - v0z;

                        var pvecX = localDir.y * e2z - localDir.z * e2y;
                        var pvecY = localDir.z * e2x - localDir.x * e2z;
                        var pvecZ = localDir.x * e2y - localDir.y * e2x;

                        var det = e1x * pvecX + e1y * pvecY + e1z * pvecZ;
                        if (Math.abs(det) < 0.000001) continue;
                        var invDet = 1.0 / det;

                        var tvecX = localOrigin.x - v0x;
                        var tvecY = localOrigin.y - v0y;
                        var tvecZ = localOrigin.z - v0z;

                        var u = (tvecX * pvecX + tvecY * pvecY + tvecZ * pvecZ) * invDet;
                        if (u < 0.0 || u > 1.0) continue;

                        var qvecX = tvecY * e1z - tvecZ * e1y;
                        var qvecY = tvecZ * e1x - tvecX * e1z;
                        var qvecZ = tvecX * e1y - tvecY * e1x;

                        var v = (localDir.x * qvecX + localDir.y * qvecY + localDir.z * qvecZ) * invDet;
                        if (v < 0.0 || u + v > 1.0) continue;

                        var t = (e2x * qvecX + e2y * qvecY + e2z * qvecZ) * invDet;
                        if (t > 0.001 && t < closestT) {
                            closestT = t;
                            hitLocalX = localOrigin.x + localDir.x * t;
                            hitLocalY = localOrigin.y + localDir.y * t;
                            hitLocalZ = localOrigin.z + localDir.z * t;
                            var fnx = e1y * e2z - e1z * e2y;
                            var fny = e1z * e2x - e1x * e2z;
                            var fnz = e1x * e2y - e1y * e2x;
                            var fnLen = Math.sqrt(fnx * fnx + fny * fny + fnz * fnz);
                            if (fnLen > 0.000001) {
                                hitNormX = fnx / fnLen;
                                hitNormY = fny / fnLen;
                                hitNormZ = fnz / fnLen;
                            }
                            hitFound = true;
                            bestSurface = surf;

                            if (idx0 + 4 < vData.length && idx1 + 4 < vData.length && idx2 + 4 < vData.length) {
                                var wCoord = 1.0 - u - v;
                                var uv0_u = vData[idx0 + 3];
                                var uv0_v = vData[idx0 + 4];
                                var uv1_u = vData[idx1 + 3];
                                var uv1_v = vData[idx1 + 4];
                                var uv2_u = vData[idx2 + 3];
                                var uv2_v = vData[idx2 + 4];
                                hitU = wCoord * uv0_u + u * uv1_u + v * uv2_u;
                                hitV = wCoord * uv0_v + u * uv1_v + v * uv2_v;
                            }
                        }
                    }
                }
            }
        }

        if (hitFound) {
            var hitLocal = new openfl.geom.Vector3D(hitLocalX, hitLocalY, hitLocalZ);
            var hitWorld = node.localToGlobal(hitLocal);
            var hitNormWorld = node.world.deltaTransformVector(new openfl.geom.Vector3D(hitNormX, hitNormY, hitNormZ));
            hitNormWorld.normalize();
            var worldDist = openfl.geom.Vector3D.distance(origin, hitWorld);
            var cInfo = new flare.collisions.CollisionInfo(hitWorld, hitNormWorld, worldDist, mesh);
            cInfo.surface = bestSurface;
            cInfo.u = hitU;
            cInfo.v = hitV;
            return cInfo;
        }

        return null;
    }

    private function raycastRecursive(node:Pivot3D, origin:openfl.geom.Vector3D, dir:openfl.geom.Vector3D, best:{pivot:Pivot3D, info:flare.collisions.CollisionInfo}):Void {
        if (!node.visible) return;

        var info = testNodeIntersection(node, origin, dir);
        if (info != null) {
            if (best.info == null || info.distance < best.info.distance) {
                best.info = info;
                best.pivot = node;
            }
        }

        for (child in node.children) {
            raycastRecursive(child, origin, dir, best);
        }
    }

    private function onStageMouseMove(e:openfl.events.MouseEvent):Void {
        var ray = getScreenRay(e.stageX, e.stageY);
        if (ray == null) return;
        var best = {pivot: null, info: null};
        raycastRecursive(this, ray.origin, ray.dir, best);

        var hitPivot = best.pivot;
        var hitInfo = best.info;
        if (hitPivot != null) {
            // mouse hover hit
        }
        if (hitPivot != null && hitInfo != null) {
            if (hitInfo.mesh == null && Std.isOfType(hitPivot, flare.core.Mesh3D)) {
                hitInfo.mesh = cast hitPivot;
            }
            if (hitInfo.target == null) {
                hitInfo.target = hitPivot;
            }
        }

        if (hitPivot != _hoveredPivot) {
            if (_hoveredPivot != null) {
                if (_hoveredPivot.hasEventListener(flare.events.MouseEvent3D.MOUSE_OUT)) {
                    _hoveredPivot.dispatchEvent(new flare.events.MouseEvent3D(flare.events.MouseEvent3D.MOUSE_OUT, _lastHitInfo, true));
                }
                openfl.ui.Mouse.cursor = openfl.ui.MouseCursor.AUTO;
            }
            _hoveredPivot = hitPivot;
            _lastHitInfo = hitInfo;
            if (_hoveredPivot != null) {
                if (_hoveredPivot.hasEventListener(flare.events.MouseEvent3D.MOUSE_OVER)) {
                    _hoveredPivot.dispatchEvent(new flare.events.MouseEvent3D(flare.events.MouseEvent3D.MOUSE_OVER, hitInfo, true));
                }
                openfl.ui.Mouse.cursor = openfl.ui.MouseCursor.BUTTON;
            }
        }

        if (_hoveredPivot != null && hitInfo != null) {
            _lastHitInfo = hitInfo;
            _hoveredPivot.dispatchEvent(new flare.events.MouseEvent3D(flare.events.MouseEvent3D.MOUSE_MOVE, hitInfo, true));
        }
    }

    private function onStageMouseDown(e:openfl.events.MouseEvent):Void {
        var ray = getScreenRay(e.stageX, e.stageY);
        var hitPivot:Pivot3D = null;
        var hitInfo:flare.collisions.CollisionInfo = null;
        if (ray != null) {
            var best = {pivot: null, info: null};
            raycastRecursive(this, ray.origin, ray.dir, best);
            hitPivot = best.pivot;
            hitInfo = best.info;
        }
        if (hitPivot != null) {
            var evt = new flare.events.MouseEvent3D(flare.events.MouseEvent3D.MOUSE_DOWN, hitInfo, true);
            hitPivot.dispatchEvent(evt);
        }
    }

    private function onStageMouseUp(e:openfl.events.MouseEvent):Void {
        if (_hoveredPivot != null) {
            var evt = new flare.events.MouseEvent3D(flare.events.MouseEvent3D.MOUSE_UP, _lastHitInfo, true);
            _hoveredPivot.dispatchEvent(evt);
        }
    }

    private function onStageMouseClick(e:openfl.events.MouseEvent):Void {
        if (_hoveredPivot != null) {
            var evt = new flare.events.MouseEvent3D(flare.events.MouseEvent3D.CLICK, _lastHitInfo, true);
            _hoveredPivot.dispatchEvent(evt);
        }
    }
}