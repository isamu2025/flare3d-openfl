package flare.loaders;

import openfl.events.Event;
import openfl.events.ProgressEvent;
import openfl.net.URLLoader;
import openfl.net.URLRequest;
import openfl.Vector;
import openfl.geom.Matrix3D;
import flare.core.Pivot3D;
import flare.core.Camera3D;
import flare.core.Light3D;
import flare.core.Mesh3D;
import flare.core.Surface3D;
import flare.core.Texture3D;
import flare.core.Frame3D;
import flare.materials.Shader3D;
import flare.materials.filters.TextureMapFilter;
import flare.modifiers.Modifier;
import flare.modifiers.SkinModifier;
import flare.system.ILibraryExternalItem;
import flare.system.Library3D;
import flare.basic.Scene3D;

using StringTools;

/**
 * ColladaLoader imports COLLADA (.dae) 3D assets, hierarchies, and animations into Flare3D.
 */
class ColladaLoader extends Pivot3D implements ILibraryExternalItem {
    public var requestTexture:Dynamic -> Void;

    public var bytesLoaded:Float = 0;
    public var bytesTotal:Float = 0;
    public var loaded:Bool = false;
    public var request:URLRequest;

    private var _parent:Pivot3D;
    private var _sceneContext:Scene3D;
    private var _library:Library3D;
    private var _texturesFolder:String;
    private var _flipNormals:Bool;
    private var _cullFace:String;
    private var _loader:URLLoader;

    public var libraryContext(get, never):Library3D;

    public function new(request:Dynamic = null, parent:Pivot3D = null, sceneContext:Scene3D = null, texturesFolder:String = null, flipNormals:Bool = false, cullFace:String = null) {
        var reqName = "collada";
        if (Std.isOfType(request, String)) reqName = cast request;
        super(reqName);

        if (Std.isOfType(request, URLRequest)) {
            this.request = cast request;
        } else if (Std.isOfType(request, String)) {
            this.request = new URLRequest(cast request);
        }
        this._parent = parent;
        this._sceneContext = sceneContext;
        this._texturesFolder = texturesFolder != null ? texturesFolder : "";
        this._flipNormals = flipNormals;
        this._cullFace = cullFace;
        this._library = new Library3D();

        if (parent != null) {
            parent.addChild(this);
        } else if (sceneContext != null) {
            sceneContext.addChild(this);
        }

        if (request != null) {
            load();
        }
    }

    public function load():Void {
        if (loaded) return;

        var urlStr = this.request != null ? this.request.url : "";
        if (urlStr == "") return;

        var content:String = null;

        #if sys
        var progDir = "";
        try {
            var prog = Sys.programPath();
            if (prog != null && prog != "") progDir = haxe.io.Path.directory(prog);
        } catch (e:Dynamic) {}

        var baseName = haxe.io.Path.withoutDirectory(urlStr);
        var possiblePaths = [
            urlStr,
            "assets/" + urlStr,
            "assets/" + baseName,
            "../assets/" + urlStr,
            "../assets/" + baseName
        ];
        if (progDir != "") {
            possiblePaths.push(haxe.io.Path.join([progDir, urlStr]));
            possiblePaths.push(haxe.io.Path.join([progDir, "assets", urlStr]));
            possiblePaths.push(haxe.io.Path.join([progDir, baseName]));
            possiblePaths.push(haxe.io.Path.join([progDir, "assets", baseName]));
        }
        for (p in possiblePaths) {
            if (sys.FileSystem.exists(p)) {
                try {
                    content = sys.io.File.getContent(p);
                    break;
                } catch (e:Dynamic) {}
            }
        }
        #end

        if (content == null) {
            try {
                if (openfl.utils.Assets.exists(urlStr)) {
                    content = openfl.utils.Assets.getText(urlStr);
                } else if (openfl.utils.Assets.exists("assets/" + urlStr)) {
                    content = openfl.utils.Assets.getText("assets/" + urlStr);
                }
            } catch (e:Dynamic) {}
        }

        if (content != null && content.length > 0) {
            parseCollada(content);
            loaded = true;
            dispatchEvent(new Event(Event.COMPLETE));
            if (_sceneContext != null) {
                _sceneContext.notifyLoadComplete();
            }
        } else {
            // Asynchronous fallback (HTML5 / remote)
            _loader = new URLLoader();
            _loader.addEventListener(Event.COMPLETE, function(e:Event) {
                var text:String = _loader.data;
                if (text != null && text.length > 0) {
                    parseCollada(text);
                }
                loaded = true;
                dispatchEvent(new Event(Event.COMPLETE));
                if (_sceneContext != null) {
                    _sceneContext.notifyLoadComplete();
                }
            });
            _loader.addEventListener(openfl.events.IOErrorEvent.IO_ERROR, function(e:Dynamic) {
                if (!StringTools.startsWith(urlStr, "assets/")) {
                    var loader2 = new URLLoader();
                    loader2.addEventListener(Event.COMPLETE, function(e2:Event) {
                        var text2:String = loader2.data;
                        if (text2 != null && text2.length > 0) {
                            parseCollada(text2);
                        }
                        loaded = true;
                        dispatchEvent(new Event(Event.COMPLETE));
                        if (_sceneContext != null) {
                            _sceneContext.notifyLoadComplete();
                        }
                    });
                    loader2.addEventListener(openfl.events.IOErrorEvent.IO_ERROR, function(e2:Dynamic) {
                        loaded = true;
                        if (_sceneContext != null) _sceneContext.notifyLoadComplete();
                    });
                    loader2.load(new URLRequest("assets/" + urlStr));
                } else {
                    loaded = true;
                    if (_sceneContext != null) _sceneContext.notifyLoadComplete();
                }
            });
            _loader.load(this.request);
        }
    }

