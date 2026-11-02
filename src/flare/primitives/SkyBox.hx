package flare.primitives;

import openfl.Vector;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import flare.basic.Scene3D;
import flare.core.Camera3D;
import flare.core.Mesh3D;
import flare.core.Surface3D;
import flare.core.Texture3D;
import flare.materials.Shader3D;
import flare.materials.filters.TextureMapFilter;

/**
 * SkyBox generates an enclosing background sky mesh that tracks the camera.
 * Disassembled and reconstructed directly from Flare3D 2.7.1 Flash bytecode:
 * - 6 faces: 0: Front (+Z), 1: Right (+X), 2: Back (-Z), 3: Left (-X), 4: Top (+Y), 5: Bottom (-Y)
 * - Horizontal cross 4x3 slicing:
 *   Face 0 (Front):  col 1, row 1
 *   Face 1 (Right):  col 2, row 1
 *   Face 2 (Back):   col 3, row 1
 *   Face 3 (Left):   col 0, row 1
 *   Face 4 (Top):    col 1, row 0
 *   Face 5 (Bottom): col 1, row 2
 * - Supports HORIZONTAL_CROSS, VERTICAL_CROSS, FOLDER_JPG/PNG, BITMAP_DATA_ARRAY
 */
class SkyBox extends Mesh3D {
    public static inline var HORIZONTAL_CROSS:Int = 0;
    public static inline var FOLDER_JPG:Int = 1;
    public static inline var BITMAP_DATA_ARRAY:Int = 2;
    public static inline var FOLDER_PNG:Int = 3;
    public static inline var VERTICAL_CROSS:Int = 4;

    public var scaleRatio:Float = 0.5;
    private var _textures:Array<Texture3D> = [];

