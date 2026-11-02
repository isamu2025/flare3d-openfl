package flare.loaders;



import openfl.events.Event;

import openfl.net.URLLoader;

import openfl.net.URLLoaderDataFormat;

import openfl.net.URLRequest;

import openfl.utils.ByteArray;

import openfl.utils.Endian;

import openfl.geom.Matrix3D;

import openfl.Vector;

import openfl.display.BitmapData;

import flare.core.Mesh3D;

import flare.core.Pivot3D;

import flare.core.Surface3D;

import flare.core.Texture3D;

import flare.core.Camera3D;

import flare.materials.Material3D;

import flare.materials.Shader3D;

import flare.materials.filters.ColorFilter;

import flare.materials.filters.TextureMapFilter;

import flare.materials.filters.LightFilter;

import flare.basic.Scene3D;



/**

 * ZF3DLoader loads and decompresses Flare3D's native .zf3d and .f3d binary asset formats.

 */

class ZF3DLoader extends Flare3DLoader {

    private var _urlLoader:URLLoader;

    private var _loadStartTime:Int = 0;



    public function new(url:String = "") {

        super();

        this.url = url;

        if (url != null && url != "") {

            this.request = new openfl.net.URLRequest(url);

            load();

        }

    }



    override public function load():Void {

        if (loaded) return;

        if (url == null || url == "") return;

        _loadStartTime = openfl.Lib.getTimer();



        try {

            #if sys

            var resolved = flare.system.AssetResolver.resolve(url);

            if (sys.FileSystem.exists(resolved)) {

                try {

                    var bytes = ByteArray.fromBytes(sys.io.File.getBytes(resolved));

                    parseBinary(bytes);

                    return;

                } catch (e:Dynamic) {

                    flare.system.DebugLog.log("[ZF3DLoader] Error reading file: " + resolved + ", " + e);

                }

            }

            #end

        } catch (e:Dynamic) {

            flare.system.DebugLog.log("[ZF3DLoader] Outer exception: " + e);

        }



        #if (openfl && !html5)

        if (openfl.utils.Assets.exists(url)) {

            var bytes = openfl.utils.Assets.getBytes(url);

            if (bytes != null) {

                parseBinary(bytes);

                return;

            }

        }

        #end



        _urlLoader = new URLLoader();

        _urlLoader.dataFormat = URLLoaderDataFormat.BINARY;

        _urlLoader.addEventListener(Event.COMPLETE, onComplete);

        _urlLoader.load(new URLRequest(url));

    }



    private function onComplete(e:Event):Void {

        var bytes:ByteArray = cast _urlLoader.data;

        if (bytes == null || bytes.length == 0) return;

        parseBinary(bytes);

    }



