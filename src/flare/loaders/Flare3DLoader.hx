package flare.loaders;

import openfl.events.Event;
import openfl.net.URLRequest;
import openfl.utils.ByteArray;
import flare.core.Pivot3D;
import flare.basic.Scene3D;
import flare.system.ILibraryExternalItem;

/**
 * Flare3DLoader is the primary loader interface that detects and loads Flare3D assets (.zf3d, .f3d, .dae).
 */
class Flare3DLoader extends Pivot3D implements ILibraryExternalItem {
    public static inline var COMPLETE_EVENT:String = "complete";
    public static inline var PROGRESS_EVENT:String = "progress";
    public static inline var ERROR_EVENT:String = "error";

    public var url:String;
    public var request:URLRequest;
    public var loaded:Bool = false;
    public var bytesLoaded:Float = 0;
    public var bytesTotal:Float = 0;
    public var source:Dynamic;
    public var activeCamera:flare.core.Camera3D;

    private var _delegate:Pivot3D;

    public function new(request:Dynamic = null, parent:Pivot3D = null, sceneContext:Scene3D = null) {
        super("loader");
        this.source = request;
        if (sceneContext != null) {
            this.scene = sceneContext;
        }
        if (parent != null) {
            parent.addChild(this);
        }

        if (Std.isOfType(request, String)) {
            this.url = cast(request, String);
            this.request = new URLRequest(this.url);
        } else if (Std.isOfType(request, URLRequest)) {
            this.request = cast(request, URLRequest);
            this.url = this.request.url;
        }

        if (request != null) {
            load();
        }
    }

    public function load():Void {
        if (url == null || url == "") return;

        var lower = url.toLowerCase();
        if (StringTools.endsWith(lower, ".dae")) {
            var cl = new ColladaLoader(url, this);
            cl.addEventListener(Event.COMPLETE, onDelegateComplete);
            _delegate = cl;
        } else {
            var zl = new ZF3DLoader();
            zl.url = url;
            if (this.scene != null) zl.scene = this.scene;
            var onLoaded = function() {
                while (zl.children.length > 0) {
                    this.addChild(zl.children[0]);
                }
                this.totalFrames = zl.totalFrames;
                this.frames = zl.frames;
                this.frameSpeed = zl.frameSpeed;
                this.animationSpeed = zl.animationSpeed;
                if (zl.activeCamera != null) {
                    this.activeCamera = zl.activeCamera;
                    if (this.scene != null && (this.scene.camera == null || this.scene.camera.name == "defaultCamera" || this.scene.camera.name == "Default_Scene_Camera")) {
                        this.scene.camera = this.activeCamera;
                    }
                }
                for (l in zl.labels) {
                    this.labels.push(l);
                }
                // Re-bind any SkinModifier root to this Flare3DLoader instance
                this.forEach(function(p:Pivot3D) {
                    if (Std.isOfType(p, flare.core.Mesh3D)) {
                        var m:flare.core.Mesh3D = cast p;
                        if (m.modifier != null && Std.isOfType(m.modifier, flare.modifiers.SkinModifier)) {
                            var sm:flare.modifiers.SkinModifier = cast m.modifier;
                            if (sm.root == zl || sm.root == null) {
                                sm.root = this;
                            }
                        }
                    }
                });
                if (this.totalFrames > 0 || (this.frames != null && this.frames.length > 0) || zl.isPlaying) {
                    this.play(true);
                }
                onDelegateComplete(null);
            };
            zl.addEventListener(Event.COMPLETE, function(e) {
                onLoaded();
            });
            _delegate = zl;
            zl.load();
            if (zl.loaded && this.children.length == 0) {
                onLoaded();
            }
        }
    }

    public function loadBytes(bytes:ByteArray):Void {
        var zl = new ZF3DLoader();
        if (this.scene != null) zl.scene = this.scene;
        var onLoaded = function() {
            while (zl.children.length > 0) {
                this.addChild(zl.children[0]);
            }
            this.totalFrames = zl.totalFrames;
            this.frames = zl.frames;
            this.frameSpeed = zl.frameSpeed;
            this.animationSpeed = zl.animationSpeed;
            for (l in zl.labels) {
                this.labels.push(l);
            }
            // Re-bind any SkinModifier root to this Flare3DLoader instance
            this.forEach(function(p:Pivot3D) {
                if (Std.isOfType(p, flare.core.Mesh3D)) {
                    var m:flare.core.Mesh3D = cast p;
                    if (m.modifier != null && Std.isOfType(m.modifier, flare.modifiers.SkinModifier)) {
                        var sm:flare.modifiers.SkinModifier = cast m.modifier;
                        if (sm.root == zl || sm.root == null) {
                            sm.root = this;
                        }
                    }
                }
            });
            if (this.totalFrames > 0 || (this.frames != null && this.frames.length > 0) || zl.isPlaying) {
                this.play(true);
            }
            onDelegateComplete(null);
        };
        zl.addEventListener(Event.COMPLETE, function(e) {
            onLoaded();
        });
        _delegate = zl;
        zl.parseBinary(bytes);
        if (zl.loaded && this.children.length == 0) {
            onLoaded();
        }
    }

    private function onDelegateComplete(e:Event):Void {
        loaded = true;
        dispatchEvent(new Event(Event.COMPLETE));
    }

    override public function setScene(sc:Scene3D):Void {
        super.setScene(sc);
        if (_delegate != null) {
            _delegate.setScene(sc);
        }
    }

    public function close():Void {}

    override public function dispose():Void {
        close();
        if (parent != null) {
            parent.removeChild(this);
        }
        super.dispose();
    }
}