    public function new(request:Dynamic = null, format:Dynamic = null, sceneContext:Scene3D = null, size:Float = 2000) {
        super("skybox");

        var hs = size * 0.5;

        // Determine format
        var fmt:Int = HORIZONTAL_CROSS;
        if (format != null) {
            if (Std.isOfType(format, Int)) {
                fmt = cast format;
            } else if (Std.isOfType(format, String)) {
                var sFmt:String = cast format;
                if (sFmt.indexOf("folder") != -1 && sFmt.indexOf("png") != -1) fmt = FOLDER_PNG;
                else if (sFmt.indexOf("folder") != -1) fmt = FOLDER_JPG;
                else if (sFmt.indexOf("bitmap") != -1 || sFmt.indexOf("array") != -1) fmt = BITMAP_DATA_ARRAY;
                else if (sFmt.indexOf("vertical") != -1) fmt = VERTICAL_CROSS;
                else fmt = HORIZONTAL_CROSS;
            }
        }

        var mats:Array<Shader3D> = [];

        // Build 6 faces: 0: Front, 1: Right, 2: Back, 3: Left, 4: Top, 5: Bottom
        if (Std.isOfType(request, Array)) {
            var arr:Array<Dynamic> = cast request;
            for (i in 0...6) {
                var item:Dynamic = (i < arr.length) ? arr[i] : null;
                var tex:Texture3D = null;
                if (Std.isOfType(item, Texture3D)) {
                    tex = cast item;
                } else if (Std.isOfType(item, BitmapData)) {
                    tex = new Texture3D(cast(item, BitmapData));
                } else if (Std.isOfType(item, String)) {
                    tex = new Texture3D(cast(item, String));
                }
                if (tex != null) {
                    tex.mipMode = Texture3D.MIP_NONE;
                    tex.wrapMode = Texture3D.WRAP_CLAMP;
                }
                _textures.push(tex);
                mats.push(createFaceMaterial(i, tex));
            }
            createBoxGeometry(hs, mats);
        } else if (Std.isOfType(request, String) && (fmt == FOLDER_JPG || fmt == FOLDER_PNG || (cast(request, String).indexOf(".") == -1 && cast(request, String).indexOf("folder") != -1))) {
            var str:String = cast request;
            var ext = (fmt == FOLDER_PNG) ? ".png" : ".jpg";
            var basePath = StringTools.replace(str, "\\", "/");
            if (StringTools.endsWith(basePath, "/")) basePath = basePath.substr(0, basePath.length - 1);
            var faces = ["front", "right", "back", "left", "top", "bottom"];
            for (i in 0...6) {
                var fPath = basePath + "/" + faces[i] + ext;
                var tex = new Texture3D(fPath);
                tex.mipMode = Texture3D.MIP_NONE;
                tex.wrapMode = Texture3D.WRAP_CLAMP;
                _textures.push(tex);
                mats.push(createFaceMaterial(i, tex));
            }
            createBoxGeometry(hs, mats);
        } else {
            // Cross image (HORIZONTAL_CROSS or VERTICAL_CROSS)
            var srcBmp:BitmapData = loadSourceBitmap(request);
            if (srcBmp != null) {
                var w:Int = 0;
                var h:Int = 0;
                var rects:Array<Rectangle> = [];

                if (fmt == VERTICAL_CROSS) {
                    w = Std.int(srcBmp.width / 3);
                    h = Std.int(srcBmp.height / 4);
                    rects = [
                        new Rectangle(w * 1, h * 1, w, h), // 0: Front
                        new Rectangle(w * 2, h * 1, w, h), // 1: Right
                        new Rectangle(w * 1, h * 3, w, h), // 2: Back
                        new Rectangle(w * 0, h * 1, w, h), // 3: Left
                        new Rectangle(w * 1, h * 0, w, h), // 4: Top
                        new Rectangle(w * 1, h * 2, w, h)  // 5: Bottom
                    ];
                } else {
                    // HORIZONTAL_CROSS (4x3)
                    w = Std.int(srcBmp.width / 4);
                    h = Std.int(srcBmp.height / 3);
                    rects = [
                        new Rectangle(w * 1, h * 1, w, h), // 0: Front
                        new Rectangle(w * 2, h * 1, w, h), // 1: Right
                        new Rectangle(w * 3, h * 1, w, h), // 2: Back
                        new Rectangle(w * 0, h * 1, w, h), // 3: Left
                        new Rectangle(w * 1, h * 0, w, h), // 4: Top
                        new Rectangle(w * 1, h * 2, w, h)  // 5: Bottom
                    ];
                }

                var pt = new Point(0, 0);
                for (i in 0...6) {
                    var faceBmd = new BitmapData(w, h, true, 0x00000000);
                    faceBmd.copyPixels(srcBmp, rects[i], pt);
                    var tex = new Texture3D(faceBmd);
                    tex.mipMode = Texture3D.MIP_NONE;
                    tex.wrapMode = Texture3D.WRAP_CLAMP;
                    _textures.push(tex);
                    mats.push(createFaceMaterial(i, tex));
                }
                createBoxGeometry(hs, mats);
            } else {
                // Fallback blank box
                for (i in 0...6) {
                    var tex = new Texture3D(new BitmapData(16, 16, false, 0x202020));
                    _textures.push(tex);
                    mats.push(createFaceMaterial(i, tex));
                }
                createBoxGeometry(hs, mats);
            }
        }

        if (sceneContext != null) {
            sceneContext.notifyLoadComplete();
        }
    }

    private function createFaceMaterial(idx:Int, tex:Texture3D):Shader3D {
        var mat = new Shader3D("skybox_mat_" + idx, [new TextureMapFilter(tex, false)], false);
        mat.enableLights = false;
        mat.depthWrite = false;
        mat.cullFace = openfl.display3D.Context3DTriangleFace.NONE;
        return mat;
    }

    private function loadSourceBitmap(request:Dynamic):BitmapData {
        if (request == null) return null;
        if (Std.isOfType(request, BitmapData)) return cast(request, BitmapData);
        if (Std.isOfType(request, Texture3D)) {
            var t:Texture3D = cast request;
            if (t.bitmapData != null) return t.bitmapData;
            if (t.url != null && t.url != "") return loadSourceBitmap(t.url);
        }
        if (Std.isOfType(request, String)) {
            var str:String = cast request;
            try {
                if (openfl.utils.Assets.exists(str)) {
                    return openfl.utils.Assets.getBitmapData(str);
                }
            } catch (e:Dynamic) {}
            #if sys
            var progDir = "";
            try {
                var prog = Sys.programPath();
                if (prog != null && prog != "") progDir = haxe.io.Path.directory(prog);
            } catch (e:Dynamic) {}

            var base = haxe.io.Path.withoutDirectory(str);
            var searchPaths = [
                str,
                "assets/" + str,
                "textures/" + base,
                "assets/textures/" + base,
                "../assets/" + str,
                "../assets/textures/" + base
            ];
            if (progDir != "") {
                searchPaths.push(haxe.io.Path.join([progDir, str]));
                searchPaths.push(haxe.io.Path.join([progDir, "assets", str]));
                searchPaths.push(haxe.io.Path.join([progDir, "textures", base]));
                searchPaths.push(haxe.io.Path.join([progDir, "assets", "textures", base]));
            }
            for (p in searchPaths) {
                if (sys.FileSystem.exists(p)) {
                    try {
                        var img = lime.graphics.Image.fromFile(p);
                        if (img != null) {
                            trace("[SkyBox] Loaded " + p + " (" + img.width + "x" + img.height + ")");
                            return BitmapData.fromImage(img);
                        }
                    } catch (e:Dynamic) {
                        trace("[SkyBox] Error loading " + p + ": " + e);
                    }
                }
            }
            trace("[SkyBox] FAILED to find image for " + str);
            #end
        }
        return null;
    }

