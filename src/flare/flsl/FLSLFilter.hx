package flare.flsl;

import flare.materials.filters.Filter3D;
import flare.materials.filters.EdgeFilter;

/**
 * FLSLFilter applies a post-processing or material filter defined by FLSL bytecode.
 */
class FLSLFilter extends Filter3D {
    public var params:Dynamic;
    public var blendMode:Dynamic;
    public var byteCode:Dynamic;
    public var passes:Dynamic;
    public var techniqueName:String;
    public var url:String;
    public var source:Dynamic;
    public var edgeFilter:EdgeFilter;
    public var isRotateTexture:Bool = false;
    public var isScreenProj:Bool = false;

    public function new(source:Dynamic = null, blendMode:Dynamic = null, technique:String = null) {
        super("flslFilter");
        this.source = source;
        this.blendMode = blendMode;
        this.techniqueName = technique;
        this.params = new flare.flsl.FLSLMaterial.FLSLParams();

        var isEdge = false;
        if (source != null) {
            var sStr:String = "";
            if (Std.isOfType(source, String)) {
                sStr = cast source;
            } else {
                try {
                    var b:openfl.utils.ByteArray = cast source;
                    b.position = 0;
                    sStr = b.readUTFBytes(Std.int(Math.min(b.length, 512)));
                    b.position = 0;
                } catch (e:Dynamic) {}
            }
            var lower = sStr.toLowerCase();
            if (lower.indexOf("edge") != -1) isEdge = true;
            if (lower.indexOf("rotate") != -1 || lower.indexOf("angles") != -1) isRotateTexture = true;
            if (lower.indexOf("screenproj") != -1 || lower.indexOf("proj") != -1) isScreenProj = true;
        }

        if (isEdge) {
            this.edgeFilter = new EdgeFilter(1.0, null, blendMode);
        }
    }

    public function build():Void {}

    public function process():Void {}

    public function clone():FLSLFilter {
        var f = new FLSLFilter(source, blendMode, techniqueName);
        if (this.edgeFilter != null) f.edgeFilter = this.edgeFilter.clone();
        f.isRotateTexture = this.isRotateTexture;
        f.isScreenProj = this.isScreenProj;
        return f;
    }
}
