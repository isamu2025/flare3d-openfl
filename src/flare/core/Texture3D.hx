package flare.core;

import openfl.display.BitmapData;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.textures.Texture;
import openfl.display3D.textures.TextureBase;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.geom.Matrix;
import flare.system.Device3D;

/**
 * Texture3D encapsulates Stage3D textures with automatic BitmapData uploading, RTT and mipmapping.
 */
class Texture3D {
    public static inline var FILTER_LINEAR:String = "linear";
    public static inline var FILTER_NEAREST:String = "nearest";
    public static inline var FORMAT_RGBA:String = "rgba";
    public static inline var FORMAT_COMPRESSED:String = "compressed";
    public static inline var FORMAT_COMPRESSED_ALPHA:String = "compressedAlpha";
    public static inline var FORMAT_BGR_PACKED:String = "bgrPacked565";
    public static inline var FORMAT_BGRA_PACKED:String = "bgraPacked4444";
    public static inline var MIP_LINEAR:String = "mipLinear";
    public static inline var MIP_NEAREST:String = "mipNearest";
    public static inline var MIP_NONE:String = "mipNone";
    public static inline var TYPE_2D:String = "2d";
    public static inline var TYPE_CUBE:String = "cube";
    public static inline var WRAP_CLAMP:String = "clamp";
    public static inline var WRAP_REPEAT:String = "repeat";

    public static var defaultTexture(get, null):Texture3D;
    private static var _defaultTexture:Texture3D;
    private static function get_defaultTexture():Texture3D {
        if (_defaultTexture == null) {
            var bmd = new BitmapData(256, 256, false, 0xffffff);
            var tileSize = 32;
            for (x in 0...256) {
                for (y in 0...256) {
                    var isDark = (Std.int(x / tileSize) + Std.int(y / tileSize)) % 2 == 1;
                    var isBorder = (x % tileSize == 0 || y % tileSize == 0);
                    var col = isBorder ? 0x404040 : (isDark ? 0xb0b0b0 : 0xffffff);
                    bmd.setPixel(x, y, col);
                }
            }
            _defaultTexture = new Texture3D(bmd);
        }
        return _defaultTexture;
    }

    public var name:String;
    public var bitmapData:BitmapData;
    public var texture:TextureBase;
    public var mipmaps:Bool;
    public var width:Int = 256;
    public var height:Int = 256;
    public var format:Context3DTextureFormat;
    public var wrapMode:String = WRAP_REPEAT;
    public var filterMode:String = FILTER_LINEAR;
    public var mipMode:String = MIP_NONE;
    public var optimizeForRenderToTexture:Bool = false;
    public var scene:Dynamic;
    public var url:String;
    public var loaded:Bool = true;

    private var _uploaded:Bool = false;
    private var _texWidth:Int = -1;
    private var _texHeight:Int = -1;

    public var type:String = TYPE_2D;

    public function new(request:Dynamic = null, mipmaps:Bool = false, format:Dynamic = null, optimizeForRenderToTexture:Dynamic = false, type:String = '2d') {
        if (Std.isOfType(optimizeForRenderToTexture, Bool)) {
            this.optimizeForRenderToTexture = cast optimizeForRenderToTexture;
        } else if (Std.isOfType(optimizeForRenderToTexture, String)) {
            this.type = cast optimizeForRenderToTexture;
            this.optimizeForRenderToTexture = false;
        }
        if (type != null && type != '2d') this.type = type;
        this.mipmaps = mipmaps;
        this.format = Context3DTextureFormat.BGRA;

        if (request != null) {
            if (Std.isOfType(request, BitmapData)) {
                this.bitmapData = cast(request, BitmapData);
                this.width = this.bitmapData.width;
                this.height = this.bitmapData.height;
            } else if (Std.isOfType(request, Point)) {
                var pt:Point = cast(request, Point);
                this.width = Std.int(pt.x);
                this.height = Std.int(pt.y);
                this.optimizeForRenderToTexture = true;
            } else if (Std.isOfType(request, Rectangle)) {
                var rect:Rectangle = cast(request, Rectangle);
                this.width = Std.int(rect.width);
                this.height = Std.int(rect.height);
                this.optimizeForRenderToTexture = true;
            } else if (Std.isOfType(request, String)) {
                this.url = cast(request, String);
                this.name = this.url;
                loadFromUrl(this.url);
            }
        }
    }

