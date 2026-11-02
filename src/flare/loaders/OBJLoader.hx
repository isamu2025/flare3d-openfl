package flare.loaders;

import openfl.Vector;
import openfl.events.Event;
import openfl.net.URLLoader;
import openfl.net.URLRequest;
import flare.core.Mesh3D;
import flare.core.Pivot3D;
import flare.core.Surface3D;
import flare.materials.Material3D;

/**
 * OBJLoader loads Wavefront .obj 3D models into Flare3D Mesh3D hierarchies.
 */
class OBJLoader extends Pivot3D {
    public var url:String;
    public var loaded:Bool = false;
    public var mesh:Mesh3D;

    private var _urlLoader:URLLoader;
    private var _material:Material3D;

    public function new(url:String = "", material:Material3D = null) {
        super("obj_" + url);
        this.url = url;
        this._material = material;
        if (url != "") {
            load();
        }
    }

    public function load():Void {
        #if sys
        var resolved = flare.system.AssetResolver.resolve(url);
        if (sys.FileSystem.exists(resolved)) {
            try {
                var text = sys.io.File.getContent(resolved);
                parse(text);
                loaded = true;
                return;
            } catch (e:Dynamic) {}
        }
        #end

        _urlLoader = new URLLoader();
        _urlLoader.addEventListener(Event.COMPLETE, onComplete);
        _urlLoader.load(new URLRequest(url));
    }

    private function onComplete(e:Event):Void {
        var text:String = _urlLoader.data;
        parse(text);
        loaded = true;
    }

    public function parse(objText:String):Mesh3D {
        mesh = new Mesh3D(name + "_mesh");
        var surface = new Surface3D("obj_surf");

        var rawPositions:Array<Float> = [];
        var rawUVs:Array<Float> = [];
        var rawNormals:Array<Float> = [];

        var vData = surface.vertexData;
        var iData = surface.indexData;

        var lines = objText.split("\n");
        for (line in lines) {
            line = StringTools.trim(line);
            if (line.length == 0 || line.indexOf("#") == 0) continue;

            var parts = ~/\s+/g.split(line);
            var cmd = parts[0];

            if (cmd == "v") {
                rawPositions.push(Std.parseFloat(parts[1]));
                rawPositions.push(Std.parseFloat(parts[2]));
                rawPositions.push(Std.parseFloat(parts[3]));
            } else if (cmd == "vt") {
                rawUVs.push(Std.parseFloat(parts[1]));
                rawUVs.push(Std.parseFloat(parts[2]));
            } else if (cmd == "vn") {
                rawNormals.push(Std.parseFloat(parts[1]));
                rawNormals.push(Std.parseFloat(parts[2]));
                rawNormals.push(Std.parseFloat(parts[3]));
            } else if (cmd == "f") {
                // Triangulate face
                var numVerts = parts.length - 1;
                var faceIndices:Array<UInt> = [];

                for (p in 1...parts.length) {
                    var token = parts[p].split("/");
                    var vIdx = (Std.parseInt(token[0]) - 1) * 3;
                    var vtIdx = token.length > 1 && token[1] != "" ? (Std.parseInt(token[1]) - 1) * 2 : -1;
                    var vnIdx = token.length > 2 && token[2] != "" ? (Std.parseInt(token[2]) - 1) * 3 : -1;

                    var px = (vIdx >= 0 && vIdx < rawPositions.length) ? rawPositions[vIdx] : 0.0;
                    var py = (vIdx >= 0 && vIdx + 1 < rawPositions.length) ? rawPositions[vIdx + 1] : 0.0;
                    var pz = (vIdx >= 0 && vIdx + 2 < rawPositions.length) ? rawPositions[vIdx + 2] : 0.0;

                    var u = (vtIdx >= 0 && vtIdx < rawUVs.length) ? rawUVs[vtIdx] : 0.0;
                    var v = (vtIdx >= 0 && vtIdx + 1 < rawUVs.length) ? 1.0 - rawUVs[vtIdx + 1] : 0.0;

                    var nx = (vnIdx >= 0 && vnIdx < rawNormals.length) ? rawNormals[vnIdx] : 0.0;
                    var ny = (vnIdx >= 0 && vnIdx + 1 < rawNormals.length) ? rawNormals[vnIdx + 1] : 1.0;
                    var nz = (vnIdx >= 0 && vnIdx + 2 < rawNormals.length) ? rawNormals[vnIdx + 2] : 0.0;

                    var curIdx:UInt = Std.int(vData.length / 8);
                    vData.push(px); vData.push(py); vData.push(pz);
                    vData.push(u); vData.push(v);
                    vData.push(nx); vData.push(ny); vData.push(nz);

                    faceIndices.push(curIdx);
                }

                // Fan triangulation
                for (t in 1...(faceIndices.length - 1)) {
                    iData.push(faceIndices[0]);
                    iData.push(faceIndices[t]);
                    iData.push(faceIndices[t + 1]);
                }
            }
        }

        mesh.addSurface(surface, _material);
        addChild(mesh);
        return mesh;
    }
}
