package flare.materials.filters;

import openfl.geom.Vector3D;
import flare.core.Light3D;
import flare.core.ShadowProjector3D;
import flare.core.Texture3D;
import flare.basic.Scene3D;

/**
 * LightFilter calculates per-vertex or per-pixel directional, point, and ambient lighting.
 */
class LightFilter extends Filter3D {
    public static inline var LINEAR:String = "linear";
    public static inline var NO_LIGHTS:String = "noLights";
    public static inline var PER_VERTEX:String = "perVertex";
    public static inline var PHONG:String = "phong";
    public static inline var SAMPLED:String = "sampled";

    public var techniqueName:String;
    public var maxPointLights:Int;
    public var maxDirectionalLights:Int;
    public var useDefaultLights:Bool;

    public var ambientColor:Vector3D = new Vector3D(0.5, 0.5, 0.5);
    public var ambientIntensity:Float = 0.65;
    public var defaultLight:Light3D;
    public var enableRenderShadows:Bool = false;
    public var enableShadowsFiltering:Bool = false;
    public var shadowMapTexture:Texture3D;
    public var filterMapTexture:Texture3D;
    public var cubeMap:Texture3D;
    public var texture:Texture3D;
    public var list:Array<Light3D>;
    public var projectors:Array<ShadowProjector3D>;
    public var scene:Scene3D;

    public var length(get, never):Int;
    private inline function get_length():Int return list.length;
    public inline function iterator():Iterator<Light3D> return list.iterator();
    @:arrayAccess public inline function get(index:Int):Light3D return list[index];

    public function new(techniqueName:String = "perVertex", maxPointLights:Int = 0, maxDirectionalLights:Int = 1, useDefaultLights:Bool = false) {
        super("light");
        this.techniqueName = techniqueName;
        this.maxPointLights = maxPointLights;
        this.maxDirectionalLights = maxDirectionalLights;
        this.useDefaultLights = useDefaultLights;
        this.list = [];
        this.projectors = [];
        this.defaultLight = new Light3D("defaultLight", Light3D.DIRECTIONAL);
    }

    public function process():Void {}
    public function update():Void {}
    public function renderShadows():Void {
        if (projectors != null && scene != null) {
            for (p in projectors) {
                if (p != null) p.updateTextures(scene);
            }
        }
    }
    public function setFogProperties(color:Int, near:Float, far:Float):Void {}
    public function setGamma(val:Float = 2.2):Void {}
    public function dispose():Void {}
}