    public function loadFromUrl(url:String):Void {
        this.loaded = false;
        try {
            if (openfl.utils.Assets.exists(url)) {
                var bmd = openfl.utils.Assets.getBitmapData(url);
                if (bmd != null) {
                    this.bitmapData = bmd;
                    this.width = bmd.width;
                    this.height = bmd.height;
                    this.loaded = true;
                    this._uploaded = false;
                    return;
                }
            }
        } catch (e:Dynamic) {}

        #if sys
        try {
            var progDir = "";
            try {
                var prog = Sys.programPath();
                if (prog != null && prog != "") progDir = haxe.io.Path.directory(prog);
            } catch (e:Dynamic) {}

            var base = haxe.io.Path.withoutDirectory(url);
            var searchPaths = [
                url,
                "assets/" + url,
                "textures/" + base,
                "assets/textures/" + base,
                "../assets/" + url,
                "../assets/textures/" + base
            ];
            if (progDir != "") {
                searchPaths.push(haxe.io.Path.join([progDir, url]));
                searchPaths.push(haxe.io.Path.join([progDir, "assets", url]));
                searchPaths.push(haxe.io.Path.join([progDir, "textures", base]));
                searchPaths.push(haxe.io.Path.join([progDir, "assets", "textures", base]));
            }
            for (p in searchPaths) {
                if (sys.FileSystem.exists(p)) {
                    var img = lime.graphics.Image.fromFile(p);
                    if (img != null) {
                        this.bitmapData = BitmapData.fromImage(img);
                        this.width = this.bitmapData.width;
                        this.height = this.bitmapData.height;
                        this.loaded = true;
                        this._uploaded = false;
                        if (Device3D.context != null) {
                            this.upload(Device3D.context);
                        }
                        return;
                    }
                }
            }
        } catch (eSys:Dynamic) {}
        #end

        try {
            BitmapData.loadFromFile(url).onComplete(function(bmd:BitmapData) {
                if (bmd != null) {
                    this.bitmapData = bmd;
                    this.width = bmd.width;
                    this.height = bmd.height;
                    this.loaded = true;
                    this._uploaded = false;
                    if (Device3D.context != null) {
                        this.upload(Device3D.context);
                    }
                }
            }).onError(function(msg:Dynamic) {
                if (!StringTools.startsWith(url, "assets/")) {
                    var fallbackUrl = "assets/" + url;
                    try {
                        if (openfl.utils.Assets.exists(fallbackUrl)) {
                            var bmd = openfl.utils.Assets.getBitmapData(fallbackUrl);
                            if (bmd != null) {
                                this.bitmapData = bmd;
                                this.width = bmd.width;
                                this.height = bmd.height;
                                this.loaded = true;
                                this._uploaded = false;
                                return;
                            }
                        }
                    } catch (e2:Dynamic) {}
                    try {
                        BitmapData.loadFromFile(fallbackUrl).onComplete(function(bmd:BitmapData) {
                            if (bmd != null) {
                                this.bitmapData = bmd;
                                this.width = bmd.width;
                                this.height = bmd.height;
                                this.loaded = true;
                                this._uploaded = false;
                                if (Device3D.context != null) {
                                    this.upload(Device3D.context);
                                }
                            }
                        });
                    } catch (e3:Dynamic) {}
                }
            });
        } catch (e:Dynamic) {}
    }

    private static inline function isPowerOfTwo(val:Int):Bool {
        return val > 0 && (val & (val - 1)) == 0;
    }

    private static function toPowerOfTwo(val:Int):Int {
        if (isPowerOfTwo(val)) return val;
        var p = 1;
        while (p < val) p <<= 1;
        var prev = p >> 1;
        // e.g. for 550, prev is 512, p is 1024. Distance to 512 is 38. Distance to 1024 is 474.
        if (prev >= 64 && (val - prev) * 3 < (p - val)) {
            return prev;
        }
        return p;
    }

    public function uploadTexture():Void {
        if (texture != null && bitmapData != null) {
            try {
                cast(texture, openfl.display3D.textures.Texture).uploadFromBitmapData(bitmapData, 0);
            } catch (e:Dynamic) {}
        }
    }