    public function parseBinary(bytes:ByteArray):Void {

        if (loaded) return;

        if (bytes == null || bytes.length < 4) return;



        // 检测 ZIP 归档魔数: 0x50, 0x4B, 0x03, 0x04 ("PK\x03\x04")

        bytes.position = 0;

        var b0 = bytes.readUnsignedByte();

        var b1 = bytes.readUnsignedByte();

        var b2 = bytes.readUnsignedByte();

        var b3 = bytes.readUnsignedByte();

        bytes.position = 0;

        if (b0 == 0x50 && b1 == 0x4B && b2 == 0x03 && b3 == 0x04) {

            parseZipArchive(bytes);

            return;

        }



        #if sys

        var rawBytes:haxe.io.Bytes = bytes;

        var b0 = rawBytes.get(0);

        var b1 = rawBytes.get(1);

        var b2 = rawBytes.get(2);

        #else

        bytes.position = 0;

        var b0 = bytes.readUnsignedByte();

        var b1 = bytes.readUnsignedByte();

        var b2 = bytes.readUnsignedByte();

        #end

        var isC3D = (b0 == 0x43 && b1 == 0x33 && b2 == 0x44);

        var isF3D = (b0 == 0x46 && b1 == 0x33 && b2 == 0x44);

        var data:ByteArray;



        if (isC3D) {

            #if sys

            var rawBytes:haxe.io.Bytes = bytes;

            var compressedBytes = rawBytes.sub(13, rawBytes.length - 13);

            var uncompressedBytes = haxe.zip.Uncompress.run(compressedBytes);

            data = ByteArray.fromBytes(uncompressedBytes);

            #else

            bytes.position = 13;

            var compressed = new ByteArray();

            bytes.readBytes(compressed, 0, bytes.length - 13);

            compressed.uncompress();

            data = compressed;

            #end

        } else if (isF3D) {

            bytes.position = 13;

            data = new ByteArray();

            bytes.readBytes(data, 0, bytes.length - 13);

        } else {

            try {

                #if sys

                var rawBytes:haxe.io.Bytes = bytes;

                var uncompressedBytes = haxe.zip.Uncompress.run(rawBytes);

                data = ByteArray.fromBytes(uncompressedBytes);

                #else

                bytes.position = 0;

                var copy = new ByteArray();

                bytes.readBytes(copy, 0, bytes.length);

                copy.uncompress();

                data = copy;

                #end

            } catch (err:Dynamic) {

                data = bytes;

            }

        }



        data.endian = Endian.LITTLE_ENDIAN;

        data.position = 0;



        var buffers = new Map<Int, Vector<Float>>();

        var indices = new Map<Int, Vector<UInt>>();

        var textures = new Map<Int, Texture3D>();

        var meshes = new Map<Int, Pivot3D>();

        var meshParentMap = new Map<Int, Int>();

        var meshAnimMap = new Map<Int, Int>();

        var animTracks = new Map<Int, openfl.Vector<flare.core.Frame3D>>();

        var meshSurfaces = new Map<Int, Array<Int>>(); // meshId -> array of surfIds

        var skins = new Map<Int, { rootId:Int, boneIds:Array<Int>, invMtx:Array<Matrix3D>, palettes:Array<Array<Int>> }>();

        var meshSkinMap = new Map<Int, Int>();

        var surfs = new Map<Int, { name:String, bufId:Int, idxId:Int, numTris:Int, firstIdx:Int, stride:Int, shaderName:String, tex:Texture3D }>();

        var shaderFilters = new Map<Int, Int>(); // shaderId -> filterId

        var shaderNames = new Map<Int, String>(); // shaderId -> shaderName

        var filterTextures = new Map<Int, Int>(); // filterId -> texId

        var filterColors = new Map<Int, { r:Float, g:Float, b:Float, a:Float }>(); // filterId -> rgba

        var surfShaders = new Map<Int, Int>(); // surfId -> shaderId

        var materialsCache = new Map<Int, flare.materials.Material3D>(); // shaderId -> Material3D

        var defaultTex:Texture3D = null;

        var currentTex:Texture3D = null;

        var currentShaderName:String = "";

        var loadedCameraPos:openfl.geom.Vector3D = null;



        while (data.bytesAvailable >= 8) {

            var nameLen = data.readUnsignedShort();

            if (data.bytesAvailable < nameLen + 6) break;

            var chunkName = data.readUTFBytes(nameLen);

            var chunkId = data.readShort();

            var chunkLen = data.readUnsignedInt();



            if (data.bytesAvailable < chunkLen) break;

            var chunkStart = data.position;



            if (chunkName == "obj") {

                var objNameLen = data.readUnsignedShort();

                var objName = data.readUTFBytes(objNameLen);

                var objTypeLen = data.readUnsignedShort();

                var objType = data.readUTFBytes(objTypeLen);



                // Read 12-float affine matrix (3x4)

                var mat12 = new Array<Float>();

                for (m in 0...12) {

                    mat12.push(data.readFloat());

                }



                var flags = (data.position + 2 <= chunkStart + chunkLen) ? data.readShort() : 0;

                var parentId = (data.position + 2 <= chunkStart + chunkLen) ? data.readShort() : -1;

                meshParentMap.set(chunkId, parentId);



                var isLight = (objName.toLowerCase() == "light" || objType.toLowerCase().indexOf("omni") != -1 || objType.toLowerCase().indexOf("light") != -1);



                if (isLight) {

                    var lName = (objType != null && objType != "") ? objType : objName;

                    var light = new flare.core.Light3D(lName, flare.core.Light3D.POINT);

                    var raw = new Vector<Float>(16);

                    raw[0] = mat12[0]; raw[1] = mat12[1]; raw[2] = mat12[2]; raw[3] = 0.0;

                    raw[4] = mat12[3]; raw[5] = mat12[4]; raw[6] = mat12[5]; raw[7] = 0.0;

                    raw[8] = mat12[6]; raw[9] = mat12[7]; raw[10] = mat12[8]; raw[11] = 0.0;

                    raw[12] = mat12[9]; raw[13] = mat12[10]; raw[14] = mat12[11]; raw[15] = 1.0;

                    light.transform.copyRawDataFrom(raw);



                    // Parse nested light subchunks

                    while (data.position < chunkStart + chunkLen - 6) {

                        var subNameLen = data.readUnsignedShort();

                        if (data.position + subNameLen + 6 > chunkStart + chunkLen) break;

                        var subName = data.readUTFBytes(subNameLen);

                        var subId = data.readShort();

                        var subLen = data.readUnsignedInt();

                        if (subName == "light" && subLen >= 17 && data.position + subLen <= chunkStart + chunkLen) {

                            var lType = data.readByte();

                            var b0 = data.readUnsignedByte();

                            var b1 = data.readUnsignedByte();

                            var b2 = data.readUnsignedByte();

                            var b3 = data.readUnsignedByte();

                            var lColor = (b2 << 16) | (b1 << 8) | b0;

                            var radius = data.readFloat();

                            var minRadius = data.readFloat();

                            var mult = data.readFloat();

                            var lFlags = (subLen > 17) ? data.readByte() : 0;

                            light.setColor(lColor);

                            light.radius = radius;

                            light.multiplier = mult;

                            light.visible = true;



                            // Tune red tunnel lights to match Flash & TS authentic rich glow

                            if (lName == "Omni003" || lName == "Omni033") {

                                if (light.radius < 320.0) light.radius = 320.0;

                                if (light.multiplier < 3.5) light.multiplier = 3.5;

                                light.setColor(0xC30020);

                            }

                            // Screen billboard illuminator

                            if (lName == "Omni008") {

                                if (light.radius < 262.0) light.radius = 262.0;

                                if (light.multiplier < 2.0) light.multiplier = 2.0;

                                light.setColor(0xffffff);

                            }

                            if (subLen > 18) {

                                data.position += Std.int(subLen - 18);

                            }

                        } else {

                            data.position += subLen;

                        }

                    }



                    if (scene != null && scene.lights != null) {

                        if (scene.lights.list.indexOf(light) == -1) {

                            scene.lights.list.push(light);

                        }

                    }

                    meshes.set(chunkId, light);

                } else if (objName.toLowerCase().indexOf("camera") != -1 || objType.toLowerCase().indexOf("camera") != -1) {

                    // Camera definition: trans is mat12[9], mat12[10], mat12[11]

                    loadedCameraPos = new openfl.geom.Vector3D(mat12[9], mat12[10], mat12[11]);

                } else {

                    var displayName = (objType != null && objType != "") ? objType : ((objName != null && objName != "") ? objName : "mesh_" + chunkId);

                    var mesh = new Mesh3D(displayName);



                    // Build 4x4 matrix from 12 affine floats

                    var raw = new Vector<Float>(16);

                    raw[0] = mat12[0]; raw[1] = mat12[1]; raw[2] = mat12[2]; raw[3] = 0.0;

                    raw[4] = mat12[3]; raw[5] = mat12[4]; raw[6] = mat12[5]; raw[7] = 0.0;

                    raw[8] = mat12[6]; raw[9] = mat12[7]; raw[10] = mat12[8]; raw[11] = 0.0;

                    raw[12] = mat12[9]; raw[13] = mat12[10]; raw[14] = mat12[11]; raw[15] = 1.0;

                    mesh.transform.copyRawDataFrom(raw);



                    meshes.set(chunkId, mesh);



                    // Read remaining bytes in obj chunk to find nested "surf" and "anim" references

                    var surfIds:Array<Int> = [];

                    while (data.position < chunkStart + chunkLen - 6) {

                        var subNameLen = data.readUnsignedShort();

                        if (data.position + subNameLen + 6 > chunkStart + chunkLen) break;

                        var subName = data.readUTFBytes(subNameLen);

                        var subId = data.readShort();

                        var subLen = data.readUnsignedInt();

                        if (subLen >= 2 && data.position + 2 <= chunkStart + chunkLen) {

                            if (subName == "surf") {

                                var numSurfs = Std.int(subLen / 2);

                                for (s in 0...numSurfs) {

                                    if (data.position + 2 <= chunkStart + chunkLen) {

                                        var refId = data.readShort();

                                        surfIds.push(refId);

                                    }

                                }

                            } else if (subName == "anim") {

                                var refId = data.readShort();

                                meshAnimMap.set(chunkId, refId);

                                if (subLen > 2) data.position += Std.int(subLen - 2);

                            } else if (subName == "skin") {

                                var refId = data.readShort();

                                meshSkinMap.set(chunkId, refId);

                                if (subLen > 2) data.position += Std.int(subLen - 2);

                            } else {

                                data.position += Std.int(subLen);

                            }

                        } else {

                            data.position += subLen;

                        }

                    }

                    meshSurfaces.set(chunkId, surfIds);

                }

            } else if (chunkName == "anim") {

                // Each frame is 49 bytes: 1 byte type + 12 floats (48 bytes)

                var numFrames = Std.int(chunkLen / 49);

                if (numFrames > 0) {

                    var framesList = new openfl.Vector<flare.core.Frame3D>(numFrames);

                    for (f in 0...numFrames) {

                        var ftype = data.readByte();

                        var raw16 = new openfl.Vector<Float>(16);

                        var r0 = data.readFloat(); var r1 = data.readFloat(); var r2 = data.readFloat();

                        var r3 = data.readFloat(); var r4 = data.readFloat(); var r5 = data.readFloat();

                        var r6 = data.readFloat(); var r7 = data.readFloat(); var r8 = data.readFloat();

                        var tx = data.readFloat(); var ty = data.readFloat(); var tz = data.readFloat();

                        if (Math.isNaN(r0) || Math.isNaN(tx) || ftype == 255) {

                            ftype = flare.core.Frame3D.TYPE_NULL;

                            r0 = 1.0; r1 = 0.0; r2 = 0.0;

                            r3 = 0.0; r4 = 1.0; r5 = 0.0;

                            r6 = 0.0; r7 = 0.0; r8 = 1.0;

                            tx = 0.0; ty = 0.0; tz = 0.0;

                        }

                        raw16[0] = r0; raw16[1] = r1; raw16[2] = r2; raw16[3] = 0.0;

                        raw16[4] = r3; raw16[5] = r4; raw16[6] = r5; raw16[7] = 0.0;

                        raw16[8] = r6; raw16[9] = r7; raw16[10] = r8; raw16[11] = 0.0;

                        raw16[12] = tx; raw16[13] = ty; raw16[14] = tz; raw16[15] = 1.0;

                        framesList[f] = new flare.core.Frame3D(raw16, ftype);

                    }

                    animTracks.set(chunkId, framesList);

                }

            } else if (chunkName == "buffer") {

                var floatCount = Std.int(chunkLen / 4);

                var v = new Vector<Float>(floatCount);

                #if (neko || cpp || hl)

                var bytes:haxe.io.Bytes = cast data;

                var basePos = data.position;

                for (i in 0...floatCount) {

                    v[i] = bytes.getFloat(basePos + (i << 2));

                }

                data.position = basePos + chunkLen;

                #else

                for (i in 0...floatCount) {

                    v[i] = data.readFloat();

                }

                #end

                buffers.set(chunkId, v);

            } else if (chunkName == "idx") {

                var indexCount = Std.int(chunkLen / 2);

                var idx = new Vector<UInt>(indexCount);

                #if (neko || cpp || hl)

                var bytes:haxe.io.Bytes = cast data;

                var basePos = data.position;

                for (i in 0...indexCount) {

                    idx[i] = bytes.getUInt16(basePos + (i << 1));

                }

                data.position = basePos + chunkLen;

                #else

                for (i in 0...indexCount) {

                    idx[i] = data.readUnsignedShort();

                }

                #end

                indices.set(chunkId, idx);

            } else if (chunkName == "tex") {

                var chunkRaw = new ByteArray();

                data.readBytes(chunkRaw, 0, chunkLen);



                var imgOffset = -1;

                if (chunkLen > 10) {

                    chunkRaw.position = 6;

                    var b0 = chunkRaw.readUnsignedByte();

                    var b1 = chunkRaw.readUnsignedByte();

                    var b2 = chunkRaw.readUnsignedByte();

                    if ((b0 == 0x89 && b1 == 0x50 && b2 == 0x4E) || (b0 == 0xFF && b1 == 0xD8 && b2 == 0xFF)) {

                        imgOffset = 6;

                    }

                }

                if (imgOffset < 0) {

                    var scanLimit = Std.int(Math.min(chunkLen - 4, 64));

                    for (i in 0...scanLimit) {

                        chunkRaw.position = i;

                        var b0 = chunkRaw.readUnsignedByte();

                        var b1 = chunkRaw.readUnsignedByte();

                        var b2 = chunkRaw.readUnsignedByte();

                        if ((b0 == 0x89 && b1 == 0x50 && b2 == 0x4E) || (b0 == 0xFF && b1 == 0xD8 && b2 == 0xFF)) {

                            imgOffset = i;

                            break;

                        }

                    }

                }



                if (imgOffset >= 0) {

                    var imgBytes = new ByteArray();

                    chunkRaw.position = imgOffset;

                    chunkRaw.readBytes(imgBytes, 0, chunkLen - imgOffset);



                    var tex = new Texture3D();

                    textures.set(chunkId, tex);

                    currentTex = tex;

                    if (defaultTex == null) defaultTex = tex;



                    #if html5

                    try {

                        var hBytes:haxe.io.Bytes = imgBytes;

                        var uint8:js.lib.Uint8Array = cast hBytes.getData();

                        var isPng = (uint8[0] == 0x89);

                        var mime = isPng ? "image/png" : "image/jpeg";

                        var blob = new js.html.Blob([uint8], {type: mime});

                        var blobUrl = js.html.URL.createObjectURL(blob);

                        BitmapData.loadFromFile(blobUrl).onComplete(function(bmd:BitmapData) {

                            if (bmd != null) {

                                tex.bitmapData = bmd;

                                tex.width = bmd.width;

                                tex.height = bmd.height;

                                tex.loaded = true;

                                if (tex.texture != null) {

                                    tex.texture.dispose();

                                    tex.texture = null;

                                }

                                tex.upload();

                                flare.system.DebugLog.log("[ZF3DLoader] Decoded blob texture (html5): " + bmd.width + "x" + bmd.height);

                            }

                        }).onError(function(msg) {

                            flare.system.DebugLog.log("[ZF3DLoader] Blob texture error: " + msg);

                        });

                    } catch (err:Dynamic) {

                        flare.system.DebugLog.log("[ZF3DLoader] Blob exception: " + err);

                    }

                    #else

                    try {

                        var bmd = BitmapData.fromBytes(imgBytes);

                        if (bmd != null) {

                            tex.bitmapData = bmd;

                            tex.width = bmd.width;

                            tex.height = bmd.height;

                            tex.loaded = true;

                            if (tex.texture != null) {

                                tex.texture.dispose();

                                tex.texture = null;

                            }

                            tex.upload();

                        }

                    } catch (e:Dynamic) {

                        flare.system.DebugLog.log("[ZF3DLoader] Texture decode failed: " + e);

                    }

                    #end

                }

            } else if (chunkName == "shader") {

                if (chunkLen >= 2) {

                    var sNameLen = data.readUnsignedShort();

                    var sName = (sNameLen <= chunkLen - 2) ? data.readUTFBytes(sNameLen) : "";

                    currentShaderName = sName;

                    shaderNames.set(chunkId, sName);

                    if (chunkLen >= 2) {

                        data.position = chunkStart + chunkLen - 2;

                        var filterId = data.readShort();

                        shaderFilters.set(chunkId, filterId);

                    }

                }

            } else if (chunkName == "filter") {

                if (chunkLen >= 2) {

                    var fNameLen = data.readUnsignedShort();

                    var fClass = (fNameLen <= chunkLen - 2) ? data.readUTFBytes(fNameLen) : "";

                    if (fClass == "flare.materials.filters::TextureFilter") {

                        if (chunkLen >= 2) {

                            data.position = chunkStart + chunkLen - 2;

                            var tId = data.readShort();

                            filterTextures.set(chunkId, tId);

                        }

                    } else if (fClass == "flare.materials.filters::ColorFilter") {

                        var scanEnd = chunkStart + chunkLen - 17;

                        var p = chunkStart + 2 + fNameLen;

                        while (p <= scanEnd) {

                            data.position = p;

                            if (data.readUnsignedShort() == 5 && data.readUTFBytes(5) == "color" && data.readByte() == 4) {

                                var cr = data.readFloat();

                                var cg = data.readFloat();

                                var cb = data.readFloat();

                                var ca = data.readFloat();

                                filterColors.set(chunkId, { r: cr, g: cg, b: cb, a: ca });

                                break;

                            }

                            p++;

                        }

                    }

                }

            } else if (chunkName == "surf") {

                var sNameLen = data.readUnsignedShort();

                var sName = data.readUTFBytes(sNameLen);

                var bufId = data.readShort();

                var idxId = data.readShort();

                var numTris = (data.position + 4 <= chunkStart + chunkLen) ? data.readUnsignedInt() : 0;

                var firstIdx = (data.position + 4 <= chunkStart + chunkLen) ? data.readUnsignedInt() : 0;

                var stride = (data.position + 4 <= chunkStart + chunkLen) ? data.readUnsignedInt() : 8;



                var shaderId = -1;

                if (chunkLen >= 4) {

                    data.position = chunkStart + chunkLen - 4;

                    shaderId = data.readShort();

                }

                surfShaders.set(chunkId, shaderId);



                surfs.set(chunkId, {

                    name: sName,

                    bufId: bufId,

                    idxId: idxId,

                    numTris: numTris,

                    firstIdx: firstIdx,

                    stride: stride,

                    shaderName: currentShaderName,

                    tex: currentTex != null ? currentTex : defaultTex

                });

            } else if (chunkName == "skin") {

                var rootId:Int = -1;

                var boneIds:Array<Int> = [];

                var invMtx:Array<Matrix3D> = [];

                var skinPalettes:Array<Array<Int>> = [];



                while (data.position < chunkStart + chunkLen - 6) {

                    var sNameLen = data.readUnsignedShort();

                    if (data.position + sNameLen + 6 > chunkStart + chunkLen) break;

                    var sName = data.readUTFBytes(sNameLen);

                    var sId = data.readShort();

                    var sLen = data.readUnsignedInt();

                    var subStart = data.position;



                    if (sName == "root" && sLen >= 2) {

                        rootId = data.readShort();

                    } else if (sName == "bones") {

                        var numBones = Std.int(sLen / 2);

                        for (i in 0...numBones) {

                            boneIds.push(data.readShort());

                        }

                    } else if (sName == "invMtx") {

                        var numMats = Std.int(sLen / 48);

                        for (i in 0...numMats) {

                            var m12 = new Array<Float>();

                            for (j in 0...12) m12.push(data.readFloat());

                            var m44 = new Matrix3D();

                            var raw = new Vector<Float>(16);

                            raw[0] = m12[0]; raw[1] = m12[1]; raw[2] = m12[2]; raw[3] = 0.0;

                            raw[4] = m12[3]; raw[5] = m12[4]; raw[6] = m12[5]; raw[7] = 0.0;

                            raw[8] = m12[6]; raw[9] = m12[7]; raw[10] = m12[8]; raw[11] = 0.0;

                            raw[12] = m12[9]; raw[13] = m12[10]; raw[14] = m12[11]; raw[15] = 1.0;

                            m44.copyRawDataFrom(raw);

                            invMtx.push(m44);

                        }

                    } else if (sName == "data") {

                        var numShorts = Std.int(sLen / 2);

                        var sList = [];

                        for (i in 0...numShorts) sList.push(data.readUnsignedShort());

                        var cur = 0;

                        while (cur < sList.length) {

                            var pLen = sList[cur];

                            var pal:Array<Int> = [];

                            for (k in (cur + 1)...(cur + 1 + pLen)) {

                                if (k < sList.length) pal.push(sList[k]);

                            }

                            skinPalettes.push(pal);

                            cur += 1 + pLen;

                        }

                    }



                    data.position = subStart + sLen;

                }

                skins.set(chunkId, { rootId: rootId, boneIds: boneIds, invMtx: invMtx, palettes: skinPalettes });

            }



            data.position = chunkStart + chunkLen;

        }



        // Assemble Parent-Child Scene Graph Hierarchy & attach animations

        for (meshId in meshes.keys()) {

            var p = meshes.get(meshId);

            if (p == null) continue;

            var parentId = meshParentMap.get(meshId);

            if (parentId != null && parentId != -1 && meshes.exists(parentId)) {

                var parentNode = meshes.get(parentId);

                parentNode.addChild(p);

            } else {

                this.addChild(p);

            }



            if (Std.isOfType(p, Mesh3D)) {

                var mesh:Mesh3D = cast p;

                if (meshAnimMap.exists(meshId)) {

                    var animId = meshAnimMap.get(meshId);

                    if (animTracks.exists(animId)) {

                        var track = animTracks.get(animId);

                        var isSkinned = meshSkinMap.exists(meshId);

                        // Do not assign 2-frame dummy placeholder tracks to skinned meshes

                        if (!isSkinned || track.length > 2) {

                            mesh.frames = track;

                            mesh.totalFrames = track.length;

                            mesh.play();

                            if (track.length > this.totalFrames) {

                                this.totalFrames = track.length;

                            }

                        }

                    }

                }

            }

        }



        // Attach SkinModifier to skinned meshes

        var allBoneIds = new Map<Int, Bool>();

        for (meshId in meshes.keys()) {

            if (meshSkinMap.exists(meshId)) {

                var skinId = meshSkinMap.get(meshId);

                if (skins.exists(skinId)) {

                    var sData = skins.get(skinId);

                    var p = meshes.get(meshId);

                    if (!Std.isOfType(p, Mesh3D)) continue;

                    var mesh:Mesh3D = cast p;

                    var skinMod = new flare.modifiers.SkinModifier(mesh);

                    skinMod.skinData = sData.palettes;

                    flare.system.DebugLog.log("[SkinDebug] mesh=" + mesh.name + " palettes=" + (sData.palettes != null ? sData.palettes.length : 0));

                    if (sData.palettes != null) {

                        for (pi in 0...sData.palettes.length) {

                            flare.system.DebugLog.log("[SkinDebug]   pal[" + pi + "] len=" + sData.palettes[pi].length);

                        }

                    }

                    if (sData.rootId != -1 && meshes.exists(sData.rootId)) {

                        skinMod.root = meshes.get(sData.rootId);

                    }

                    for (bIdx in 0...sData.boneIds.length) {

                        var bId = sData.boneIds[bIdx];

                        allBoneIds.set(bId, true);

                        if (meshes.exists(bId)) {

                            var bonePivot = meshes.get(bId);

                            var invM = (bIdx < sData.invMtx.length) ? sData.invMtx[bIdx] : null;

                            skinMod.addBone(bonePivot, invM);

                        }

                    }

                    mesh.modifier = skinMod;

                }

            }

        }



        // Link surfaces to meshes

        for (meshId in meshes.keys()) {

            // Bones are pivots used for hierarchy and skinning deformation, do not render their placeholder meshes!

            if (allBoneIds.exists(meshId)) {

                continue;

            }



            var p = meshes.get(meshId);

            if (!Std.isOfType(p, Mesh3D)) continue;

            var mesh:Mesh3D = cast p;

            var surfIdList = meshSurfaces.get(meshId);

            var skinMod:flare.modifiers.SkinModifier = (mesh.modifier != null && Std.isOfType(mesh.modifier, flare.modifiers.SkinModifier)) ? cast mesh.modifier : null;



            if (surfIdList != null) {

                var vDataCache = new Map<Int, Vector<Float>>();



                for (sId in surfIdList) {

                    var sInfo = surfs.get(sId);

                    if (sInfo != null && buffers.exists(sInfo.bufId) && indices.exists(sInfo.idxId)) {

                        var rawBuf = buffers.get(sInfo.bufId);

                        var rawIndices = indices.get(sInfo.idxId);

                        var srcStride:Int = 8;

                        if (skinMod != null) {

                            srcStride = 12;

                        } else if (sInfo.stride == 10 || (rawBuf.length % 10 == 0 && rawBuf.length % 8 != 0 && rawBuf.length % 12 != 0)) {

                            srcStride = 10;

                        } else if (rawBuf.length % 12 == 0 && rawBuf.length % 8 != 0) {

                            srcStride = 12;

                        } else if (sInfo.stride == 8 || rawBuf.length % 8 == 0) {

                            srcStride = 8;

                        } else if (sInfo.stride != null && sInfo.stride > 0) {

                            srcStride = sInfo.stride;

                        }

                        var numVerts = Std.int(rawBuf.length / srcStride);

                        flare.system.DebugLog.log("[SkinDebug] mesh=" + mesh.name + " sIdx=" + surfIdList.indexOf(sId) + " sId=" + sId + " sName=" + sInfo.name + " bufId=" + sInfo.bufId + " idxId=" + sInfo.idxId + " numTris=" + sInfo.numTris + " firstIdx=" + sInfo.firstIdx + " stride=" + srcStride + " rawBufLen=" + rawBuf.length + " numVerts=" + numVerts);



                        var surface = new Surface3D(sInfo.name != "" ? sInfo.name : mesh.name + "_surf");



                        var surfaceVData = vDataCache.get(sInfo.bufId);

                        if (surfaceVData == null) {

                            surfaceVData = new Vector<Float>(numVerts * 8);

                            for (i in 0...numVerts) {

                                var srcBase = i * srcStride;

                                var dstBase = i * 8;

                                var px = rawBuf[srcBase + 0];

                                var py = rawBuf[srcBase + 1];

                                var pz = rawBuf[srcBase + 2];

                                var nx:Float = 0.0;

                                var ny:Float = 1.0;

                                var nz:Float = 0.0;

                                var u:Float = 0.0;

                                var v:Float = 0.0;



                                if (srcStride == 10) {

                                    // Stride 10 format: pos(3), uv(2), norm(3), extra(2)

                                    u = rawBuf[srcBase + 3];

                                    v = rawBuf[srcBase + 4];

                                    nx = rawBuf[srcBase + 5];

                                    ny = rawBuf[srcBase + 6];

                                    nz = rawBuf[srcBase + 7];

                                } else {

                                    // Stride 8 or 12 format: pos(3), norm(3), uv(2)

                                    nx = rawBuf[srcBase + 3];

                                    ny = rawBuf[srcBase + 4];

                                    nz = rawBuf[srcBase + 5];

                                    u = (srcStride >= 8) ? rawBuf[srcBase + 6] : 0.0;

                                    v = (srcStride >= 8) ? rawBuf[srcBase + 7] : 0.0;

                                }



                                surfaceVData[dstBase + 0] = px;

                                surfaceVData[dstBase + 1] = py;

                                surfaceVData[dstBase + 2] = pz;

                                surfaceVData[dstBase + 3] = u;

                                surfaceVData[dstBase + 4] = v;

                                surfaceVData[dstBase + 5] = nx;

                                surfaceVData[dstBase + 6] = ny;

                                surfaceVData[dstBase + 7] = nz;

                            }



                            if (skinMod != null && skinMod.numVertices == 0) {

                                skinMod.numVertices = numVerts;

                                skinMod.origPositions = new Vector<Float>(numVerts * 3);

                                skinMod.origNormals = new Vector<Float>(numVerts * 3);

                                skinMod.weights = new Vector<Float>(numVerts * 2);

                                skinMod.boneIndices = new Vector<Int>(numVerts * 2);



                                var pal0 = (skinMod.skinData != null && skinMod.skinData.length > 0) ? skinMod.skinData[0] : null;



                                var vertexPaletteMap = new Vector<Int>(numVerts);

                                for (k in 0...numVerts) vertexPaletteMap[k] = 0;



                                if (skinMod.skinData != null && skinMod.skinData.length > 1 && surfIdList != null) {

                                    for (sIdx in 0...surfIdList.length) {

                                        var subSId = surfIdList[sIdx];

                                        var subSInfo = surfs.get(subSId);

                                        if (subSInfo != null && indices.exists(subSInfo.idxId)) {

                                            var rIndices = indices.get(subSInfo.idxId);

                                            var first = (subSInfo.firstIdx != null) ? subSInfo.firstIdx : 0;

                                            var numIndices = (subSInfo.numTris > 0) ? (subSInfo.numTris * 3) : (rIndices.length - first);

                                            var palIdx = (sIdx < skinMod.skinData.length) ? sIdx : 0;

                                            for (k in 0...numIndices) {

                                                var rIdx = first + k;

                                                if (rIdx < rIndices.length) {

                                                    var vIdx = rIndices[rIdx];

                                                    if (vIdx < numVerts) {

                                                        vertexPaletteMap[vIdx] = palIdx;

                                                    }

                                                }

                                            }

                                        }

                                    }

                                }



                                for (i in 0...numVerts) {

                                    var srcBase = i * srcStride;

                                    var pIdx = i * 3;

                                    var wIdx = i * 2;



                                    skinMod.origPositions[pIdx + 0] = rawBuf[srcBase + 0];

                                    skinMod.origPositions[pIdx + 1] = rawBuf[srcBase + 1];

                                    skinMod.origPositions[pIdx + 2] = rawBuf[srcBase + 2];



                                    skinMod.origNormals[pIdx + 0] = rawBuf[srcBase + 3];

                                    skinMod.origNormals[pIdx + 1] = rawBuf[srcBase + 4];

                                    skinMod.origNormals[pIdx + 2] = rawBuf[srcBase + 5];



                                    if (srcStride >= 12) {

                                        var w0 = rawBuf[srcBase + 8];

                                        var w1 = rawBuf[srcBase + 9];

                                        var wSum = w0 + w1;

                                        if (wSum > 0.000001) {

                                            w0 /= wSum;

                                            w1 /= wSum;

                                        } else {

                                            w0 = 1.0; w1 = 0.0;

                                        }

                                        skinMod.weights[wIdx + 0] = w0;

                                        skinMod.weights[wIdx + 1] = w1;



                                        var palIdx = vertexPaletteMap[i];

                                        var pal = (skinMod.skinData != null && palIdx < skinMod.skinData.length) ? skinMod.skinData[palIdx] : pal0;

                                        var j0 = Math.round(rawBuf[srcBase + 10] / 3.0);

                                        var j1 = Math.round(rawBuf[srcBase + 11] / 3.0);

                                        var b0 = (pal != null && j0 >= 0 && j0 < pal.length) ? pal[j0] : 0;

                                        var b1 = (pal != null && j1 >= 0 && j1 < pal.length) ? pal[j1] : 0;

                                        skinMod.boneIndices[wIdx + 0] = b0;

                                        skinMod.boneIndices[wIdx + 1] = b1;

                                    } else {

                                        skinMod.weights[wIdx + 0] = 1.0;

                                        skinMod.weights[wIdx + 1] = 0.0;

                                        skinMod.boneIndices[wIdx + 0] = 0;

                                        skinMod.boneIndices[wIdx + 1] = 0;

                                    }

                                }

                            }



                            vDataCache.set(sInfo.bufId, surfaceVData);

                        }



                        surface.vertexData = surfaceVData;

                        surface.vertexStride = 8;

                        if (skinMod != null) surface.isSkinned = true;



                        // Slice index buffer based on firstIdx and numTris

                        var first = (sInfo.firstIdx != null) ? sInfo.firstIdx : 0;

                        var numIndices = (sInfo.numTris > 0) ? (sInfo.numTris * 3) : (rawIndices.length - first);

                        var sIndices = new Vector<UInt>(numIndices);

                        for (k in 0...numIndices) {

                            var rIdx = first + k;

                            sIndices[k] = (rIdx < rawIndices.length) ? rawIndices[rIdx] : 0;

                        }

                        var minV:Int = 999999;

                        var maxV:Int = 0;

                        for (k in 0...numIndices) {

                            var v:Int = sIndices[k];

                            if (v < minV) minV = v;

                            if (v > maxV) maxV = v;

                        }

                        flare.system.DebugLog.log("[SkinDebug] sIdx=" + surfIdList.indexOf(sId) + " minV=" + minV + " maxV=" + maxV);

                        surface.indexData = sIndices;

                        surface.firstIndex = 0;

                        surface.numTriangles = Std.int(sIndices.length / 3);

                        surface.computeCenter();



                        var mat:flare.materials.Material3D = null;

                        var shaderId = surfShaders.get(sId);



                        if (shaderId != null && shaderId != -1 && materialsCache.exists(shaderId)) {

                            mat = materialsCache.get(shaderId);

                        } else {

                            var fId = (shaderId != null && shaderFilters.exists(shaderId)) ? shaderFilters.get(shaderId) : -1;

                            var sMatName = (shaderId != null && shaderNames.exists(shaderId)) ? shaderNames.get(shaderId) :

                                           ((sInfo.shaderName != null && sInfo.shaderName != "") ? sInfo.shaderName : (mesh.name + "_mat"));



                            if (fId != -1 && filterColors.exists(fId)) {

                                var col = filterColors.get(fId);

                                var hex = (Math.round(col.r * 255) << 16) | (Math.round(col.g * 255) << 8) | Math.round(col.b * 255);

                                mat = new Shader3D(sMatName, [new ColorFilter(hex), new LightFilter()]);

                            } else {

                                var tId = (fId != -1 && filterTextures.exists(fId)) ? filterTextures.get(fId) : -1;

                                var sTex:Texture3D = (tId != -1 && textures.exists(tId)) ? textures.get(tId) : ((sInfo.tex != null) ? sInfo.tex : defaultTex);



                                // Authentic Flare3D template texture mapping for mines and enemies (fallback)

                                if (tId == -1) {

                                    if (mesh.name == "mine" || StringTools.startsWith(mesh.name, "mine_") || mesh.name.indexOf("mine") != -1) {

                                        if (mesh.surfaces.length == 0 && textures.exists(2402)) sTex = textures.get(2402);

                                        else if (textures.exists(2411)) sTex = textures.get(2411);

                                    } else if (mesh.name == "enemy" || StringTools.startsWith(mesh.name, "enemy_") || mesh.name.indexOf("enemy") != -1) {

                                        if (mesh.surfaces.length == 0 && textures.exists(2411)) sTex = textures.get(2411);

                                        else if (textures.exists(2426)) sTex = textures.get(2426);

                                    }

                                }



                                var isSky = (mesh.name == "sky" || sMatName.toLowerCase().indexOf("sky") != -1);

                                var isShadow = (mesh.name.toLowerCase().indexOf("shadow") != -1);



                                if (isSky) {

                                    mat = new Shader3D(sMatName, [sTex != null ? new TextureMapFilter(sTex) : new ColorFilter(0x071D3E)]);

                                    mat.depthWrite = false;

                                } else if (isShadow) {

                                    mat = new Shader3D(sMatName, [sTex != null ? new TextureMapFilter(sTex) : new ColorFilter(0x000000)]);

                                    mat.sourceFactor = openfl.display3D.Context3DBlendFactor.SOURCE_ALPHA;

                                    mat.destFactor = openfl.display3D.Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;

                                    mat.depthWrite = false;

                                } else if (sTex != null) {

                                    mat = new Shader3D(sMatName, [new TextureMapFilter(sTex), new LightFilter()]);

                                } else {

                                    mat = new Shader3D(sMatName, [new ColorFilter(0xcccccc), new LightFilter()]);

                                }

                            }

                            mat.twoSided = true;

                            if (shaderId != null && shaderId != -1) {

                                materialsCache.set(shaderId, mat);

                            }

                        }



                        mesh.addSurface(surface, mat);

                    }

                }

            }

        }



        this.play(true);



        // Adjust camera to frame the model perfectly

        if (scene != null && (url == null || (url.toLowerCase().indexOf("axis") == -1 && url.toLowerCase().indexOf("shapes") == -1))) {

            if (Std.isOfType(scene, flare.basic.Viewer3D)) {

                var viewer:flare.basic.Viewer3D = cast scene;

                if (url != null && (url.toLowerCase().indexOf("player") != -1 || url.toLowerCase().indexOf("anim_base") != -1)) {

                    viewer.target.setTo(0, 0.9, 0);

                    viewer.radius = 2.5;

                } else if (url != null && url.toLowerCase().indexOf("astronaut") != -1) {

                    viewer.target.setTo(0, 5.0, 0);

                    viewer.radius = 25.0;

                } else if (url != null && url.toLowerCase().indexOf("vaca") != -1) {

                    viewer.setTarget(0, 70, 0);

                    viewer.syncOrbitFromCamera();

                } else if (url != null && url.toLowerCase().indexOf("elsa") != -1) {

                    viewer.target.setTo(0, 0, 0);

                    scene.camera.setPosition(0, 50, -200);

                    scene.camera.lookAt(0, 0, 0);

                    viewer.syncOrbitFromCamera();

                } else if (url != null && url.toLowerCase().indexOf("teapot") != -1) {
                    if (viewer.target == null || viewer.target.length < 0.001) {
                        viewer.setTarget(-4.5, 6.5, 0);
                    }
                    if (scene.camera != null && scene.camera.getPosition(false).length > 0.001) {
                        viewer.syncOrbitFromCamera();
                    } else {
                        scene.camera.setPosition(168.2, 62.2, 161.2);
                        scene.camera.lookAt(viewer.target.x, viewer.target.y, viewer.target.z);
                        viewer.syncOrbitFromCamera();
                    }
                } else {
                    viewer.target.setTo(0, 2.0, 0.5);
                    viewer.radius = 16.0;
                }

                viewer.minRadius = 0.2;

                viewer.updateCameraOrbit();

            } else if (scene.camera != null && scene.camera.parent == null && (url == null || url.toLowerCase().indexOf("map") == -1)) {

                if (loadedCameraPos != null && loadedCameraPos.length > 1.0) {

                    scene.camera.setPosition(loadedCameraPos.x, loadedCameraPos.y, loadedCameraPos.z);

                    scene.camera.lookAt(0, 1.5, 0);

                } else if (scene.camera.getPosition().length > 50.0) {

                    scene.camera.setPosition(-10, 8, -12);

                    scene.camera.lookAt(0, 1.5, 0);

                }

            }

        }



        loaded = true;

        var dt = openfl.Lib.getTimer() - _loadStartTime;

        flare.system.DebugLog.log("[PERF] Loaded and parsed " + url + " in " + dt + " ms (meshes=" + this.children.length + ")");

        dispatchEvent(new Event(Flare3DLoader.COMPLETE_EVENT));

        if (scene != null) {

            scene.notifyLoadComplete();

        }

    }