    private static function findElements(xml:Xml, localName:String, out:Array<Xml>):Void {
        for (node in xml) {
            if (node.nodeType == Xml.Element) {
                var name = node.nodeName;
                var colon = name.indexOf(":");
                if (colon != -1) name = name.substr(colon + 1);
                if (name == localName) {
                    out.push(node);
                }
                findElements(node, localName, out);
            }
        }
    }

    private static function transposeColladaMatrix(c:Array<Float>):openfl.Vector<Float> {
        var out = new openfl.Vector<Float>(16);
        if (c == null || c.length < 16) return out;
        out[0] = c[0];  out[4] = c[1];  out[8]  = c[2];  out[12] = c[3];
        out[1] = c[4];  out[5] = c[5];  out[9]  = c[6];  out[13] = c[7];
        out[2] = c[8];  out[6] = c[9];  out[10] = c[10]; out[14] = c[11];
        out[3] = c[12]; out[7] = c[13]; out[11] = c[14]; out[15] = c[15];
        return out;
    }

    private function parseCollada(xmlText:String):Void {
        try {
            var xml = Xml.parse(xmlText);

            // 1. Find images
            var imageNodes:Array<Xml> = [];
            findElements(xml, "image", imageNodes);
            var texturePath:String = null;
            for (img in imageNodes) {
                var initFrom:Array<Xml> = [];
                findElements(img, "init_from", initFrom);
                if (initFrom.length > 0 && initFrom[0].firstChild() != null) {
                    texturePath = initFrom[0].firstChild().nodeValue.trim();
                    break;
                }
            }

            // 2. Map all sources (float_array and Name_array)
            var sourceNodes:Array<Xml> = [];
            findElements(xml, "source", sourceNodes);
            var sourceMap:Map<String, Array<Float>> = new Map();
            var sourceNameMap:Map<String, Array<String>> = new Map();
            for (src in sourceNodes) {
                var sid = src.get("id");
                if (sid == null) continue;
                var faNodes:Array<Xml> = [];
                findElements(src, "float_array", faNodes);
                if (faNodes.length > 0 && faNodes[0].firstChild() != null) {
                    var raw = ~/[\s\r\n]+/g.split(faNodes[0].firstChild().nodeValue.trim());
                    var arr:Array<Float> = [];
                    for (s in raw) {
                        if (s.length > 0) arr.push(Std.parseFloat(s));
                    }
                    sourceMap.set(sid, arr);
                }
                var naNodes:Array<Xml> = [];
                findElements(src, "Name_array", naNodes);
                if (naNodes.length > 0 && naNodes[0].firstChild() != null) {
                    var raw = ~/[\s\r\n]+/g.split(naNodes[0].firstChild().nodeValue.trim());
                    var arr:Array<String> = [];
                    for (s in raw) {
                        if (s.length > 0) arr.push(s);
                    }
                    sourceNameMap.set(sid, arr);
                }
            }

            // 3. Map vertices
            var verticesNodes:Array<Xml> = [];
            findElements(xml, "vertices", verticesNodes);
            var vertexToPosSource:Map<String, String> = new Map();
            for (vNode in verticesNodes) {
                var vid = vNode.get("id");
                var inps:Array<Xml> = [];
                findElements(vNode, "input", inps);
                for (inp in inps) {
                    if (inp.get("semantic") == "POSITION") {
                        var s = inp.get("source");
                        if (s != null) vertexToPosSource.set(vid, s.replace("#", ""));
                    }
                }
            }

            // 4. Parse Visual Scenes (Bones and Scene Nodes)
            var nodeMap:Map<String, Pivot3D> = new Map();
            var rootBones:Array<Pivot3D> = [];

            function parseSceneNode(nodeXml:Xml, parentPivot:Pivot3D):Void {
                var nid = nodeXml.get("id");
                var name = nodeXml.get("name");
                var sid = nodeXml.get("sid");
                var nType = nodeXml.get("type");

                var pivotName = (name != null) ? name : ((nid != null) ? nid : "node");
                var pivot = new Pivot3D(pivotName);

                if (nid != null) nodeMap.set(nid, pivot);
                if (name != null && !nodeMap.exists(name)) nodeMap.set(name, pivot);
                if (sid != null && !nodeMap.exists(sid)) nodeMap.set(sid, pivot);

                for (c in nodeXml) {
                    if (c.nodeType == Xml.Element) {
                        var cName = c.nodeName;
                        var colon = cName.indexOf(":");
                        if (colon != -1) cName = cName.substr(colon + 1);
                        if (cName == "matrix" && c.firstChild() != null) {
                            var raw = ~/[\s\r\n]+/g.split(c.firstChild().nodeValue.trim());
                            var cArr:Array<Float> = [];
                            for (s in raw) if (s.length > 0) cArr.push(Std.parseFloat(s));
                            if (cArr.length == 16) {
                                var openflVec = transposeColladaMatrix(cArr);
                                pivot.matrix.copyFrom(new Matrix3D(openflVec));
                            }
                        }
                    }
                }

                if (parentPivot != null) {
                    parentPivot.addChild(pivot);
                } else {
                    var hasInstance = false;
                    for (c in nodeXml) {
                        if (c.nodeType == Xml.Element) {
                            var cName = c.nodeName;
                            var colon = cName.indexOf(":");
                            if (colon != -1) cName = cName.substr(colon + 1);
                            if (cName == "instance_geometry" || cName == "instance_controller") {
                                hasInstance = true;
                                break;
                            }
                        }
                    }
                    if (!hasInstance || nType == "JOINT") {
                        rootBones.push(pivot);
                    }
                }

                for (c in nodeXml) {
                    if (c.nodeType == Xml.Element) {
                        var cName = c.nodeName;
                        var colon = cName.indexOf(":");
                        if (colon != -1) cName = cName.substr(colon + 1);
                        if (cName == "node") {
                            parseSceneNode(c, pivot);
                        }
                    }
                }
            }

            var vsNodes:Array<Xml> = [];
            findElements(xml, "visual_scene", vsNodes);
            for (vs in vsNodes) {
                for (c in vs) {
                    if (c.nodeType == Xml.Element) {
                        var cName = c.nodeName;
                        var colon = cName.indexOf(":");
                        if (colon != -1) cName = cName.substr(colon + 1);
                        if (cName == "node") {
                            parseSceneNode(c, null);
                        }
                    }
                }
            }
            for (rb in rootBones) {
                this.addChild(rb);
            }

            // 5. Parse Animations
            var animNodes:Array<Xml> = [];
            findElements(xml, "animation", animNodes);
            var maxAnimFrames:Int = 0;

            for (anim in animNodes) {
                var chNodes:Array<Xml> = [];
                findElements(anim, "channel", chNodes);
                if (chNodes.length == 0) continue;

                var target = chNodes[0].get("target");
                if (target == null) continue;
                var targetBoneId = target.indexOf("/") != -1 ? target.split("/")[0] : target;
                var bonePivot = nodeMap.get(targetBoneId);
                if (bonePivot == null) continue;

                var samplerSource = chNodes[0].get("source");
                if (samplerSource == null) continue;
                var samplerId = samplerSource.replace("#", "");

                var samplers:Array<Xml> = [];
                findElements(anim, "sampler", samplers);
                var samplerXml:Xml = null;
                for (s in samplers) {
                    if (s.get("id") == samplerId) { samplerXml = s; break; }
                }
                if (samplerXml == null && samplers.length > 0) samplerXml = samplers[0];
                if (samplerXml == null) continue;

                var outputSourceId:String = null;
                var inps:Array<Xml> = [];
                findElements(samplerXml, "input", inps);
                for (inp in inps) {
                    if (inp.get("semantic") == "OUTPUT") {
                        outputSourceId = inp.get("source").replace("#", "");
                        break;
                    }
                }
                if (outputSourceId == null || !sourceMap.exists(outputSourceId)) continue;

                var outputFloats = sourceMap.get(outputSourceId);
                var numFrames = Std.int(outputFloats.length / 16);
                if (numFrames <= 0) continue;
                if (numFrames > maxAnimFrames) maxAnimFrames = numFrames;

                var framesVec = new openfl.Vector<Frame3D>(numFrames);
                for (f in 0...numFrames) {
                    var cArr = outputFloats.slice(f * 16, (f + 1) * 16);
                    var openflVec = transposeColladaMatrix(cArr);
                    framesVec[f] = new Frame3D(openflVec, Frame3D.TYPE_FRAME);
                }
                bonePivot.frames = framesVec;
                bonePivot.totalFrames = numFrames;
                bonePivot.isPlaying = true;
            }

            // 6. Parse Controllers (Skin Bindings, Inverse Bind Matrices & Weights)
            var geomControllerMap:Map<String, {
                jointNames: Array<String>,
                invMatrices: Array<Matrix3D>,
                meshWeight0: Array<Float>,
                meshWeight1: Array<Float>,
                meshBone0: Array<Int>,
                meshBone1: Array<Int>
            }> = new Map();

            var ctrlNodes:Array<Xml> = [];
            findElements(xml, "controller", ctrlNodes);
            for (ctrl in ctrlNodes) {
                var skinNodes:Array<Xml> = [];
                findElements(ctrl, "skin", skinNodes);
                if (skinNodes.length == 0) continue;
                var skin = skinNodes[0];
                var skinSource = skin.get("source");
                if (skinSource == null) continue;
                var geomId = skinSource.replace("#", "");

                var jointsNodes:Array<Xml> = [];
                findElements(skin, "joints", jointsNodes);
                if (jointsNodes.length == 0) continue;
                var jointNameSrcId:String = null;
                var invMatSrcId:String = null;
                var jInps:Array<Xml> = [];
                findElements(jointsNodes[0], "input", jInps);
                for (inp in jInps) {
                    var sem = inp.get("semantic");
                    var src = inp.get("source").replace("#", "");
                    if (sem == "JOINT") jointNameSrcId = src;
                    else if (sem == "INV_BIND_MATRIX") invMatSrcId = src;
                }

                var jointNames = (jointNameSrcId != null && sourceNameMap.exists(jointNameSrcId)) ? sourceNameMap.get(jointNameSrcId) : [];
                var invFloats = (invMatSrcId != null && sourceMap.exists(invMatSrcId)) ? sourceMap.get(invMatSrcId) : [];
                var invMatrices:Array<Matrix3D> = [];
                var numInv = Std.int(invFloats.length / 16);
                for (j in 0...numInv) {
                    var cArr = invFloats.slice(j * 16, (j + 1) * 16);
                    var openflVec = transposeColladaMatrix(cArr);
                    invMatrices.push(new Matrix3D(openflVec));
                }

                var vwNodes:Array<Xml> = [];
                findElements(skin, "vertex_weights", vwNodes);
                if (vwNodes.length == 0) continue;
                var vw = vwNodes[0];

                var weightSrcId:String = null;
                var jOff = 0;
                var wOff = 1;
                var vwStride = 2;
                var vwInps:Array<Xml> = [];
                findElements(vw, "input", vwInps);
                for (inp in vwInps) {
                    var sem = inp.get("semantic");
                    var off = Std.parseInt(inp.get("offset"));
                    if (off + 1 > vwStride) vwStride = off + 1;
                    if (sem == "JOINT") jOff = off;
                    else if (sem == "WEIGHT") {
                        wOff = off;
                        weightSrcId = inp.get("source").replace("#", "");
                    }
                }

                var weightFloats = (weightSrcId != null && sourceMap.exists(weightSrcId)) ? sourceMap.get(weightSrcId) : [1.0];

                var vcNodes:Array<Xml> = [];
                findElements(vw, "vcount", vcNodes);
                var vcounts:Array<Int> = [];
                if (vcNodes.length > 0 && vcNodes[0].firstChild() != null) {
                    var raw = ~/[\s\r\n]+/g.split(vcNodes[0].firstChild().nodeValue.trim());
                    for (s in raw) if (s.length > 0) vcounts.push(Std.parseInt(s));
                }

                var vNodes:Array<Xml> = [];
                findElements(vw, "v", vNodes);
                var vIndices:Array<Int> = [];
                if (vNodes.length > 0 && vNodes[0].firstChild() != null) {
                    var raw = ~/[\s\r\n]+/g.split(vNodes[0].firstChild().nodeValue.trim());
                    for (s in raw) if (s.length > 0) vIndices.push(Std.parseInt(s));
                }

                var numPosVerts = vcounts.length;
                var meshWeight0:Array<Float> = [];
                var meshWeight1:Array<Float> = [];
                var meshBone0:Array<Int> = [];
                var meshBone1:Array<Int> = [];

                var vCursor = 0;
                for (pv in 0...numPosVerts) {
                    var cnt = vcounts[pv];
                    var bestJ0 = 0; var bestW0:Float = 0.0;
                    var bestJ1 = 0; var bestW1:Float = 0.0;

                    for (k in 0...cnt) {
                        var jIdx = vIndices[vCursor + jOff];
                        var wIdx = vIndices[vCursor + wOff];
                        vCursor += vwStride;
                        var wVal = (wIdx >= 0 && wIdx < weightFloats.length) ? weightFloats[wIdx] : 0.0;
                        if (wVal > bestW0) {
                            bestW1 = bestW0; bestJ1 = bestJ0;
                            bestW0 = wVal; bestJ0 = jIdx;
                        } else if (wVal > bestW1) {
                            bestW1 = wVal; bestJ1 = jIdx;
                        }
                    }

                    var sum = bestW0 + bestW1;
                    if (sum > 0.000001) {
                        bestW0 /= sum;
                        bestW1 /= sum;
                    } else {
                        bestW0 = 1.0; bestW1 = 0.0;
                    }
                    meshWeight0.push(bestW0);
                    meshWeight1.push(bestW1);
                    meshBone0.push(bestJ0);
                    meshBone1.push(bestJ1);
                }

                geomControllerMap.set(geomId, {
                    jointNames: jointNames,
                    invMatrices: invMatrices,
                    meshWeight0: meshWeight0,
                    meshWeight1: meshWeight1,
                    meshBone0: meshBone0,
                    meshBone1: meshBone1
                });
            }

            // 7. Resolve Texture & Material
            var tex3D:Texture3D = null;
            if (texturePath != null) {
                var baseName = haxe.io.Path.withoutDirectory(texturePath);
                var daeDir = (this.request != null && this.request.url != null) ? haxe.io.Path.directory(this.request.url) : "";
                var testPaths = [
                    texturePath,
                    "assets/" + texturePath,
                    "textures/" + baseName,
                    "assets/textures/" + baseName,
                    _texturesFolder + baseName,
                    _texturesFolder + texturePath,
                    "../assets/" + texturePath,
                    "../assets/textures/" + baseName
                ];
                if (daeDir != "") {
                    testPaths.push(haxe.io.Path.join([daeDir, texturePath]));
                    testPaths.push(haxe.io.Path.join([daeDir, "textures", baseName]));
                    testPaths.push(haxe.io.Path.join([daeDir, baseName]));
                }
                #if sys
                var progDir = "";
                try {
                    var prog = Sys.programPath();
                    if (prog != null && prog != "") progDir = haxe.io.Path.directory(prog);
                } catch (e:Dynamic) {}
                if (progDir != "") {
                    testPaths.push(haxe.io.Path.join([progDir, texturePath]));
                    testPaths.push(haxe.io.Path.join([progDir, "textures", baseName]));
                    testPaths.push(haxe.io.Path.join([progDir, "assets", texturePath]));
                    testPaths.push(haxe.io.Path.join([progDir, "assets", "textures", baseName]));
                }
                for (tp in testPaths) {
                    if (sys.FileSystem.exists(tp)) {
                        tex3D = (_sceneContext != null) ? _sceneContext.addTextureFromFile(tp) : new Texture3D(tp);
                        break;
                    }
                }
                #else
                for (tp in testPaths) {
                    if (openfl.utils.Assets.exists(tp)) {
                        tex3D = (_sceneContext != null) ? _sceneContext.addTextureFromFile(tp) : new Texture3D(tp);
                        break;
                    }
                }
                #end
                if (tex3D == null) {
                    tex3D = (_sceneContext != null) ? _sceneContext.addTextureFromFile(texturePath) : new Texture3D(texturePath);
                }
            }

            var mat:Shader3D = null;
            if (tex3D != null) {
                mat = new Shader3D("colladaMat", [new TextureMapFilter(tex3D)]);
            } else {
                mat = new Shader3D("colladaMat", [new TextureMapFilter()]);
            }
            mat.twoSided = true;
            mat.build();

            // 8. Parse Geometries
            var geomNodes:Array<Xml> = [];
            findElements(xml, "geometry", geomNodes);

            for (geom in geomNodes) {
                var gId = geom.get("id");
                var gName = geom.get("name") != null ? geom.get("name") : gId;
                var mesh = new Mesh3D(gName);

                var ctrlData = (gId != null && geomControllerMap.exists(gId)) ? geomControllerMap.get(gId) : null;
                var skinMod:SkinModifier = null;
                if (ctrlData != null) {
                    skinMod = new SkinModifier(mesh);
                    for (j in 0...ctrlData.jointNames.length) {
                        var bName = ctrlData.jointNames[j];
                        var bPivot = nodeMap.get(bName);
                        if (bPivot == null) bPivot = this;
                        var invM = (j < ctrlData.invMatrices.length) ? ctrlData.invMatrices[j] : null;
                        skinMod.addBone(bPivot, invM);
                    }
                }

                var polys:Array<Xml> = [];
                findElements(geom, "polylist", polys);
                findElements(geom, "triangles", polys);
                findElements(geom, "polygons", polys);

                for (poly in polys) {
                    var inps:Array<Xml> = [];
                    findElements(poly, "input", inps);

                    var posSourceId:String = null;
                    var normSourceId:String = null;
                    var uvSourceId:String = null;
                    var posOffset:Int = 0;
                    var normOffset:Int = -1;
                    var uvOffset:Int = -1;
                    var stride:Int = 0;

                    for (inp in inps) {
                        var sem = inp.get("semantic");
                        var src = inp.get("source").replace("#", "");
                        var off = Std.parseInt(inp.get("offset"));
                        if (off >= stride) stride = off + 1;

                        if (sem == "VERTEX") {
                            posOffset = off;
                            posSourceId = vertexToPosSource.exists(src) ? vertexToPosSource.get(src) : src;
                        } else if (sem == "POSITION") {
                            posOffset = off;
                            posSourceId = src;
                        } else if (sem == "NORMAL") {
                            normOffset = off;
                            normSourceId = src;
                        } else if (sem == "TEXCOORD") {
                            uvOffset = off;
                            uvSourceId = src;
                        }
                    }

                    if (stride == 0) stride = 1;

                    var pNodes:Array<Xml> = [];
                    findElements(poly, "p", pNodes);
                    if (pNodes.length == 0 || pNodes[0].firstChild() == null) continue;

                    var pRaw = ~/[\s\r\n]+/g.split(pNodes[0].firstChild().nodeValue.trim());
                    var indices:Array<Int> = [];
                    for (s in pRaw) {
                        if (s.length > 0) indices.push(Std.parseInt(s));
                    }

                    var posArray = posSourceId != null ? sourceMap.get(posSourceId) : null;
                    var normArray = normSourceId != null ? sourceMap.get(normSourceId) : null;
                    var uvArray = uvSourceId != null ? sourceMap.get(uvSourceId) : null;

                    if (posArray == null) continue;

                    var vcountNodes:Array<Xml> = [];
                    findElements(poly, "vcount", vcountNodes);
                    var vcounts:Array<Int> = [];
                    if (vcountNodes.length > 0 && vcountNodes[0].firstChild() != null) {
                        var vcRaw = ~/[\s\r\n]+/g.split(vcountNodes[0].firstChild().nodeValue.trim());
                        for (s in vcRaw) {
                            if (s.length > 0) vcounts.push(Std.parseInt(s));
                        }
                    }

                    var surface = new Surface3D(gName + "_surf");
                    var vData = surface.vertexData;
                    var iData = surface.indexData;
                    var outIdx = 0;
                    var vertCache = new Map<String, Int>();

                    var sOrigPos:openfl.Vector<Float> = (ctrlData != null) ? new openfl.Vector<Float>() : null;
                    var sOrigNorm:openfl.Vector<Float> = (ctrlData != null) ? new openfl.Vector<Float>() : null;
                    var sWeights:openfl.Vector<Float> = (ctrlData != null) ? new openfl.Vector<Float>() : null;
                    var sBones:openfl.Vector<Int> = (ctrlData != null) ? new openfl.Vector<Int>() : null;

                    var emitVertex = function(indexCursor:Int):Int {
                        var pIdx = indices[indexCursor + posOffset];
                        var nIdx = (normOffset != -1) ? indices[indexCursor + normOffset] : -1;
                        var uvIdx = (uvOffset != -1) ? indices[indexCursor + uvOffset] : -1;
                        var vKey = pIdx + "_" + nIdx + "_" + uvIdx;
                        if (vertCache.exists(vKey)) return vertCache.get(vKey);

                        var px = posArray[pIdx * 3];
                        var py = posArray[pIdx * 3 + 1];
                        var pz = posArray[pIdx * 3 + 2];

                        var nx:Float = 0.0, ny:Float = 1.0, nz:Float = 0.0;
                        if (normOffset != -1 && normArray != null && nIdx != -1) {
                            nx = normArray[nIdx * 3];
                            ny = normArray[nIdx * 3 + 1];
                            nz = normArray[nIdx * 3 + 2];
                        }

                        var u:Float = 0.0, v:Float = 0.0;
                        if (uvOffset != -1 && uvArray != null && uvIdx != -1) {
                            u = uvArray[uvIdx * 2];
                            v = 1.0 - uvArray[uvIdx * 2 + 1];
                        }

                        vData.push(px);
                        vData.push(py);
                        vData.push(pz);
                        vData.push(u);
                        vData.push(v);
                        vData.push(nx);
                        vData.push(ny);
                        vData.push(nz);

                        if (ctrlData != null) {
                            sOrigPos.push(px);
                            sOrigPos.push(py);
                            sOrigPos.push(pz);
                            sOrigNorm.push(nx);
                            sOrigNorm.push(ny);
                            sOrigNorm.push(nz);
                            if (pIdx >= 0 && pIdx < ctrlData.meshWeight0.length) {
                                sWeights.push(ctrlData.meshWeight0[pIdx]);
                                sWeights.push(ctrlData.meshWeight1[pIdx]);
                                sBones.push(ctrlData.meshBone0[pIdx]);
                                sBones.push(ctrlData.meshBone1[pIdx]);
                            } else {
                                sWeights.push(1.0);
                                sWeights.push(0.0);
                                sBones.push(0);
                                sBones.push(0);
                            }
                        }

                        var resIdx = outIdx;
                        vertCache.set(vKey, resIdx);
                        outIdx++;
                        return resIdx;
                    };

                    if (vcounts.length > 0) {
                        var cursor = 0;
                        for (vc in vcounts) {
                            if (vc == 3) {
                                var idx0 = emitVertex(cursor);
                                var idx1 = emitVertex(cursor + stride);
                                var idx2 = emitVertex(cursor + stride * 2);
                                iData.push(idx0);
                                iData.push(idx1);
                                iData.push(idx2);
                                cursor += stride * 3;
                            } else if (vc == 4) {
                                var idx0 = emitVertex(cursor);
                                var idx1 = emitVertex(cursor + stride);
                                var idx2 = emitVertex(cursor + stride * 2);
                                var idx3 = emitVertex(cursor + stride * 3);
                                iData.push(idx0);
                                iData.push(idx1);
                                iData.push(idx2);
                                iData.push(idx0);
                                iData.push(idx2);
                                iData.push(idx3);
                                cursor += stride * 4;
                            } else if (vc > 4) {
                                var polyVerts:Array<Int> = [];
                                for (p in 0...vc) {
                                    polyVerts.push(emitVertex(cursor + stride * p));
                                }
                                for (p in 1...(vc - 1)) {
                                    iData.push(polyVerts[0]);
                                    iData.push(polyVerts[p]);
                                    iData.push(polyVerts[p + 1]);
                                }
                                cursor += stride * vc;
                            }
                        }
                    } else {
                        var k = 0;
                        while (k < indices.length) {
                            var idx0 = emitVertex(k);
                            var idx1 = emitVertex(k + stride);
                            var idx2 = emitVertex(k + stride * 2);
                            iData.push(idx0);
                            iData.push(idx1);
                            iData.push(idx2);
                            k += stride * 3;
                        }
                    }

                    if (skinMod != null && sOrigPos != null) {
                        var nVerts = Std.int(sOrigPos.length / 3);
                        skinMod.addSurfaceSkin(surface, sOrigPos, sOrigNorm, sWeights, sBones, nVerts);
                        surface.isSkinned = true;
                        surface._dirty = false;
                    }

                    surface.material = mat;
                    mesh.addSurface(surface, mat);
                }

                this.addChild(mesh);

                if (skinMod != null && skinMod.surfaceSkins.length > 0) {
                    mesh.modifier = skinMod;
                    skinMod.root = this;
                    skinMod.totalFrames = maxAnimFrames > 0 ? maxAnimFrames : 26;
                }
            }

            this.totalFrames = maxAnimFrames > 0 ? maxAnimFrames : 26;
            this.isPlaying = true;
            this.play(true);
            flare.system.DebugLog.log("[ColladaLoader] Loaded: bones=" + rootBones.length + ", maxFrames=" + this.totalFrames + ", children=" + this.children.length);
        } catch (e:Dynamic) {
            flare.system.DebugLog.log("[ColladaLoader] parse error: " + e);
        }
    }

    public function close():Void {
        if (_loader != null) {
            try { _loader.close(); } catch (e:Dynamic) {}
        }
    }

    override public function dispose():Void {
        close();
        super.dispose();
    }

    public function extract():Void {}
    public function optimizeSurfaces():Void {}
    public function start():Void {}

    public function bindMaterial(node:Dynamic, mesh:Mesh3D):Void {}
    public function bindMaterial3(node:Dynamic, mesh:Mesh3D, technique:Dynamic):Void {}
    public function getAnimation():Void {}
    public function getCamera():Camera3D return new Camera3D();
    public function getController():Modifier return null;
    public function getEffect():Void {}
    public function getGeometry():Vector<Surface3D> return new Vector<Surface3D>();
    public function getImage():Void {}
    public function getLight():Light3D return new Light3D();
    public function getMatrix():Frame3D return new Frame3D();
    public function getNode():Pivot3D return new Pivot3D();
    public function updateController():Void {}

    private function completeEvent(e:Event):Void { dispatchEvent(e); }
    private function resourceCompleteEvent(e:Event):Void {}
    private function resourceProgressEvent(e:ProgressEvent):Void {}

    private function get_libraryContext():Library3D return _library;
}