    private function createBoxGeometry(s:Float, mats:Array<Shader3D>):Void {
        trace("[SkyBox] createBoxGeometry called with hs=" + s + ", mats.length=" + mats.length);
        // Flare3D original 6-face geometry:
        // Face 0: Front (+Z)
        addFaceSurface(mats[0], -s,  s,  s,   s,  s,  s,  -s, -s,  s,   s, -s,  s);
        // Face 1: Right (+X)
        addFaceSurface(mats[1],  s,  s,  s,   s,  s, -s,   s, -s,  s,   s, -s, -s);
        // Face 2: Back (-Z)
        addFaceSurface(mats[2],  s,  s, -s,  -s,  s, -s,   s, -s, -s,  -s, -s, -s);
        // Face 3: Left (-X)
        addFaceSurface(mats[3], -s,  s, -s,  -s,  s,  s,  -s, -s, -s,  -s, -s,  s);
        // Face 4: Top (+Y)
        addFaceSurface(mats[4], -s,  s, -s,   s,  s, -s,  -s,  s,  s,   s,  s,  s);
        // Face 5: Bottom (-Y)
        addFaceSurface(mats[5], -s, -s,  s,   s, -s,  s,  -s, -s, -s,   s, -s, -s);
    }

    private function addFaceSurface(mat:Shader3D,
        x0:Float, y0:Float, z0:Float,
        x1:Float, y1:Float, z1:Float,
        x2:Float, y2:Float, z2:Float,
        x3:Float, y3:Float, z3:Float):Void 
    {
        var surface = new Surface3D("skybox_surf");
        var vData = surface.vertexData;
        var iData = surface.indexData;

        // Flare3D vertex format:
        // Vert 0: (x0, y0, z0, u=0, v=0, nx=0, ny=0, nz=0)
        // Vert 1: (x1, y1, z1, u=1, v=0, nx=0, ny=0, nz=0)
        // Vert 2: (x2, y2, z2, u=0, v=1, nx=0, ny=0, nz=0)
        // Vert 3: (x3, y3, z3, u=1, v=1, nx=0, ny=0, nz=0)
        var u0:Float = 0.5 / 128.0;
        var u1:Float = 1.0 - u0;
        var v0:Float = 0.5 / 128.0;
        var v1:Float = 1.0 - v0;

        vData.push(x0); vData.push(y0); vData.push(z0); vData.push(u0); vData.push(v0); vData.push(0); vData.push(0); vData.push(0);
        vData.push(x1); vData.push(y1); vData.push(z1); vData.push(u1); vData.push(v0); vData.push(0); vData.push(0); vData.push(0);
        vData.push(x2); vData.push(y2); vData.push(z2); vData.push(u0); vData.push(v1); vData.push(0); vData.push(0); vData.push(0);
        vData.push(x3); vData.push(y3); vData.push(z3); vData.push(u1); vData.push(v1); vData.push(0); vData.push(0); vData.push(0);

        // Triangles: (0, 1, 2) and (1, 3, 2)
        iData.push(0); iData.push(1); iData.push(2);
        iData.push(1); iData.push(3); iData.push(2);

        addSurface(surface, mat);
    }

    override public function render(camera:Camera3D = null, clearDepth:Bool = false, target:Dynamic = null):Void {
        if (camera != null) {
            var cPos = camera.getPosition(false);
            setPosition(cPos.x, cPos.y, cPos.z);
            updateTransforms(true);
        }
        super.render(camera);
    }
}