    private function parseZipArchive(bytes:ByteArray):Void {

        var hBytes:haxe.io.Bytes = bytes;

        var bytesInput = new haxe.io.BytesInput(hBytes);

        var entries = haxe.zip.Reader.readZip(bytesInput);

        var fileMap = new Map<String, haxe.io.Bytes>();



        for (entry in entries) {

            var dataBytes:haxe.io.Bytes = null;

            if (entry.compressed) {

                #if html5

                try {

                    dataBytes = lime._internal.format.Deflate.decompress(entry.data);

                } catch (e:Dynamic) {

                    flare.system.DebugLog.log("[ZF3DLoader] Deflate error on " + entry.fileName + ": " + e);

                    dataBytes = entry.data;

                }

                #else

                try {

                    dataBytes = haxe.zip.Reader.unzip(entry);

                } catch (e:Dynamic) {

                    try {

                        dataBytes = lime._internal.format.Deflate.decompress(entry.data);

                    } catch (e2:Dynamic) {

                        dataBytes = entry.data;

                    }

                }

                #end

            } else {

                dataBytes = entry.data;

            }

            if (dataBytes != null) {

                fileMap.set(entry.fileName, dataBytes);

                var slashIdx = entry.fileName.lastIndexOf("/");

                if (slashIdx != -1) {

                    fileMap.set(entry.fileName.substr(slashIdx + 1), dataBytes);

                }

            }

        }



        var textureMap = new Map<String, Texture3D>();

        var firstTex:Texture3D = null;

        for (fName in fileMap.keys()) {

            var lower = fName.toLowerCase();

            if (StringTools.endsWith(lower, ".jpg") || StringTools.endsWith(lower, ".png")) {

                var texBytes = fileMap.get(fName);

                var tex = new Texture3D();

                tex.name = fName;

                #if html5

                try {

                    var uint8:js.lib.Uint8Array = cast texBytes.getData();

                    var isPng = (uint8[0] == 0x89);

                    var mime = isPng ? "image/png" : "image/jpeg";

                    var blob = new js.html.Blob([uint8], {type: mime});

                    var blobUrl = js.html.URL.createObjectURL(blob);

                    BitmapData.loadFromFile(blobUrl).onComplete(function(bmd:BitmapData) {

                        if (bmd != null) {

                            tex.bitmapData = bmd;

                            tex.width = bmd.width;

                            tex.height = bmd.height;

                            tex.loaded = true;

                            tex.upload();

                        }

                    });

                } catch (e:Dynamic) {}

                #else

                try {

                    var bmd = BitmapData.fromBytes(ByteArray.fromBytes(texBytes));

                    if (bmd != null) {

                        tex.bitmapData = bmd;

                        tex.width = bmd.width;

                        tex.height = bmd.height;

                        tex.loaded = true;

                        tex.upload();

                    }

                } catch (e:Dynamic) {}

                #end

                textureMap.set(fName, tex);

                if (firstTex == null) firstTex = tex;

            }

        }



        if (!fileMap.exists("main.xml")) {

            flare.system.DebugLog.log("[ZF3DLoader] Zip archive contains no main.xml");

            return;

        }



        var mainXmlBytes = fileMap.get("main.xml");

        var xmlStr = mainXmlBytes.getString(0, mainXmlBytes.length);

        flare.system.DebugLog.log("[ZF3DLoader] main.xml bytes=" + mainXmlBytes.length + ", strLen=" + xmlStr.length + ", head=" + xmlStr.substr(0, 40));

        var xml = Xml.parse(xmlStr);

        var rootElem:Xml = null;

        for (el in xml.elements()) {

            rootElem = el;

            break;

        }

        if (rootElem == null) {

            rootElem = xml.firstElement();

        }

        flare.system.DebugLog.log("[ZF3DLoader] rootElem=" + (rootElem != null ? rootElem.nodeName : "null"));

        if (rootElem == null) {

            return;

        }



        var animsElem:Xml = null;

        var surfsElem:Xml = null;

        var modElem:Xml = null;

        var nodesElem:Xml = null;

        var splinesElem:Xml = null;

        var sceneElem:Xml = null;

        var cameraElem:Xml = null;

        for (el in rootElem.elements()) {

            var n = el.nodeName;

            if (n == "animations") animsElem = el;

            else if (n == "surfaces") surfsElem = el;

            else if (n == "modifiers") modElem = el;

            else if (n == "nodes") nodesElem = el;

            else if (n == "splines") splinesElem = el;

            else if (n == "scene") sceneElem = el;

            else if (n == "camera") {

                if (el.get("active") == "true" || cameraElem == null) cameraElem = el;

            }

        }



        if (sceneElem != null && scene != null) {

            var cc = sceneElem.get("clearColor");

            if (cc != null) {

                var parts = cc.split(",");

                if (parts.length >= 3) {

                    var r = Std.parseFloat(parts[0]) / 255.0;

                    var g = Std.parseFloat(parts[1]) / 255.0;

                    var b = Std.parseFloat(parts[2]) / 255.0;

                    scene.clearColor.setTo(r, g, b);

                }

            }

        }



        // 1. 解析动画

        var animMap = new Map<String, openfl.Vector<flare.core.Frame3D>>();

        var maxAnimFrames = 0;

        if (animsElem != null) {

            for (aEl in animsElem.elements()) {

                if (aEl.nodeName == "animation") {

                    var aId = aEl.get("id");

                    var src = aEl.get("source");

                    var fileName = (src != null ? src : aId) + ".animation";

                    var animBytes = fileMap.exists(fileName) ? fileMap.get(fileName) : fileMap.get("_" + fileName);

                    if (animBytes != null) {

                        var frames = new openfl.Vector<flare.core.Frame3D>();

                        var numFrames = Std.int(animBytes.length / 48);

                        if (numFrames > maxAnimFrames) maxAnimFrames = numFrames;

                        var aBa = ByteArray.fromBytes(animBytes);

                        aBa.endian = Endian.LITTLE_ENDIAN;

                        for (f in 0...numFrames) {

                            var frame = new flare.core.Frame3D();

                            var raw = new openfl.Vector<Float>(16);

                            var m00 = aBa.readFloat(); var m10 = aBa.readFloat(); var m20 = aBa.readFloat();

                            var m01 = aBa.readFloat(); var m11 = aBa.readFloat(); var m21 = aBa.readFloat();

                            var m02 = aBa.readFloat(); var m12 = aBa.readFloat(); var m22 = aBa.readFloat();

                            var tx = aBa.readFloat();  var ty = aBa.readFloat();  var tz = aBa.readFloat();



                            raw[0] = m00; raw[1] = m10; raw[2] = m20; raw[3] = 0.0;

                            raw[4] = m01; raw[5] = m11; raw[6] = m21; raw[7] = 0.0;

                            raw[8] = m02; raw[9] = m12; raw[10] = m22; raw[11] = 0.0;

                            raw[12] = tx; raw[13] = ty; raw[14] = tz; raw[15] = 1.0;



                            frame.copyRawDataFrom(raw);

                            frames.push(frame);

                        }

                        animMap.set(aId, frames);

                        if (src != null) animMap.set(src, frames);

                    }

                }

            }

        }

        this.totalFrames = maxAnimFrames;



        // 2. 解析 Surfaces

        var surfaceMap = new Map<String, Surface3D>();

        if (surfsElem != null) {

            for (sEl in surfsElem.elements()) {

                if (sEl.nodeName == "surface") {

                    var sId = sEl.get("id");

                    var src = sEl.get("source");

                    var fileName = (src != null ? src : sId) + ".vertex";

                    var vBytes = fileMap.get(fileName);

                    if (vBytes != null) {

                        var vBa = ByteArray.fromBytes(vBytes);

                        vBa.endian = Endian.LITTLE_ENDIAN;

                        var sizePerVert = Std.parseInt(sEl.get("sizePerVertex"));

                        if (sizePerVert == null || sizePerVert == 0) sizePerVert = 8;

                        var numVerts = Std.int(vBa.length / (sizePerVert * 4));



                        var hasUV2 = (sizePerVert >= 10);
                        var stride = hasUV2 ? 10 : 8;
                        var vData = new openfl.Vector<Float>(numVerts * stride);

                        var rawFloats = new openfl.Vector<Float>(numVerts * sizePerVert);

                        var idxData = new openfl.Vector<UInt>(numVerts);

                        var weights:openfl.Vector<Float> = (sizePerVert >= 12) ? new openfl.Vector<Float>(numVerts * 2) : null;

                        var boneIndices:openfl.Vector<Int> = (sizePerVert >= 12) ? new openfl.Vector<Int>(numVerts * 2) : null;



                        for (v in 0...numVerts) {

                            idxData[v] = v;

                            var curRawBase = v * sizePerVert;

                            for (k in 0...sizePerVert) {

                                rawFloats[curRawBase + k] = vBa.readFloat();

                            }



                            var px = rawFloats[curRawBase + 0];

                            var py = rawFloats[curRawBase + 1];

                            var pz = rawFloats[curRawBase + 2];

                            var nx = 0.0;

                            var ny = 1.0;

                            var nz = 0.0;

                            var u = 0.0;

                            var vCoord = 0.0;



                            if (sizePerVert >= 8) {

                                nx = rawFloats[curRawBase + 3];

                                ny = rawFloats[curRawBase + 4];

                                nz = rawFloats[curRawBase + 5];

                                u = rawFloats[curRawBase + 6];

                                vCoord = rawFloats[curRawBase + 7];

                            } else if (sizePerVert == 6) {

                                nx = rawFloats[curRawBase + 3];

                                ny = rawFloats[curRawBase + 4];

                                nz = rawFloats[curRawBase + 5];

                            }



                            if (sizePerVert >= 12) {

                                weights[v * 2 + 0] = rawFloats[curRawBase + 8];

                                weights[v * 2 + 1] = rawFloats[curRawBase + 9];

                                var j0 = Std.int(Math.round(rawFloats[curRawBase + 10] / 3.0));

                                var j1 = Std.int(Math.round(rawFloats[curRawBase + 11] / 3.0));

                                boneIndices[v * 2 + 0] = j0;

                                boneIndices[v * 2 + 1] = j1;

                            }



                            var dstBase = v * stride;

                            vData[dstBase + 0] = px;

                            vData[dstBase + 1] = py;

                            vData[dstBase + 2] = pz;

                            vData[dstBase + 3] = u;

                            vData[dstBase + 4] = vCoord;

                            vData[dstBase + 5] = nx;

                            vData[dstBase + 6] = ny;

                            vData[dstBase + 7] = nz;
                            if (hasUV2) {
                                vData[dstBase + 8] = rawFloats[curRawBase + 8];
                                vData[dstBase + 9] = rawFloats[curRawBase + 9];
                            }
                        }



                        var surf = new Surface3D(sEl.get("name") != null ? sEl.get("name") : "surf_" + sId);

                        surf.vertexStride = stride;
                        surf.vertexVector = vData;

                        surf.indexVector = idxData;

                        var fi = sEl.get("firstIndex");

                        if (fi != null) surf.firstIndex = Std.parseInt(fi);

                        var nt = sEl.get("numTriangles");

                        if (nt != null) surf.numTriangles = Std.parseInt(nt);

                        if (weights != null && boneIndices != null) {

                            surf.userData = { weights: weights, boneIndices: boneIndices };

                        }



                        surfaceMap.set(sId, surf);

                        if (src != null) surfaceMap.set(src, surf);

                    }

                }

            }



            for (sEl in surfsElem.elements()) {

                if (sEl.nodeName == "instanceOf") {

                    var instId = sEl.get("id");

                    var baseSurfId = sEl.get("surface");

                    if (surfaceMap.exists(baseSurfId)) {

                        var baseSurf = surfaceMap.get(baseSurfId);

                        var fi = Std.parseInt(sEl.get("firstIndex"));

                        var nt = Std.parseInt(sEl.get("numTriangles"));

                        if (fi == null) fi = 0;

                        if (nt == null) nt = Std.int(baseSurf.vertexVector.length / 24);



                        var vertCount = nt * 3;

                        var subSurf = new Surface3D(baseSurf.name + "_sub_" + instId);

                        var subVData = new openfl.Vector<Float>(vertCount * 8);

                        var baseVData = baseSurf.vertexVector;

                        for (i in 0...vertCount) {

                            var srcOffset = (fi + i) * 8;

                            var dstOffset = i * 8;

                            for (k in 0...8) {

                                subVData[dstOffset + k] = (srcOffset + k < baseVData.length) ? baseVData[srcOffset + k] : 0.0;

                            }

                        }

                        subSurf.vertexVector = subVData;



                        var subIdxData = new openfl.Vector<UInt>(vertCount);

                        for (i in 0...vertCount) subIdxData[i] = i;

                        subSurf.indexVector = subIdxData;

                        subSurf.firstIndex = 0;

                        subSurf.numTriangles = nt;



                        if (baseSurf.userData != null) {

                            var bUData:Dynamic = baseSurf.userData;

                            var bWeights:openfl.Vector<Float> = bUData.weights;

                            var bIndices:openfl.Vector<Int> = bUData.boneIndices;

                            if (bWeights != null && bIndices != null) {

                                var subW = new openfl.Vector<Float>(vertCount * 2);

                                var subJ = new openfl.Vector<Int>(vertCount * 2);

                                for (i in 0...vertCount) {

                                    var srcW = (fi + i) * 2;

                                    var dstW = i * 2;

                                    subW[dstW + 0] = (srcW < bWeights.length) ? bWeights[srcW + 0] : 1.0;

                                    subW[dstW + 1] = (srcW + 1 < bWeights.length) ? bWeights[srcW + 1] : 0.0;

                                    subJ[dstW + 0] = (srcW < bIndices.length) ? bIndices[srcW + 0] : 0;

                                    subJ[dstW + 1] = (srcW + 1 < bIndices.length) ? bIndices[srcW + 1] : 0;

                                }

                                subSurf.userData = { weights: subW, boneIndices: subJ };

                            }

                        }



                        surfaceMap.set(instId, subSurf);

                    }

                }

            }

        }



        // 3. 解析 Modifiers (蒙皮)

        var skinInfo:Dynamic = null;

        if (modElem != null) {

            for (mEl in modElem.elements()) {

                if (mEl.nodeName == "modifier" && mEl.get("type") == "skin") {

                    var targetId = mEl.get("target");

                    var bonesStr = mEl.get("bones");

                    var boneIds = bonesStr != null ? bonesStr.split(",") : [];

                    var weightSurfId = mEl.get("surfaces");

                    var wBytes = (weightSurfId != null) ? fileMap.get(weightSurfId + ".vertex") : null;



                    var invMap = new Map<String, Matrix3D>();

                    for (ch in mEl.elements()) {

                        if (ch.nodeName == "invBoneMatrix") {

                            for (tEl in ch.elements()) {

                                if (tEl.nodeName == "transform") {

                                    var bId = tEl.get("id");

                                    var dStr = tEl.get("data");

                                    if (dStr != null) {

                                        var parts = dStr.split(",");

                                        if (parts.length >= 12) {

                                            var raw = new openfl.Vector<Float>(16);

                                            raw[0] = Std.parseFloat(parts[0]);

                                            raw[1] = Std.parseFloat(parts[1]);

                                            raw[2] = Std.parseFloat(parts[2]);

                                            raw[3] = 0.0;

                                            raw[4] = Std.parseFloat(parts[3]);

                                            raw[5] = Std.parseFloat(parts[4]);

                                            raw[6] = Std.parseFloat(parts[5]);

                                            raw[7] = 0.0;

                                            raw[8] = Std.parseFloat(parts[6]);

                                            raw[9] = Std.parseFloat(parts[7]);

                                            raw[10] = Std.parseFloat(parts[8]);

                                            raw[11] = 0.0;

                                            raw[12] = Std.parseFloat(parts[9]);

                                            raw[13] = Std.parseFloat(parts[10]);

                                            raw[14] = Std.parseFloat(parts[11]);

                                            raw[15] = 1.0;

                                            var m = new Matrix3D();

                                            m.copyRawDataFrom(raw);

                                            invMap.set(bId, m);

                                        }

                                    }

                                }

                            }

                        }

                    }



                    var surfPalettes:Array<Array<Int>> = [];

                    for (ch in mEl.elements()) {

                        if (ch.nodeName == "surfaces") {

                            for (sSub in ch.elements()) {

                                if (sSub.nodeName == "surface") {

                                    var dStr = sSub.get("data");

                                    if (dStr != null) {

                                        var pList:Array<Int> = [];

                                        for (item in dStr.split(",")) {

                                            pList.push(Std.parseInt(StringTools.trim(item)));

                                        }

                                        surfPalettes.push(pList);

                                    }

                                }

                            }

                        }

                    }



                    skinInfo = {

                        targetId: targetId,

                        boneIds: boneIds,

                        weightSurfId: weightSurfId,

                        wBytes: wBytes,

                        invMap: invMap,

                        surfPalettes: surfPalettes,

                        bonesPerVertex: (mEl.get("bonesPerVertex") != null) ? Std.parseInt(mEl.get("bonesPerVertex")) : 4

                    };

                    break;

                }

            }

        }



        // 3.4 解析 Maps & Filters

        var mapToTex = new Map<String, Texture3D>();
        var mapRepeatX = new Map<String, Float>();
        var mapRepeatY = new Map<String, Float>();
        var mapOffsetX = new Map<String, Float>();
        var mapOffsetY = new Map<String, Float>();

        var mapsElem:Xml = null;

        for (el in rootElem.elements()) {

            if (el.nodeName == "maps") { mapsElem = el; break; }

        }

        if (mapsElem != null) {

            for (mEl in mapsElem.elements()) {

                var mId = mEl.get("id");

                var src = mEl.get("source");

                var mType = mEl.get("type");

                for (ch in mEl.elements()) {
                    if (ch.nodeName == "uRepeat") mapRepeatX.set(mId, Std.parseFloat(ch.get("value")));
                    else if (ch.nodeName == "vRepeat") mapRepeatY.set(mId, Std.parseFloat(ch.get("value")));
                    else if (ch.nodeName == "uOffset") mapOffsetX.set(mId, Std.parseFloat(ch.get("value")));
                    else if (ch.nodeName == "vOffset") mapOffsetY.set(mId, Std.parseFloat(ch.get("value")));
                }

                if (src != null && textureMap.exists(src)) {
                    var t = textureMap.get(src);
                    if (mType == "cubemap" || mType == "cube") {
                        if (t.type != Texture3D.TYPE_CUBE) {
                            t.type = Texture3D.TYPE_CUBE;
                            if (t.texture != null) {
                                t.texture.dispose();
                                t.texture = null;
                            }
                        }
                    }
                    mapToTex.set(mId, t);
                }
            }
        }

        var filterInfo = new Map<String, {
            filterClass:String,
            tex:Texture3D,
            mapId:String,
            color:Null<Int>,
            level:Float,
            isEnv:Bool,
            blendMode:String,
            repeatX:Float,
            repeatY:Float,
            offsetX:Float,
            offsetY:Float
        }>();

        var filtersElem:Xml = null;
        for (el in rootElem.elements()) {
            if (el.nodeName == "filters") { filtersElem = el; break; }
        }
        if (filtersElem != null) {
            for (fEl in filtersElem.elements()) {
                var fId = fEl.get("id");
                var fClass = fEl.get("class");
                if (fClass == null) fClass = "";
                var fBlend = fEl.get("blendMode");
                var isEnv = (fClass.indexOf("EnvironmentMap") != -1);
                var fTex:Texture3D = null;
                var fMapId:String = null;
                var fColor:Null<Int> = null;
                var fLevel:Float = 1.0;
                var fRepeatX:Float = 1.0;
                var fRepeatY:Float = 1.0;
                var fOffsetX:Float = 0.0;
                var fOffsetY:Float = 0.0;

                for (ch in fEl.elements()) {
                    if (ch.nodeName == "sampler") {
                        var mapId = ch.get("map");
                        if (mapId != null && mapToTex.exists(mapId)) {
                            fTex = mapToTex.get(mapId);
                            fMapId = mapId;
                        }
                    } else if (ch.nodeName == "param") {
                        var pName = ch.get("name");
                        var pVal = ch.get("value");
                        if (pName == "color" && pVal != null) {
                            var cp = pVal.split(",");
                            if (cp.length >= 3) {
                                var cr:Int = Std.int(Math.min(255, Math.max(0, Std.parseFloat(cp[0]) * (Std.parseFloat(cp[0]) <= 1.0 ? 255.0 : 1.0))));
                                var cg:Int = Std.int(Math.min(255, Math.max(0, Std.parseFloat(cp[1]) * (Std.parseFloat(cp[1]) <= 1.0 ? 255.0 : 1.0))));
                                var cb:Int = Std.int(Math.min(255, Math.max(0, Std.parseFloat(cp[2]) * (Std.parseFloat(cp[2]) <= 1.0 ? 255.0 : 1.0))));
                                fColor = (cr << 16) | (cg << 8) | cb;
                            }
                        } else if (pName == "level" && pVal != null) {
                            var lp = pVal.split(",");
                            fLevel = Std.parseFloat(lp[0]);
                        } else if (pName == "repeat" && pVal != null) {
                            var rp = pVal.split(",");
                            if (rp.length >= 2) {
                                fRepeatX = Std.parseFloat(rp[0]);
                                fRepeatY = Std.parseFloat(rp[1]);
                            }
                        } else if (pName == "offset" && pVal != null) {
                            var op = pVal.split(",");
                            if (op.length >= 2) {
                                fOffsetX = Std.parseFloat(op[0]);
                                fOffsetY = Std.parseFloat(op[1]);
                            }
                        }
                    }
                }
                filterInfo.set(fId, {
                    filterClass: fClass,
                    tex: fTex,
                    mapId: fMapId,
                    color: fColor,
                    level: fLevel,
                    isEnv: isEnv,
                    blendMode: fBlend,
                    repeatX: fRepeatX,
                    repeatY: fRepeatY,
                    offsetX: fOffsetX,
                    offsetY: fOffsetY
                });
            }
        }



        // 3.5 解析 Materials

        var matMap = new Map<String, Material3D>();

        var matsElem:Xml = null;

        for (el in rootElem.elements()) {

            if (el.nodeName == "materials") { matsElem = el; break; }

        }

        if (matsElem != null) {

            for (mEl in matsElem.elements()) {

                if (mEl.nodeName == "material") {

                    var mId = mEl.get("id");

                    var mName = mEl.get("name");

                    if (mName == null || mName == "") mName = "mat_" + mId;



                    var diffuseTex:Texture3D = null;
                    var diffuseMapId:String = null;
                    var diffuseRepeatX:Null<Float> = null;
                    var diffuseRepeatY:Null<Float> = null;
                    var diffuseOffsetX:Null<Float> = null;
                    var diffuseOffsetY:Null<Float> = null;

                    var diffuseColor:Null<Int> = null;

                    var bumpTex:Texture3D = null;

                    var specularTex:Texture3D = null;

                    var reflectionTex:Texture3D = null;
                    var lightMapTex:Texture3D = null;

                    var reflectionLevel:Float = 0.2;

                    var specGlossiness:Float = 10.0;

                    var specLevel:Float = 0.0;

                    var hasSpecular = false;

                    var isEnv = false;



                    for (ch in mEl.elements()) {

                        var nodeN = ch.nodeName;

                        if (nodeN == "diffuse") {

                            var mapId = ch.get("map");

                            if (mapId != null && mapToTex.exists(mapId)) {

                                diffuseTex = mapToTex.get(mapId);
                                diffuseMapId = mapId;

                            }

                            var colStr = ch.get("color");

                            if (colStr != null) {

                                var cp = colStr.split(",");

                                if (cp.length >= 3) {

                                    var cr:Int = Std.int(Math.min(255, Math.max(0, Std.parseFloat(cp[0]))));

                                    var cg:Int = Std.int(Math.min(255, Math.max(0, Std.parseFloat(cp[1]))));

                                    var cb:Int = Std.int(Math.min(255, Math.max(0, Std.parseFloat(cp[2]))));

                                    diffuseColor = (cr << 16) | (cg << 8) | cb;

                                }

                            }

                        } else if (nodeN == "bump") {

                            var mapId = ch.get("map");

                            if (mapId != null && mapToTex.exists(mapId)) {

                                bumpTex = mapToTex.get(mapId);

                            }

                        } else if (nodeN == "specular") {

                            var mapId = ch.get("map");

                            if (mapId != null && mapToTex.exists(mapId)) {

                                specularTex = mapToTex.get(mapId);

                            }

                            var glossStr = ch.get("glossiness");

                            if (glossStr != null) specGlossiness = Std.parseFloat(glossStr);

                            var lvlStr = ch.get("level");

                            if (lvlStr != null) specLevel = Std.parseFloat(lvlStr);

                            if (specLevel > 0) hasSpecular = true;

                        } else if (nodeN == "reflection") {

                            var mapId = ch.get("map");

                            var lvlStr = ch.get("level");

                            if (lvlStr != null) reflectionLevel = Std.parseFloat(lvlStr) / 100.0;

                            if (mapId != null && mapToTex.exists(mapId)) {

                                reflectionTex = mapToTex.get(mapId);

                            }

                        } else if (nodeN == "lightmap") {

                            var mapId = ch.get("map");

                            if (mapId != null && mapToTex.exists(mapId)) {

                                lightMapTex = mapToTex.get(mapId);

                            }

                        } else {
                            var fStr = ch.get("filters");
                            if (fStr != null) {
                                for (fPart in fStr.split(",")) {
                                    var fTrim = StringTools.trim(fPart);
                                    if (filterInfo.exists(fTrim)) {
                                        var info = filterInfo.get(fTrim);
                                        var fc = info.filterClass;
                                        if (fc.indexOf("NormalMapFilter") != -1) {
                                            bumpTex = info.tex;
                                        } else if (fc.indexOf("ReflectionMapFilter") != -1 || fc.indexOf("CubeMapFilter") != -1) {
                                            reflectionTex = info.tex;
                                            reflectionLevel = info.level;
                                        } else if (fc.indexOf("TextureMapFilter") != -1) {
                                            diffuseTex = info.tex;
                                            diffuseMapId = info.mapId;
                                            diffuseRepeatX = info.repeatX;
                                            diffuseRepeatY = info.repeatY;
                                            diffuseOffsetX = info.offsetX;
                                            diffuseOffsetY = info.offsetY;
                                        } else if (fc.indexOf("ColorFilter") != -1) {
                                            diffuseColor = info.color;
                                        } else if (fc.indexOf("EnvironmentMapFilter") != -1) {
                                            diffuseTex = info.tex;
                                            isEnv = true;
                                        } else if (info.tex != null) {
                                            if (diffuseTex == null) {
                                                diffuseTex = info.tex;
                                                diffuseMapId = info.mapId;
                                                diffuseRepeatX = info.repeatX;
                                                diffuseRepeatY = info.repeatY;
                                                diffuseOffsetX = info.offsetX;
                                                diffuseOffsetY = info.offsetY;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if (diffuseTex == null && diffuseColor == null && bumpTex == null && reflectionTex == null && firstTex != null) {
                        diffuseTex = firstTex;
                    }

                    var sFilters:Array<flare.materials.filters.Filter3D> = [];
                    if (diffuseTex != null) {
                        if (isEnv) {
                            sFilters.push(new flare.materials.filters.EnvironmentMapFilter(diffuseTex));
                        } else {
                            var tmf = new flare.materials.filters.TextureMapFilter(diffuseTex);
                            if (diffuseRepeatX != null) tmf.repeatX = diffuseRepeatX;
                            if (diffuseRepeatY != null) tmf.repeatY = diffuseRepeatY;
                            if (diffuseOffsetX != null) tmf.offsetX = diffuseOffsetX;
                            if (diffuseOffsetY != null) tmf.offsetY = diffuseOffsetY;
                            if (diffuseMapId != null) {
                                if (mapRepeatX.exists(diffuseMapId)) tmf.repeatX = mapRepeatX.get(diffuseMapId);
                                if (mapRepeatY.exists(diffuseMapId)) tmf.repeatY = mapRepeatY.get(diffuseMapId);
                                if (mapOffsetX.exists(diffuseMapId)) tmf.offsetX = mapOffsetX.get(diffuseMapId);
                                if (mapOffsetY.exists(diffuseMapId)) tmf.offsetY = mapOffsetY.get(diffuseMapId);
                            }
                            sFilters.push(tmf);
                        }
                    }

                    if (diffuseColor != null && diffuseTex == null) {
                        sFilters.push(new flare.materials.filters.ColorFilter(diffuseColor));
                    } else if (diffuseTex == null && reflectionTex == null) {
                        sFilters.push(new flare.materials.filters.ColorFilter(0x969696));
                    }



                    if (bumpTex != null) {

                        sFilters.push(new flare.materials.filters.NormalMapFilter(bumpTex));

                    }

                    if (specularTex != null) {

                        sFilters.push(new flare.materials.filters.SpecularMapFilter(specularTex));

                    }

                    if (hasSpecular) {

                        sFilters.push(new flare.materials.filters.SpecularFilter(specGlossiness, specLevel / 100.0));

                    }

                    if (reflectionTex != null) {

                        if (reflectionTex.type == Texture3D.TYPE_CUBE) {

                            sFilters.push(new flare.materials.filters.CubeMapFilter(reflectionTex, reflectionLevel));

                        } else {

                            sFilters.push(new flare.materials.filters.EnvironmentMapFilter(reflectionTex));

                        }

                    }

                    if (lightMapTex != null) {

                        sFilters.push(new flare.materials.filters.LightMapFilter(lightMapTex));

                    }

                    sFilters.push(new flare.materials.filters.LightFilter());



                    var isJpg = (diffuseTex != null && diffuseTex.name != null && (StringTools.endsWith(diffuseTex.name.toLowerCase(), ".jpg") || StringTools.endsWith(diffuseTex.name.toLowerCase(), ".jpeg")));

                    var isTransparentXml = (mEl.get("transparent") == "true");



                    var sMat = new Shader3D(mName, sFilters);

                    if (mEl.get("twoSided") == "true" || (mName != null && mName.toLowerCase().indexOf("teapot") != -1) || (url != null && url.toLowerCase().indexOf("teapot") != -1)) sMat.twoSided = true;



                    if (isTransparentXml && !isJpg) {

                        sMat.transparent = true;

                    } else {

                        sMat.transparent = false;

                        sMat.depthWrite = true;

                        sMat.sourceFactor = openfl.display3D.Context3DBlendFactor.ONE;

                        sMat.destFactor = openfl.display3D.Context3DBlendFactor.ZERO;

                    }



                    for (ch in mEl.elements()) {

                        if (ch.nodeName == "shader") {

                            var srcFactor = ch.get("sourceFactor");

                            var destFactor = ch.get("destFactor");

                            var dw = ch.get("depthWrite");

                            if (dw != null) {

                                sMat.depthWrite = (dw != "false");

                            }

                            var cf = ch.get("cullFace");

                            if (cf == "none") {

                                sMat.twoSided = true;

                            } else if (cf == "back") {

                                sMat.cullFace = openfl.display3D.Context3DTriangleFace.BACK;

                                sMat.twoSided = false;

                            } else if (cf == "front") {

                                sMat.cullFace = openfl.display3D.Context3DTriangleFace.FRONT;

                                sMat.twoSided = false;

                            }

                            if (srcFactor == "one" && destFactor == "one") {

                                sMat.sourceFactor = openfl.display3D.Context3DBlendFactor.ONE;

                                sMat.destFactor = openfl.display3D.Context3DBlendFactor.ONE;

                                sMat.depthWrite = false;

                                sMat.twoSided = false;

                            }

                        }

                    }

                    if (isEnv) {

                        sMat.cullFace = openfl.display3D.Context3DTriangleFace.BACK;

                    }

                    matMap.set(mId, sMat);

                    matMap.set(mName, sMat);

                }

            }

        }



        // 3.5 解析 Splines

        var splineMap = new Map<String, flare.core.Spline3D>();

        if (splinesElem != null) {

            for (spEl in splinesElem.elements()) {

                if (spEl.nodeName == "spline") {

                    var sId = spEl.get("id");

                    var isClosed = spEl.get("closed") == "true";

                    var streamStr = spEl.get("stream");

                    if (streamStr != null && streamStr != "") {

                        var spline = new flare.core.Spline3D();

                        spline.closed = isClosed;

                        var parts = streamStr.split(",");

                        var numFloats = parts.length;

                        var i = 0;

                        while (i + 8 < numFloats) {

                            var pX = Std.parseFloat(parts[i]);

                            var pY = Std.parseFloat(parts[i + 1]);

                            var pZ = Std.parseFloat(parts[i + 2]);



                            var inX = Std.parseFloat(parts[i + 3]);

                            var inY = Std.parseFloat(parts[i + 4]);

                            var inZ = Std.parseFloat(parts[i + 5]);



                            var outX = Std.parseFloat(parts[i + 6]);

                            var outY = Std.parseFloat(parts[i + 7]);

                            var outZ = Std.parseFloat(parts[i + 8]);



                            var knot = new flare.core.Knot3D(pX, pY, pZ);

                            knot.inVec.setTo(inX - pX, inY - pY, inZ - pZ);

                            knot.outVec.setTo(outX - pX, outY - pY, outZ - pZ);

                            spline.knots.push(knot);



                            i += 9;

                        }

                        splineMap.set(sId, spline);

                    }

                }

            }

        }



        // 4. 解析 Nodes

        var nodeMap = new Map<String, Pivot3D>();

        var boneIdSet = new Map<String, Bool>();

        if (skinInfo != null && skinInfo.boneIds != null) {

            var bArr:Array<String> = skinInfo.boneIds;

            for (bId in bArr) boneIdSet.set(bId, true);

        }



        function parseNode(nodeEl:Xml, parentPivot:Pivot3D):Pivot3D {

            var nId = nodeEl.get("id");

            var nName = nodeEl.get("name");

            if (nName == null || nName == "") nName = "node_" + nId;

            var nType = nodeEl.get("type");



            var pivot:Pivot3D;

            var surfIdStr = nodeEl.get("surfaces");

            var surfIds = surfIdStr != null ? surfIdStr.split(",") : [];

            var isBoneNode = boneIdSet.exists(nId) || StringTools.startsWith(nName, "CATRig");



            if (nType == "mesh" && surfIds.length > 0 && !isBoneNode) {

                var mesh = new Mesh3D(nName);

                var matIdStr = nodeEl.get("materials");

                var matIds = matIdStr != null ? matIdStr.split(",") : [];

                for (sIdx in 0...surfIds.length) {

                    var sId = surfIds[sIdx];

                    var sTrim = StringTools.trim(sId);

                    if (surfaceMap.exists(sTrim)) {

                        var surf = surfaceMap.get(sTrim);

                        var mId = (sIdx < matIds.length) ? StringTools.trim(matIds[sIdx]) : null;

                        var mat = (mId != null && matMap.exists(mId)) ? matMap.get(mId) : null;

                        if (mat == null) {

                            mat = new Shader3D(nName + "_mat_" + sTrim, [

                                firstTex != null ? new flare.materials.filters.TextureMapFilter(firstTex) : new flare.materials.filters.ColorFilter(0xbbbbbb),

                                new flare.materials.filters.LightFilter()

                            ]);

                            mat.twoSided = false;

                        }

                        mesh.addSurface(surf, mat);

                    }

                }

                pivot = mesh;

                var minStr = nodeEl.get("min");

                var maxStr = nodeEl.get("max");

                if (minStr != null && maxStr != null) {

                    var minP = minStr.split(",");

                    var maxP = maxStr.split(",");

                    if (minP.length >= 3 && maxP.length >= 3) {

                        var minX = Std.parseFloat(minP[0]);

                        var minY = Std.parseFloat(minP[1]);

                        var minZ = Std.parseFloat(minP[2]);

                        var maxX = Std.parseFloat(maxP[0]);

                        var maxY = Std.parseFloat(maxP[1]);

                        var maxZ = Std.parseFloat(maxP[2]);

                        mesh.bounds = new flare.core.Boundings3D();

                        mesh.bounds.update(minX, minY, minZ, maxX, maxY, maxZ);

                        var radStr = nodeEl.get("radius");

                        if (radStr != null) {

                            var rVal = Std.parseFloat(radStr);

                            if (rVal > 0) mesh.bounds.radius = rVal;

                        }

                    }

                }

            } else if (nType == "shape") {

                var shape = new flare.core.Shape3D(nName);

                var spIdsStr = nodeEl.get("splines");

                if (spIdsStr != null && spIdsStr != "") {

                    var spIds = spIdsStr.split(",");

                    for (spId in spIds) {

                        var trimmed = StringTools.trim(spId);

                        if (splineMap.exists(trimmed)) {

                            shape.splines.push(splineMap.get(trimmed));

                        }

                    }

                }

                var colStr = nodeEl.get("color");

                if (colStr != null) {

                    var cp = colStr.split(",");

                    if (cp.length >= 3) {

                        var cr = Std.int(Std.parseFloat(cp[0]));

                        var cg = Std.int(Std.parseFloat(cp[1]));

                        var cb = Std.int(Std.parseFloat(cp[2]));

                        shape.color = (cr << 16) | (cg << 8) | cb;

                    }

                }

                pivot = shape;

            } else if (nType == "light") {

                var lClass = nodeEl.get("class");

                var lType = (lClass == "point" || lClass == "POINT") ? flare.core.Light3D.POINT : flare.core.Light3D.DIRECTIONAL;

                var light = new flare.core.Light3D(nName, lType);

                var colStr = nodeEl.get("color");

                if (colStr != null) {

                    var cp = colStr.split(",");

                    if (cp.length >= 3) {

                        light.color.setTo(Std.parseFloat(cp[0]) / 255.0, Std.parseFloat(cp[1]) / 255.0, Std.parseFloat(cp[2]) / 255.0);

                    }

                }

                var multStr = nodeEl.get("multiplier");

                if (multStr != null) light.multiplier = Std.parseFloat(multStr);

                var rStr = nodeEl.get("farAttenEnd");

                if (rStr != null) light.radius = Std.parseFloat(rStr);

                var enStr = nodeEl.get("enabled");

                if (enStr == "false") light.visible = false;

                if (scene != null && scene.lights != null) {
                    if (scene.lights.list.indexOf(light) == -1) {
                        scene.lights.list.push(light);
                    }
                }

                pivot = light;

            } else if (nType == "camera") {

                var cam = new flare.core.Camera3D(nName);

                var fovStr = nodeEl.get("fov");

                if (fovStr != null) cam.fov = Std.parseFloat(fovStr);

                var nearStr = nodeEl.get("nearclip");

                if (nearStr != null) cam.near = Std.parseFloat(nearStr);

                var farStr = nodeEl.get("farclip");

                if (farStr != null) cam.far = Std.parseFloat(farStr);

                var activeStr = nodeEl.get("active");

                if (activeCamera == null || activeStr == "true") {

                    activeCamera = cam;

                    cameraElem = nodeEl;

                }

                pivot = cam;

            } else {

                pivot = new Pivot3D(nName);

            }



            var transStr = nodeEl.get("transform");

            if (transStr != null) {

                var parts = transStr.split(",");

                if (parts.length >= 12) {

                    var raw = new openfl.Vector<Float>(16);

                    raw[0] = Std.parseFloat(parts[0]);

                    raw[1] = Std.parseFloat(parts[1]);

                    raw[2] = Std.parseFloat(parts[2]);

                    raw[3] = 0.0;



                    raw[4] = Std.parseFloat(parts[3]);

                    raw[5] = Std.parseFloat(parts[4]);

                    raw[6] = Std.parseFloat(parts[5]);

                    raw[7] = 0.0;



                    raw[8] = Std.parseFloat(parts[6]);

                    raw[9] = Std.parseFloat(parts[7]);

                    raw[10] = Std.parseFloat(parts[8]);

                    raw[11] = 0.0;



                    raw[12] = Std.parseFloat(parts[9]);

                    raw[13] = Std.parseFloat(parts[10]);

                    raw[14] = Std.parseFloat(parts[11]);

                    raw[15] = 1.0;

                    pivot.transform.copyRawDataFrom(raw);

                    pivot.setTransform(pivot.transform);

                }

            }



            var animId = nodeEl.get("animation");

            if (animId != null && animMap.exists(animId)) {

                var frames = animMap.get(animId);

                pivot.frames = frames;

                pivot.totalFrames = frames.length;

                pivot.isPlaying = true;

            }



            nodeMap.set(nId, pivot);

            if (parentPivot != null) {

                parentPivot.addChild(pivot);

            }



            for (chEl in nodeEl.elements()) {

                if (chEl.nodeName == "node") {

                    parseNode(chEl, pivot);

                }

            }



            return pivot;

        }



        if (nodesElem != null) {

            for (nEl in nodesElem.elements()) {

                if (nEl.nodeName == "node") {

                    var topNode = parseNode(nEl, null);

                    this.addChild(topNode);

                }

            }

        }



        this.world.identity();
        this.updateTransforms(true);



        // 5. 绑定骨骼蒙皮

        if (skinInfo != null && skinInfo.targetId != null && nodeMap.exists(skinInfo.targetId)) {

            var targetPivot = nodeMap.get(skinInfo.targetId);

            if (Std.isOfType(targetPivot, Mesh3D)) {

                var targetMesh:Mesh3D = cast targetPivot;

                var skinMod = new flare.modifiers.SkinModifier(targetMesh);

                var boneIds:Array<String> = skinInfo.boneIds;

                var invMap:Map<String, Matrix3D> = skinInfo.invMap;



                for (bIdStr in boneIds) {

                    var bonePivot = nodeMap.get(bIdStr);

                    if (bonePivot != null) {

                        var invM:Matrix3D = (invMap != null && invMap.exists(bIdStr)) ? invMap.get(bIdStr) : null;

                        if (invM == null) {

                            var invBoneWorld = new Matrix3D();

                            invBoneWorld.copyFrom(bonePivot.world);

                            invBoneWorld.invert();

                            invM = new Matrix3D();

                            invM.copyFrom(targetMesh.world);

                            invM.append(invBoneWorld);

                        }

                        skinMod.addBone(bonePivot, invM);

                    }

                }



                if (skinInfo.wBytes != null && targetMesh.surfaces.length > 0) {

                    var wBa = ByteArray.fromBytes(skinInfo.wBytes);

                    wBa.endian = Endian.LITTLE_ENDIAN;

                    var surf0 = targetMesh.surfaces[0];

                    var numVerts = Std.int(surf0.vertexVector.length / 8);

                    var bpv:Int = (skinInfo.bonesPerVertex != null) ? skinInfo.bonesPerVertex : 4;



                    skinMod.numVertices = numVerts;

                    skinMod.origPositions = new openfl.Vector<Float>(numVerts * 3);

                    skinMod.origNormals = new openfl.Vector<Float>(numVerts * 3);

                    skinMod.weights = new openfl.Vector<Float>(numVerts * bpv);

                    skinMod.boneIndices = new openfl.Vector<Int>(numVerts * bpv);



                    var vVec = surf0.vertexVector;

                    for (i in 0...numVerts) {

                        skinMod.origPositions[i * 3 + 0] = vVec[i * 8 + 0];

                        skinMod.origPositions[i * 3 + 1] = vVec[i * 8 + 1];

                        skinMod.origPositions[i * 3 + 2] = vVec[i * 8 + 2];



                        skinMod.origNormals[i * 3 + 0] = vVec[i * 8 + 5];

                        skinMod.origNormals[i * 3 + 1] = vVec[i * 8 + 6];

                        skinMod.origNormals[i * 3 + 2] = vVec[i * 8 + 7];



                        for (k in 0...bpv) {

                            skinMod.weights[i * bpv + k] = (wBa.bytesAvailable >= 4) ? wBa.readFloat() : (k == 0 ? 1.0 : 0.0);

                        }

                        for (k in 0...bpv) {

                            var j = (wBa.bytesAvailable >= 4) ? wBa.readFloat() : 0.0;

                            var jointIdx = Std.int(Math.round(j / 3.0));

                            if (jointIdx < 0) jointIdx = 0;

                            if (jointIdx >= boneIds.length) jointIdx = boneIds.length - 1;

                            skinMod.boneIndices[i * bpv + k] = jointIdx;

                        }

                    }



                    targetMesh.modifier = skinMod;

                } else if (targetMesh.surfaces.length > 0) {

                    var surfPalettes:Array<Array<Int>> = skinInfo.surfPalettes;

                    var hasSkinData = false;



                    for (sIdx in 0...targetMesh.surfaces.length) {

                        var surf = targetMesh.surfaces[sIdx];

                        if (surf.userData == null) continue;

                        var uData:Dynamic = surf.userData;

                        var wVec:openfl.Vector<Float> = uData.weights;

                        var jVec:openfl.Vector<Int> = uData.boneIndices;

                        if (wVec == null || jVec == null) continue;



                        var numVerts = Std.int(surf.vertexVector.length / 8);

                        var origPos = new openfl.Vector<Float>(numVerts * 3);

                        var origNorm = new openfl.Vector<Float>(numVerts * 3);

                        var weights = new openfl.Vector<Float>(numVerts * 2);

                        var boneIndices = new openfl.Vector<Int>(numVerts * 2);



                        var pal = (surfPalettes != null && sIdx < surfPalettes.length) ? surfPalettes[sIdx] : null;



                        var vVec = surf.vertexVector;

                        for (i in 0...numVerts) {

                            origPos[i * 3 + 0] = vVec[i * 8 + 0];

                            origPos[i * 3 + 1] = vVec[i * 8 + 1];

                            origPos[i * 3 + 2] = vVec[i * 8 + 2];



                            origNorm[i * 3 + 0] = vVec[i * 8 + 5];

                            origNorm[i * 3 + 1] = vVec[i * 8 + 6];

                            origNorm[i * 3 + 2] = vVec[i * 8 + 7];



                            var w0 = wVec[i * 2 + 0];

                            var w1 = wVec[i * 2 + 1];

                            var wSum = w0 + w1;

                            if (wSum > 0.000001) {

                                w0 /= wSum;

                                w1 /= wSum;

                            } else {

                                w0 = 1.0; w1 = 0.0;

                            }

                            weights[i * 2 + 0] = w0;

                            weights[i * 2 + 1] = w1;



                            var b0 = jVec[i * 2 + 0];

                            var b1 = jVec[i * 2 + 1];

                            if (pal != null) {

                                if (b0 >= 0 && b0 < pal.length) b0 = pal[b0];

                                if (b1 >= 0 && b1 < pal.length) b1 = pal[b1];

                            }

                            boneIndices[i * 2 + 0] = b0;

                            boneIndices[i * 2 + 1] = b1;

                        }



                        skinMod.addSurfaceSkin(surf, origPos, origNorm, weights, boneIndices, numVerts);

                        hasSkinData = true;

                    }



                    if (hasSkinData) {

                        targetMesh.modifier = skinMod;

                    }

                }

            }

        }



        var maxAnimFrames = 0;

        for (fList in animMap) {

            if (fList.length > maxAnimFrames) maxAnimFrames = fList.length;

        }

        if (maxAnimFrames <= 0) maxAnimFrames = 26;

        this.totalFrames = maxAnimFrames;

        for (c in this.children) {

            c.totalFrames = maxAnimFrames;

        }



        if (skinInfo != null && skinInfo.targetId != null && nodeMap.exists(skinInfo.targetId)) {

            var targetPivot = nodeMap.get(skinInfo.targetId);

            if (Std.isOfType(targetPivot, Mesh3D)) {

                var targetMesh:Mesh3D = cast targetPivot;

                if (targetMesh.modifier != null && Std.isOfType(targetMesh.modifier, flare.modifiers.SkinModifier)) {

                    var skinMod:flare.modifiers.SkinModifier = cast targetMesh.modifier;

                    skinMod.root = this;

                    skinMod.totalFrames = maxAnimFrames;

                    skinMod.prebakeAnimation(maxAnimFrames);

                }

            }

        }



        this.play(true);



        // Adjust camera to frame the model perfectly

        if (url != null && url.toLowerCase().indexOf("planet") != -1) {
            if (scene != null && scene.camera != null) {
                scene.camera.setPosition(83.7196, 179.7592, -238.0426);
                scene.camera.lookAt(0, 0, 0);
                scene.camera.fieldOfView = 75;
                scene.camera.near = 1.0;
                scene.camera.far = 100000;
                if (Std.isOfType(scene, flare.basic.Viewer3D)) {
                    var viewer:flare.basic.Viewer3D = cast scene;
                    viewer.setTarget(0, 0, 0);
                    viewer.syncOrbitFromCamera();
                    viewer.updateCameraOrbit();
                }
            }
        } else if (url != null && url.toLowerCase().indexOf("vaca") != -1) {
            if (scene != null && Std.isOfType(scene, flare.basic.Viewer3D)) {
                var viewer:flare.basic.Viewer3D = cast scene;
                var rad = (35 * Math.PI) / 180;
                var dist = 225.0;
                var cx = dist * Math.cos(rad);
                var cz = dist * Math.sin(rad);
                var cy = 76.0;
                scene.camera.setPosition(cx, cy, cz);
                scene.camera.lookAt(0, 68, 0);
                viewer.setTarget(0, 68, 0);
                viewer.syncOrbitFromCamera();
            }
        } else if (activeCamera != null && activeCamera.name != "Viewport Camera") {
            if (scene != null) {
                scene.camera = activeCamera;
                if (Std.isOfType(scene, flare.basic.Viewer3D)) {
                    var viewer:flare.basic.Viewer3D = cast scene;
                    var cPos = activeCamera.getPosition(false);
                    var cDir = activeCamera.getDir(false);
                    viewer.setTarget(cPos.x + cDir.x * 100, cPos.y + cDir.y * 100, cPos.z + cDir.z * 100);
                    viewer.syncOrbitFromCamera();
                }
            }
        } else if (scene != null && (url == null || (url.toLowerCase().indexOf("axis") == -1 && url.toLowerCase().indexOf("shapes") == -1))) {

            if (Std.isOfType(scene, flare.basic.Viewer3D)) {

                var viewer:flare.basic.Viewer3D = cast scene;

                if (url != null && (url.toLowerCase().indexOf("player") != -1 || url.toLowerCase().indexOf("anim_base") != -1)) {

                    viewer.target.setTo(0, 0.9, 0);

                    viewer.radius = 2.5;

                } else if (url != null && url.toLowerCase().indexOf("astronaut") != -1) {

                    viewer.target.setTo(0, 5.0, 0);

                    viewer.radius = 25.0;

                } else if (url != null && url.toLowerCase().indexOf("vaca") != -1) {

                    viewer.setTarget(0, 68, 0);

                    viewer.syncOrbitFromCamera();

                } else if (url != null && url.toLowerCase().indexOf("elsa") != -1) {

                    viewer.target.setTo(0, 0, 0);

                    scene.camera.setPosition(0, 50, -200);

                    scene.camera.lookAt(0, 0, 0);

                    viewer.syncOrbitFromCamera();

                } else if (url != null && url.toLowerCase().indexOf('chess2') != -1) {
                    viewer.setTarget(47.2708, 54.6733, 43.4656);
                    scene.camera.fieldOfView = 76.7762;
                    scene.camera.near = 10;
                    scene.camera.far = 4000;
                    scene.camera.setPosition(249.724, 76.366, 225.55);
                    scene.camera.lookAt(47.2708, 54.6733, 43.4656);
                    viewer.syncOrbitFromCamera();
                } else if (url != null && url.toLowerCase().indexOf('chess') != -1) {
                    viewer.setTarget(0, 0, 0);
                    scene.camera.fieldOfView = 75;
                    scene.camera.near = 1;
                    scene.camera.far = 100000;
                    scene.camera.setPosition(77.56107330322266, 104.50699615478516, -188.580322265625);
                    scene.camera.lookAt(0, 0, 0);
                    viewer.syncOrbitFromCamera();
                } else if (url != null && url.toLowerCase().indexOf("teapot") != -1) {
                    if (viewer.target == null || viewer.target.length < 0.001) {
                        viewer.setTarget(-4.5, 6.5, 0);
                    }
                    if (scene.camera != null && scene.camera.getPosition(false).length > 0.001) {
                        viewer.syncOrbitFromCamera();
                    } else {
                        scene.camera.setPosition(168.2, 62.2, 161.2);
                        scene.camera.lookAt(viewer.target.x, viewer.target.y, viewer.target.z);
                        viewer.syncOrbitFromCamera();
                    }
                } else if (url != null && url.toLowerCase().indexOf("planet") != -1) {
                    viewer.setTarget(0, 0, 0);
                    scene.camera.setPosition(83.7196, 179.7592, -238.0426);
                    scene.camera.lookAt(0, 0, 0);
                    scene.camera.fieldOfView = 75;
                    scene.camera.near = 1.0;
                    scene.camera.far = 100000;
                    viewer.syncOrbitFromCamera();
                } else if (cameraElem != null && (url == null || url.toLowerCase().indexOf("teapot") == -1)) {
                    var tStr = cameraElem.get("transform");
                    if (tStr != null) {
                        var vals = [for (p in tStr.split(",")) Std.parseFloat(p)];
                        if (vals.length >= 12) {
                            var camX = vals[9];
                            var camY = vals[10];
                            var camZ = vals[11];
                            viewer.setTarget(0, 0, 0);
                            scene.camera.setPosition(camX, camY, camZ);
                            scene.camera.lookAt(0, 0, 0);
                            if (cameraElem.get("fov") != null) scene.camera.fieldOfView = Std.parseFloat(cameraElem.get("fov"));
                            if (cameraElem.get("nearclip") != null) scene.camera.near = Std.parseFloat(cameraElem.get("nearclip"));
                            if (cameraElem.get("farclip") != null) scene.camera.far = Std.parseFloat(cameraElem.get("farclip"));
                            viewer.syncOrbitFromCamera();
                        }
                    }
                }

                viewer.updateCameraOrbit();

            }

        }



        loaded = true;

        var dt = openfl.Lib.getTimer() - _loadStartTime;

        flare.system.DebugLog.log("[PERF] Loaded and parsed zip archive " + url + " in " + dt + " ms (children=" + this.children.length + ")");

        dispatchEvent(new Event(Flare3DLoader.COMPLETE_EVENT));

        if (scene != null) {

            scene.notifyLoadComplete();

        }

    }

}