    public function upload(contextArg:Dynamic = null):Void {
        var context:Context3D = null;
        if (contextArg != null) {
            if (Std.isOfType(contextArg, Context3D)) {
                context = cast(contextArg, Context3D);
            } else if (Reflect.hasField(contextArg, "context")) {
                context = Reflect.field(contextArg, "context");
            }
        }
        if (context == null) context = Device3D.context;
        if (context == null) return;

        if (type == TYPE_CUBE) {
            if (_uploaded && texture != null) return;
            if (bitmapData == null) return;

            var faceW = Std.int(bitmapData.width / 4);
            var faceH = Std.int(bitmapData.height / 3);
            var tileSize = toPowerOfTwo(faceW < faceH ? faceW : faceH);

            if (texture == null) {
                texture = context.createCubeTexture(tileSize, Context3DTextureFormat.BGRA, optimizeForRenderToTexture);
            }

            var faces = flare.utils.Texture3DUtils.extractCubeMap(bitmapData);
            for (side in 0...faces.length) {
                var f = faces[side];
                if (f.width != tileSize || f.height != tileSize) {
                    var scaled = new BitmapData(tileSize, tileSize, f.transparent, 0);
                    var mat = new Matrix();
                    mat.scale(tileSize / f.width, tileSize / f.height);
                    scaled.draw(f, mat, null, null, null, true);
                    cast(texture, openfl.display3D.textures.CubeTexture).uploadFromBitmapData(scaled, side, 0);
                    scaled.dispose();
                } else {
                    cast(texture, openfl.display3D.textures.CubeTexture).uploadFromBitmapData(f, side, 0);
                }
                f.dispose();
            }
            _uploaded = true;
            return;
        }

        // Ensure texture dimensions are power-of-two (POT) for Stage3D / OpenGL repeat sampling
        if (bitmapData != null) {
            var potW = toPowerOfTwo(bitmapData.width);
            var potH = toPowerOfTwo(bitmapData.height);
            if (potW != bitmapData.width || potH != bitmapData.height) {
                var scaledBmd = new BitmapData(potW, potH, bitmapData.transparent, 0);
                var mat = new Matrix();
                mat.scale(potW / bitmapData.width, potH / bitmapData.height);
                scaledBmd.draw(bitmapData, mat, null, null, null, true);
                this.bitmapData = scaledBmd;
                this.width = potW;
                this.height = potH;
            }
        }

        // If texture exists but dimensions have changed, recreate it
        if (texture != null && (_texWidth != width || _texHeight != height)) {
            texture.dispose();
            texture = null;
            _uploaded = false;
        }

        if (_uploaded && texture != null) return;

        if (width <= 0 || height <= 0) return;

        if (texture == null) {
            texture = context.createTexture(width, height, format, optimizeForRenderToTexture);
            _texWidth = width;
            _texHeight = height;
        }

        if (bitmapData != null) {
            if (!mipmaps) {
                cast(texture, Texture).uploadFromBitmapData(bitmapData, 0);
            } else {
                uploadMipmaps(context);
            }
            _uploaded = true;
        } else {
            _uploaded = false;
        }
    }

    private function uploadMipmaps(context:Context3D):Void {
        var currentW = width;
        var currentH = height;
        var level = 0;
        var currentBmp = bitmapData;
        
        while (currentW > 0 || currentH > 0) {
            var w = currentW > 0 ? currentW : 1;
            var h = currentH > 0 ? currentH : 1;

            if (level == 0) {
                cast(texture, Texture).uploadFromBitmapData(currentBmp, 0);
            } else {
                var mip = new BitmapData(w, h, true, 0);
                var scale = new Matrix();
                scale.scale(w / bitmapData.width, h / bitmapData.height);
                mip.draw(bitmapData, scale, null, null, null, true);
                cast(texture, Texture).uploadFromBitmapData(mip, level);
                mip.dispose();
            }

            if (currentW == 1 && currentH == 1) break;
            currentW = currentW >> 1;
            currentH = currentH >> 1;
            level++;
        }
    }

    public function dispose():Void {
        if (texture != null) {
            texture.dispose();
            texture = null;
        }
        if (bitmapData != null) {
            bitmapData.dispose();
            bitmapData = null;
        }
        _uploaded = false;
    }
}
