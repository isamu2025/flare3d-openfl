package flare.flsl;



import openfl.Vector;

import openfl.utils.ByteArray;

import openfl.display3D.Context3D;

import openfl.display3D.Context3DBlendFactor;

import openfl.display3D.Context3DCompareMode;

import openfl.display3D.Context3DProgramType;

import openfl.display3D.Context3DTriangleFace;

import openfl.display3D.Program3D;

import openfl.geom.Matrix3D;

import openfl.geom.Vector3D;

import openfl.utils.AGALMiniAssembler;

import flare.core.Camera3D;

import flare.core.Mesh3D;

import flare.core.Surface3D;

import flare.core.Texture3D;

import flare.materials.Shader3D;

import flare.materials.filters.Filter3D;

import flare.materials.filters.TextureMapFilter;

import flare.materials.filters.EnvironmentMapFilter;

import flare.materials.filters.ColorFilter;

import flare.system.Device3D;



class FLSLParamProxy {

    public var name:String;

    private var _value:Dynamic;

    public var onValueChanged:Dynamic->Void = null;



    public var value(get, set):Dynamic;

    private function get_value():Dynamic {

        return _value;

    }

    private function set_value(v:Dynamic):Dynamic {

        _value = v;

        if (onValueChanged != null) onValueChanged(v);

        return v;

    }



    public function new(name:String, val:Dynamic = null) {

        this.name = name;

        if (val != null) {
            this._value = val;
        } else if (name.indexOf("Texture") != -1 || name == "texture" || name == "cubeMap" || name == "cube") {
            this._value = null;
        } else {
            this._value = [0.0, 0.0, 0.0, 0.0];
        }

    }

    public function toString():String {

        return name;

    }

}



class FLSLParams {

    public var alpha:FLSLParamProxy;

    public var color:FLSLParamProxy;

    public var blendValue:FLSLParamProxy;

    public var bloomTexture:FLSLParamProxy;

    public var intensity:FLSLParamProxy;

    public var power:FLSLParamProxy;

    public var nearFar:FLSLParamProxy;

    public var sceneTexture:FLSLParamProxy;

    public var depthTexture:FLSLParamProxy;

    public var attenuation:FLSLParamProxy;

    public var edge:FLSLParamProxy;

    public var ratios:FLSLParamProxy;

    public var fresnelBias:FLSLParamProxy;

    public var fresnelScale:FLSLParamProxy;

    public var fresnelPower:FLSLParamProxy;

    public var cubeMap:FLSLParamProxy;

    public var cube:FLSLParamProxy;

    public var angles:FLSLParamProxy;

    public var texture:FLSLParamProxy;

    public var numColors:FLSLParamProxy;

    public var offset:FLSLParamProxy;
    public var inputTexture:FLSLParamProxy;
    public var outputTexture:FLSLParamProxy;
    public var sampleDistance:FLSLParamProxy;
    public var center:FLSLParamProxy;



    private var _allParams:Array<FLSLParamProxy> = [];



    public function new() {

        alpha = reg("alpha", [1.0]);

        color = reg("color", [0.9, 0.8, 0.7, 0.7]);

        blendValue = reg("blendValue", [1.0]);

        bloomTexture = reg("bloomTexture", null);

        intensity = reg("intensity", [2.0]);

        power = reg("power", [2.0]);

        nearFar = reg("nearFar", [20.0, 100.0]);

        sceneTexture = reg("sceneTexture", null);

        depthTexture = reg("depthTexture", null);

        attenuation = reg("attenuation", [1.0]);

        edge = reg("edge", [1.0]);

        ratios = reg("ratios", [0.87, 0.88, 0.89, 1.0]);

        fresnelBias = reg("fresnelBias", [0.0]);

        fresnelScale = reg("fresnelScale", [5.0]);

        fresnelPower = reg("fresnelPower", [2.0]);

        cubeMap = reg("cubeMap", null);

        cube = reg("cube", null);

        angles = reg("angles", [0.0, 0.0, 0.0]);

        texture = reg("texture", null);

        numColors = reg("numColors", [8.0]);

        offset = reg("offset", [0.5, 0.5]);
        inputTexture = reg("inputTexture", null);
        outputTexture = reg("outputTexture", null);
        sampleDistance = reg("sampleDistance", [0.6]);
        center = reg("center", [0.5, 0.5]);

    }



    private function reg(name:String, val:Dynamic):FLSLParamProxy {

        var p = new FLSLParamProxy(name, val);

        _allParams.push(p);

        return p;

    }



    public function iterator():Iterator<FLSLParamProxy> {

        return _allParams.iterator();

    }

}



/**

 * FLSLMaterial provides custom shader programs compiled from Flare Shading Language (FLSL) bytecode or source.

 */

class FLSLMaterial extends Shader3D {

    public var params:FLSLParams;

    public var byteCode:Dynamic;

    public var programs:Dynamic;

    public var semantics:Dynamic;

    public var source:Dynamic;

    public var techniqueName:String;

    public var currentTexturesPath:String;



    public var cubeTexture:Texture3D = null;

    public var isChromaticRefraction:Bool = false;

    public var isColorMatrix:Bool = false;

    public var isBloom:Bool = false;

    public var isDepth:Bool = false;

    public var isDof:Bool = false;

    public var isNegative:Bool = false;

    public var isPosterize:Bool = false;

    public var isDream:Bool = false;
    public var isNightVision:Bool = false;
    private var _nightVisionProgram:openfl.display3D.Program3D = null;
    private var _nightVisionNoiseTex:flare.core.Texture3D = null;

    private var _negativeProgram:openfl.display3D.Program3D = null;

    private var _posterizeProgram:openfl.display3D.Program3D = null;

    private var _dreamProgram:openfl.display3D.Program3D = null;

    private var _postMvp:openfl.geom.Matrix3D = new openfl.geom.Matrix3D();

    private var _postConst0:openfl.Vector<Float> = new openfl.Vector<Float>(4);

    private var _postConst1:openfl.Vector<Float> = new openfl.Vector<Float>(4);

    private var _postConst2:openfl.Vector<Float> = new openfl.Vector<Float>(4);



    private var _depthProgram:Program3D = null;

    private var _depthMvp:Matrix3D = new Matrix3D();

    private var _depthWorldView:Matrix3D = new Matrix3D();

    private var _depthNearFar:Vector<Float> = new Vector<Float>(4);



    private var _dofBlurHTex:Texture3D = null;

    private var _dofBlurHProgram:Program3D = null;

    private var _dofCompositeProgram:Program3D = null;

    private var _dofMvp:Matrix3D = new Matrix3D();

    private var _dofWeights:Vector<Float> = new Vector<Float>(4);

    private var _dofOffset1:Vector<Float> = new Vector<Float>(4);

    private var _dofOffset2:Vector<Float> = new Vector<Float>(4);

    private var _dofParams:Vector<Float> = new Vector<Float>(4);



    private var _targetTex:Texture3D = null;

    private var _colorMatrixProgram:Program3D = null;

    private var _colorMatrixMvp:Matrix3D = new Matrix3D();

    private var _colorMatrixRow0:Vector<Float> = new Vector<Float>(4);

    private var _colorMatrixRow1:Vector<Float> = new Vector<Float>(4);

    private var _colorMatrixRow2:Vector<Float> = new Vector<Float>(4);

    private var _colorMatrixBlend:Vector<Float> = new Vector<Float>(4);



    private var _bloomProgram:Program3D = null;

    private var _bloomMvp:Matrix3D = new Matrix3D();

    private var _bloomOffset0:Vector<Float> = new Vector<Float>(4);

    private var _bloomOffset1:Vector<Float> = new Vector<Float>(4);

    private var _bloomOffset2:Vector<Float> = new Vector<Float>(4);

    private var _bloomOffset3:Vector<Float> = new Vector<Float>(4);

    private var _bloomWeights:Vector<Float> = new Vector<Float>(4);

    private var _bloomParams:Vector<Float> = new Vector<Float>(4);

    private var _bloomVertexHelpers:Vector<Float> = new Vector<Float>(4);



    private var _camPosVector:Vector<Float> = new Vector<Float>(4);

    private var _chromaticHelperConsts:Vector<Float> = new Vector<Float>(4);

    private var _fresnelVector:Vector<Float> = new Vector<Float>(4);

    private var _ratiosVector:Vector<Float> = new Vector<Float>(4);

    private var _chromaticColorVector:Vector<Float> = new Vector<Float>(4);

    private var _fc1Vector:Vector<Float> = new Vector<Float>(4);

    private var _chromaticMvp:Matrix3D = new Matrix3D();



    public function new(name:String = "", source:Dynamic = null, technique:String = null, compileAll:Bool = false) {

        super(name);

        this.source = source;

        this.techniqueName = technique;

        this.programs = [];

        this.semantics = [];



        _chromaticHelperConsts[0] = 1.0;

        _chromaticHelperConsts[1] = 0.0;

        _chromaticHelperConsts[2] = 2.0;

        _chromaticHelperConsts[3] = 0.5;



        _fc1Vector[0] = 1.0;

        _fc1Vector[1] = 0.0;

        _fc1Vector[2] = 0.0;

        _fc1Vector[3] = 0.0;



        params = new FLSLParams();

        bindParamHooks();



        var t = (techniqueName != null) ? techniqueName.toLowerCase() : "";

        var n = (name != null) ? name.toLowerCase() : "";

        var isEx16 = (n == "shader" || n == "chromaticrefraction" || t == "chromaticrefraction");

        if (!isEx16 && source != null) {

            var sStr = Std.string(source);

            if (sStr.indexOf("example16") != -1 || sStr.indexOf("chromaticRefraction") != -1) {

                isEx16 = true;

            }

        }



        if (isEx16) {

            this.isChromaticRefraction = true;

            this.transparent = true;

            this.depthWrite = true;

            this.depthCompare = Context3DCompareMode.LESS_EQUAL;

            this.twoSided = false;

            this.cullFace = Context3DTriangleFace.BACK;

            this.sourceFactor = Context3DBlendFactor.SOURCE_ALPHA;

            this.destFactor = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;

            this.cubeTexture = new Texture3D("skybox2b.png", false, Texture3D.FORMAT_RGBA, Texture3D.TYPE_CUBE);

            this.params.cubeMap.value = this.cubeTexture;

        } else if (t == "depth") {

            this.isDepth = true;

            this.twoSided = false;

            this.depthWrite = true;

            this.depthCompare = Context3DCompareMode.LESS_EQUAL;

            this.cullFace = Context3DTriangleFace.BACK;

            this.sourceFactor = Context3DBlendFactor.ONE;

            this.destFactor = Context3DBlendFactor.ZERO;

        } else if (t == "dof") {

            this.isDof = true;

            this.twoSided = true;

            this.depthWrite = false;

            this.depthCompare = Context3DCompareMode.ALWAYS;

            this.cullFace = Context3DTriangleFace.NONE;

            this.sourceFactor = Context3DBlendFactor.ONE;

            this.destFactor = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;

        } else if (n == "bloom" || t == "bloom") {

            this.isBloom = true;

            this.twoSided = true;

            this.depthWrite = false;

            this.depthCompare = Context3DCompareMode.ALWAYS;

            this.sourceFactor = Context3DBlendFactor.ONE;

            this.destFactor = Context3DBlendFactor.ONE;

        } else if (n == "negative" || t == "negative") {

            this.isNegative = true;

            this.twoSided = true;

            this.depthWrite = false;

            this.depthCompare = Context3DCompareMode.ALWAYS;

        } else if (n == "posterize" || t == "posterize") {

            this.isPosterize = true;

            this.twoSided = true;

            this.depthWrite = false;

            this.depthCompare = Context3DCompareMode.ALWAYS;

        } else if (n == "dream" || t == "dream") {

            this.isDream = true;
        } else if (n == "nightvision" || t == "nightvision" || n.indexOf("nightvision") != -1) {
            this.isNightVision = true;
            this.twoSided = true;
            this.depthWrite = false;
            this.depthCompare = Context3DCompareMode.ALWAYS;

            this.twoSided = true;

            this.depthWrite = false;

            this.depthCompare = Context3DCompareMode.ALWAYS;

        } else if (n == "sepia" || t == "sepia" || n == "colormatrix" || t == "colormatrix" || n == "gray" || t == "gray") {

            this.isColorMatrix = true;

            this.twoSided = true;

            this.depthWrite = false;

            this.depthCompare = Context3DCompareMode.ALWAYS;

            this.sourceFactor = Context3DBlendFactor.ONE;

            this.destFactor = Context3DBlendFactor.ZERO;

        } else {

            var isCm = false;

            var isBl = false;

            if (source != null) {

                var sStr = Std.string(source);

                if (sStr.indexOf("colorMatrix") != -1 || sStr.indexOf("sepia") != -1) {

                    isCm = true;

                } else if (sStr.indexOf("bloom") != -1) {

                    isBl = true;

                }

            }

            if (isBl) {

                this.isBloom = true;

                this.twoSided = true;

                this.depthWrite = false;

                this.depthCompare = Context3DCompareMode.ALWAYS;

                this.sourceFactor = Context3DBlendFactor.ONE;

                this.destFactor = Context3DBlendFactor.ONE;

            } else if (isCm) {

                this.isColorMatrix = true;

                this.twoSided = true;

                this.depthWrite = false;

                this.depthCompare = Context3DCompareMode.ALWAYS;

                this.sourceFactor = Context3DBlendFactor.ONE;

                this.destFactor = Context3DBlendFactor.ZERO;

            } else {

                this.depthCompare = Context3DCompareMode.ALWAYS;

                this.depthWrite = false;

            }

        }



        setupMaterialByTechnique();

    }



    private function bindParamHooks():Void {

        params.bloomTexture.onValueChanged = function(val:Dynamic) {

            if (isBloom) return;

            if (Std.isOfType(val, Texture3D)) {

                this.filters = [new TextureMapFilter(cast val)];

                this.sourceFactor = Context3DBlendFactor.ONE;

                this.destFactor = Context3DBlendFactor.ONE;

                this.depthWrite = false;

                build();

            }

        };

        params.sceneTexture.onValueChanged = function(val:Dynamic) {

            if (Std.isOfType(val, Texture3D)) {

                this.filters = [new TextureMapFilter(cast val)];

                this.depthWrite = false;

                build();

            }

        };

        params.cubeMap.onValueChanged = function(val:Dynamic) {

            if (Std.isOfType(val, Texture3D)) {

                this.cubeTexture = cast val;

            }

        };

    }



    public function setTargetTexture(tex:Texture3D):Void {

        _targetTex = tex;

        if (isColorMatrix || isNegative || isPosterize || isDream || isNightVision) {

            this.enableLights = false;

            this.depthWrite = false;

            this.depthCompare = Context3DCompareMode.ALWAYS;

            this.twoSided = true;

            return;

        }

        if (_targetTex == tex && program != null) return;

        if (tex != null) {

            this.filters = [new TextureMapFilter(tex), new ColorFilter(0xdfba76)];

            this.enableLights = false;

            this.depthWrite = false;

            this.depthCompare = Context3DCompareMode.ALWAYS;

            this.twoSided = true;

            build();

        }

    }



    public function setTexture(name:String, tex:Dynamic):Void {

        if (Std.isOfType(tex, Texture3D)) {

            this.cubeTexture = cast tex;

            if (params != null && params.cubeMap != null) params.cubeMap.value = tex;

        }

    }



    public function setParam(name:String, val:Dynamic):Void {

        if (params != null) {

            for (p in params) {

                if (p.name == name) {

                    p.value = val;

                    return;

                }

            }

        }

    }



    private function setupMaterialByTechnique():Void {

        if (isChromaticRefraction || isBloom || isDepth || isDof || isColorMatrix || isNegative || isPosterize || isDream || isNightVision) {

            this.filters = [];

            return;

        }

        var t = (techniqueName != null) ? techniqueName.toLowerCase() : "";

        var n = (name != null) ? name.toLowerCase() : "";



        if (t == "depth") {

            this.filters = [new ColorFilter(0x808080)];

        } else if (t == "dof" || n == "bloom" || n == "sepia") {

            this.twoSided = true;

            this.depthWrite = false;

            if (n == "bloom") {

                this.sourceFactor = Context3DBlendFactor.ONE;

                this.destFactor = Context3DBlendFactor.ONE;

            }

        } else {

            // Default 3D model material

            this.twoSided = true;

            this.filters = [

                new ColorFilter(0xd4af37),

                new flare.materials.filters.LightFilter(),

                new flare.materials.filters.SpecularFilter(40, 0.5)

            ];

        }

    }



    public function setTechnique(name:String):Void {

        this.techniqueName = name;

        setupMaterialByTechnique();

        build();

    }



    public function getTechniqueNames():Array<String> {

        return [techniqueName != null ? techniqueName : "default"];

    }



    public function rebuild():Void {

        build();

    }



    private function buildChromaticShader(context:Context3D):Program3D {

        var vSource = 

            "m44 op, va0, vc0\n" +

            "m44 vt0, va0, vc4\n" +

            "sub vt1.xyz, vt0.xyz, vc8.xyz\n" +

            "dp3 vt2.x, vt1.xyz, vt1.xyz\n" +

            "rsq vt2.x, vt2.x\n" +

            "mul vt1.xyz, vt1.xyz, vt2.xxx\n" +

            "m33 vt2.xyz, va2.xyz, vc4\n" +

            "dp3 vt3.x, vt2.xyz, vt2.xyz\n" +

            "rsq vt3.x, vt3.x\n" +

            "mul vt2.xyz, vt2.xyz, vt3.xxx\n" +

            "dp3 vt3.x, vt1.xyz, vt2.xyz\n" +

            "add vt3.y, vt3.x, vt3.x\n" +

            "mul vt4.xyz, vt2.xyz, vt3.yyy\n" +

            "sub vt4.xyz, vt1.xyz, vt4.xyz\n" +

            "mov v3.xyz, vt4.xyz\n" +

            "mov v3.w, vc9.x\n" +

            "add vt3.z, vt3.x, vc9.x\n" +

            "max vt3.z, vt3.z, vc9.y\n" +

            "min vt3.z, vt3.z, vc9.x\n" +

            "mul vt3.w, vt3.z, vt3.z\n" +

            "mul vt3.w, vt3.w, vc10.y\n" +

            "add vt3.w, vt3.w, vc10.x\n" +

            "max vt3.w, vt3.w, vc9.y\n" +

            "min vt3.w, vt3.w, vc9.x\n" +

            "mov v4.x, vt3.w\n" +

            "mov v4.yzw, vc9.yyy\n" +

            "mul vt3.y, vt3.x, vt3.x\n" +

            "sub vt3.y, vc9.x, vt3.y\n" +

            "max vt3.y, vt3.y, vc9.y\n" +

            // RED: eta = vc11.x

            "mul vt4.x, vc11.x, vc11.x\n" +

            "mul vt4.y, vt4.x, vt3.y\n" +

            "sub vt4.y, vc9.x, vt4.y\n" +

            "max vt4.y, vt4.y, vc9.y\n" +

            "sqt vt4.y, vt4.y\n" +

            "mul vt4.z, vc11.x, vt3.x\n" +

            "add vt4.z, vt4.z, vt4.y\n" +

            "mul vt5.xyz, vt1.xyz, vc11.xxx\n" +

            "mul vt6.xyz, vt2.xyz, vt4.zzz\n" +

            "sub vt5.xyz, vt5.xyz, vt6.xyz\n" +

            "mov v0.xyz, vt5.xyz\n" +

            "mov v0.w, vc9.x\n" +

            // GREEN: eta = vc11.y

            "mul vt4.x, vc11.y, vc11.y\n" +

            "mul vt4.y, vt4.x, vt3.y\n" +

            "sub vt4.y, vc9.x, vt4.y\n" +

            "max vt4.y, vt4.y, vc9.y\n" +

            "sqt vt4.y, vt4.y\n" +

            "mul vt4.z, vc11.y, vt3.x\n" +

            "add vt4.z, vt4.z, vt4.y\n" +

            "mul vt5.xyz, vt1.xyz, vc11.yyy\n" +

            "mul vt6.xyz, vt2.xyz, vt4.zzz\n" +

            "sub vt5.xyz, vt5.xyz, vt6.xyz\n" +

            "mov v1.xyz, vt5.xyz\n" +

            "mov v1.w, vc9.x\n" +

            // BLUE: eta = vc11.z

            "mul vt4.x, vc11.z, vc11.z\n" +

            "mul vt4.y, vt4.x, vt3.y\n" +

            "sub vt4.y, vc9.x, vt4.y\n" +

            "max vt4.y, vt4.y, vc9.y\n" +

            "sqt vt4.y, vt4.y\n" +

            "mul vt4.z, vc11.z, vt3.x\n" +

            "add vt4.z, vt4.z, vt4.y\n" +

            "mul vt5.xyz, vt1.xyz, vc11.zzz\n" +

            "mul vt6.xyz, vt2.xyz, vt4.zzz\n" +

            "sub vt5.xyz, vt5.xyz, vt6.xyz\n" +

            "mov v2.xyz, vt5.xyz\n" +

            "mov v2.w, vc9.x\n";



        var fSource = 

            "tex ft0, v0, fs0 <cube,linear,mipnone,clamp>\n" +

            "tex ft1, v1, fs0 <cube,linear,mipnone,clamp>\n" +

            "tex ft2, v2, fs0 <cube,linear,mipnone,clamp>\n" +

            "tex ft3, v3, fs0 <cube,linear,mipnone,clamp>\n" +

            "mov ft4.x, ft0.x\n" +

            "mov ft4.y, ft1.y\n" +

            "mov ft4.z, ft2.z\n" +

            "mov ft4.w, fc1.x\n" +

            "sub ft5, ft3, ft4\n" +

            "mul ft5, ft5, v4.xxxx\n" +

            "add ft0, ft4, ft5\n" +

            "mul ft0, ft0, fc0\n" +

            "mov oc, ft0\n";



        var assembler = new AGALMiniAssembler();

        return assembler.assemble2(context, 1, vSource, fSource);

    }



    private function getParamFloat(p:Dynamic, defaultVal:Float):Float {

        if (p == null) return defaultVal;

        var val:Dynamic = p;

        if (Reflect.hasField(p, "value")) {

            val = Reflect.field(p, "value");

        }

        if (val == null) return defaultVal;

        if (Std.isOfType(val, Float) || Std.isOfType(val, Int)) {

            var f:Float = cast val;

            return Math.isNaN(f) ? defaultVal : f;

        }

        if (Std.isOfType(val, Array)) {

            var arr:Array<Dynamic> = cast val;

            if (arr.length > 0) {

                var f:Float = Std.parseFloat(Std.string(arr[0]));

                return Math.isNaN(f) ? defaultVal : f;

            }

            return defaultVal;

        }

        if (Reflect.hasField(val, "length")) {
            try {
                var len:Int = Reflect.field(val, "length");
                if (len > 0) {
                    var arr:Dynamic = val;
                    var elem:Dynamic = arr[0];
                    var f:Float = Std.parseFloat(Std.string(elem));
                    if (!Math.isNaN(f)) return f;
                }
            } catch (e:Dynamic) {}
        }

        var str = Std.string(val);

        str = StringTools.replace(str, "[", "");

        str = StringTools.replace(str, "]", "");

        str = StringTools.trim(str);

        var f = Std.parseFloat(str);

        if (Math.isNaN(f)) return defaultVal;

        return f;

    }



    private function buildColorMatrixShader(context:Context3D):Program3D {

        var vSource = 

            "m44 op, va0, vc0\n" +

            "mov v0, va1\n";



        var fSource = 

            "tex ft0, v0, fs0 <2d,linear,mipnone,clamp>\n" +

            "dp3 ft1.x, ft0.xyz, fc0.xyz\n" +

            "dp3 ft1.y, ft0.xyz, fc1.xyz\n" +

            "dp3 ft1.z, ft0.xyz, fc2.xyz\n" +

            "mov ft1.w, ft0.w\n" +

            "sub ft2, ft0, ft1\n" +

            "mul ft2, ft2, fc3.xxxx\n" +

            "add ft0, ft1, ft2\n" +

            "mov oc, ft0\n";



        var assembler = new AGALMiniAssembler();

        return assembler.assemble2(context, 1, vSource, fSource);

    }



    private function drawColorMatrix(mesh:Mesh3D, surface:Surface3D, camera:Camera3D):Void {

        var context = Device3D.context;

        if (context == null || surface == null) return;



        if (_colorMatrixProgram == null) {

            _colorMatrixProgram = buildColorMatrixShader(context);

            if (_colorMatrixProgram == null) return;

        }



        surface.upload(context);

        if (surface.vertexBuffer == null || surface.indexBuffer == null) return;



        var activeTex = (_targetTex != null) ? _targetTex : (params.sceneTexture.value != null ? cast(params.sceneTexture.value, Texture3D) : null);

        if (activeTex != null) {

            activeTex.upload(Device3D.scene);

            if (activeTex.texture != null) {

                context.setTextureAt(0, activeTex.texture);

            }

        }



        Device3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);

        Device3D.setDepthTest(false, Context3DCompareMode.ALWAYS);

        Device3D.setCulling(Context3DTriangleFace.NONE);



        Device3D.setProgram(_colorMatrixProgram);

        Device3D.setVertexBuffers(surface.vertexBuffer, surface);



        // Vertex: vc0..vc3: MVP matrix (mesh.world)

        if (mesh != null) {

            _colorMatrixMvp.copyFrom(mesh.world);

        } else {

            _colorMatrixMvp.identity();

        }

        context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, _colorMatrixMvp, true);



        // Fragment constants:

        var t = (techniqueName != null) ? techniqueName.toLowerCase() : "";

        if (t == "gray") {

            _colorMatrixRow0[0] = 0.212671; _colorMatrixRow0[1] = 0.715160; _colorMatrixRow0[2] = 0.072169; _colorMatrixRow0[3] = 0.0;

            _colorMatrixRow1[0] = 0.212671; _colorMatrixRow1[1] = 0.715160; _colorMatrixRow1[2] = 0.072169; _colorMatrixRow1[3] = 0.0;

            _colorMatrixRow2[0] = 0.212671; _colorMatrixRow2[1] = 0.715160; _colorMatrixRow2[2] = 0.072169; _colorMatrixRow2[3] = 0.0;

        } else {

            // Sepia constants from Flare3D colorMatrix.flsl:

            // sepia[0] = float4( 0.3930000066757202, 0.7689999938011169, 0.1889999955892563, 0 ); 

            // sepia[1] = float4( 0.3490000069141388, 0.6859999895095825, 0.1679999977350235, 0 );

            // sepia[2] = float4( 0.2720000147819519, 0.5339999794960022, 0.1309999972581863, 0 );

            _colorMatrixRow0[0] = 0.3930000066757202; _colorMatrixRow0[1] = 0.7689999938011169; _colorMatrixRow0[2] = 0.1889999955892563; _colorMatrixRow0[3] = 0.0;

            _colorMatrixRow1[0] = 0.3490000069141388; _colorMatrixRow1[1] = 0.6859999895095825; _colorMatrixRow1[2] = 0.1679999977350235; _colorMatrixRow1[3] = 0.0;

            _colorMatrixRow2[0] = 0.2720000147819519; _colorMatrixRow2[1] = 0.5339999794960022; _colorMatrixRow2[2] = 0.1309999972581863; _colorMatrixRow2[3] = 0.0;

        }



        var b:Float = getParamFloat(params.blendValue, 1.0);

        if (b < 0.0) b = 0.0;

        if (b > 1.0) b = 1.0;

        _colorMatrixBlend[0] = b;

        _colorMatrixBlend[1] = 1.0 - b;

        _colorMatrixBlend[2] = 0.0;

        _colorMatrixBlend[3] = 1.0;



        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _colorMatrixRow0);

        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, _colorMatrixRow1);

        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, _colorMatrixRow2);

        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 3, _colorMatrixBlend);



        Device3D.drawCalls++;

        Device3D.triangles += surface.numTriangles;

        context.drawTriangles(surface.indexBuffer, 0, surface.numTriangles);



        context.setTextureAt(0, null);

        Device3D.currentMesh = null;

    }



    private function buildBloomShader(context:Context3D):Program3D {

        var vSource = 

            "m44 op, va0, vc0\n" +

            "mov v0, va1\n";



        var fSource = 

            "tex ft0, v0, fs0 <2d,linear,mipnone,clamp>\n" +

            "mul ft0.xyz, ft0.xyz, fc4.xxx\n" +



            "add ft1, v0, fc0\n" +

            "tex ft6, ft1, fs0 <2d,linear,mipnone,clamp>\n" +

            "mul ft6.xyz, ft6.xyz, fc4.yyy\n" +

            "add ft0.xyz, ft0.xyz, ft6.xyz\n" +



            "add ft1, v0, fc1\n" +

            "tex ft6, ft1, fs0 <2d,linear,mipnone,clamp>\n" +

            "mul ft6.xyz, ft6.xyz, fc4.yyy\n" +

            "add ft0.xyz, ft0.xyz, ft6.xyz\n" +



            "add ft1, v0, fc2\n" +

            "tex ft6, ft1, fs0 <2d,linear,mipnone,clamp>\n" +

            "mul ft6.xyz, ft6.xyz, fc4.yyy\n" +

            "add ft0.xyz, ft0.xyz, ft6.xyz\n" +



            "add ft1, v0, fc3\n" +

            "tex ft6, ft1, fs0 <2d,linear,mipnone,clamp>\n" +

            "mul ft6.xyz, ft6.xyz, fc4.yyy\n" +

            "add ft0.xyz, ft0.xyz, ft6.xyz\n" +



            "sub ft0.xyz, ft0.xyz, fc5.zzz\n" +

            "max ft0.xyz, ft0.xyz, fc4.zzz\n" +

            "mul ft0.xyz, ft0.xyz, fc5.www\n" +

            "min ft0.xyz, ft0.xyz, fc4.www\n" +

            "pow ft0.x, ft0.x, fc5.x\n" +

            "pow ft0.y, ft0.y, fc5.x\n" +

            "pow ft0.z, ft0.z, fc5.x\n" +

            "mul ft0.xyz, ft0.xyz, fc5.yyy\n" +

            "mov ft0.w, fc4.www\n" +

            "mov oc, ft0\n";



        var assembler = new AGALMiniAssembler();

        return assembler.assemble2(context, 1, vSource, fSource);

    }



    private function drawBloom(mesh:Mesh3D, surface:Surface3D, camera:Camera3D):Void {

        var context = Device3D.context;

        if (context == null || surface == null) return;



        if (_bloomProgram == null) {

            _bloomProgram = buildBloomShader(context);

            if (_bloomProgram == null) return;

        }



        surface.upload(context);

        if (surface.vertexBuffer == null || surface.indexBuffer == null) return;



        var activeTex:Texture3D = null;

        if (params != null && params.bloomTexture != null && params.bloomTexture.value != null && Std.isOfType(params.bloomTexture.value, Texture3D)) {

            activeTex = cast params.bloomTexture.value;

        } else if (_targetTex != null) {

            activeTex = _targetTex;

        }



        if (activeTex != null) {

            activeTex.upload(Device3D.scene);

            if (activeTex.texture != null) {

                context.setTextureAt(0, activeTex.texture);

            }

        }



        Device3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ONE);

        Device3D.setDepthTest(false, Context3DCompareMode.ALWAYS);

        Device3D.setCulling(Context3DTriangleFace.NONE);



        Device3D.setProgram(_bloomProgram);

        Device3D.setVertexBuffers(surface.vertexBuffer, surface);



        if (mesh != null) {

            _bloomMvp.copyFrom(mesh.world);

        } else {

            _bloomMvp.identity();

        }

        context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, _bloomMvp, true);



        // vc4: [1.0, 0.0, 0.0, 0.0] for UV Y-flip

        _bloomVertexHelpers[0] = 1.0;

        _bloomVertexHelpers[1] = 0.0;

        _bloomVertexHelpers[2] = 0.0;

        _bloomVertexHelpers[3] = 0.0;

        context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, _bloomVertexHelpers);



        // fc0..fc3: 4 diagonal texel offsets

        var w:Float = 256.0;

        var h:Float = 256.0;

        if (activeTex != null && activeTex.width > 0) w = activeTex.width;

        if (activeTex != null && activeTex.height > 0) h = activeTex.height;

        var dx = 8.0 / w;

        var dy = 8.0 / h;



        _bloomOffset0[0] =  dx; _bloomOffset0[1] =  dy; _bloomOffset0[2] = 0.0; _bloomOffset0[3] = 0.0;

        _bloomOffset1[0] = -dx; _bloomOffset1[1] =  dy; _bloomOffset1[2] = 0.0; _bloomOffset1[3] = 0.0;

        _bloomOffset2[0] =  dx; _bloomOffset2[1] = -dy; _bloomOffset2[2] = 0.0; _bloomOffset2[3] = 0.0;

        _bloomOffset3[0] = -dx; _bloomOffset3[1] = -dy; _bloomOffset3[2] = 0.0; _bloomOffset3[3] = 0.0;

        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _bloomOffset0);

        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, _bloomOffset1);

        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, _bloomOffset2);

        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 3, _bloomOffset3);



        // fc4: weights [center, corner, 0.0, 1.0]

        _bloomWeights[0] = 0.20;

        _bloomWeights[1] = 0.20;

        _bloomWeights[2] = 0.0;

        _bloomWeights[3] = 1.0;

        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 4, _bloomWeights);



        // fc5: params [power, intensity, threshold, scale]

        // Subtle highlight bloom matching Flash AS3 original

        var p:Float = getParamFloat(params.power, 2.0);

        var i:Float = 0.65;

        var thresh:Float = 0.45;

        var scale:Float = 1.0 / (1.0 - thresh);

        _bloomParams[0] = p;

        _bloomParams[1] = i;

        _bloomParams[2] = thresh;

        _bloomParams[3] = scale;

        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 5, _bloomParams);



        Device3D.drawCalls++;

        Device3D.triangles += surface.numTriangles;

        context.drawTriangles(surface.indexBuffer, 0, surface.numTriangles);



        context.setTextureAt(0, null);

        Device3D.currentMesh = null;

    }



    override public function draw(mesh:Mesh3D, surface:Surface3D, camera:Camera3D):Void {

        if (isChromaticRefraction) {

            drawChromatic(mesh, surface, camera);

            return;

        }

        if (isColorMatrix) {

            drawColorMatrix(mesh, surface, camera);

            return;

        }

        if (isBloom) {

            drawBloom(mesh, surface, camera);

            return;

        }

        if (isDepth) {

            drawDepth(mesh, surface, camera);

            return;

        }

        if (isDof) {

            drawDof(mesh, surface, camera);

            return;

        }

        if (isNegative) {

            drawNegative(mesh, surface, camera);

            return;

        }

        if (isPosterize) {

            drawPosterize(mesh, surface, camera);

            return;

        }

        if (isDream) {

            drawDream(mesh, surface, camera);

            return;

        }

        if (isNightVision) {
            drawNightVision(mesh, surface, camera);
            return;
        }

        super.draw(mesh, surface, camera);

    }



    private function drawChromatic(mesh:Mesh3D, surface:Surface3D, camera:Camera3D):Void {

        var context = Device3D.context;

        if (context == null || surface == null) return;



        if (program == null) {

            program = buildChromaticShader(context);

            if (program == null) return;

        }



        surface.upload(context);

        if (surface.vertexBuffer == null || surface.indexBuffer == null) return;



        if (cubeTexture != null) {

            cubeTexture.upload(context);

            if (cubeTexture.texture != null) {

                context.setTextureAt(0, cubeTexture.texture);

            }

        }



        Device3D.setBlendFactors(sourceFactor, destFactor);

        Device3D.setDepthTest(depthWrite, depthCompare);

        Device3D.setCulling(twoSided ? Context3DTriangleFace.NONE : cullFace);



        Device3D.setProgram(program);

        Device3D.setVertexBuffers(surface.vertexBuffer, surface);



        // vc0..vc3: MVP matrix

        _chromaticMvp.copyFrom(mesh.world);

        if (camera != null) _chromaticMvp.append(camera.viewProjection);

        context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, _chromaticMvp, true);



        // vc4..vc7: World matrix

        context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 4, mesh.world, true);



        // vc8: Camera world position

        var camPos = (camera != null) ? camera.getPosition(false) : new Vector3D(0, 20, -130);

        _camPosVector[0] = camPos.x;

        _camPosVector[1] = camPos.y;

        _camPosVector[2] = camPos.z;

        _camPosVector[3] = 1.0;

        context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 8, _camPosVector);



        // vc9: Helper constants [1.0, 0.0, 2.0, 0.5]

        context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 9, _chromaticHelperConsts);



        // vc10: Fresnel params [bias, scale, power, 0]

        var fb = getParamFloat(params.fresnelBias, 0.0);

        var fs = getParamFloat(params.fresnelScale, 5.0);

        var fp = getParamFloat(params.fresnelPower, 2.0);

        _fresnelVector[0] = fb;

        _fresnelVector[1] = fs;

        _fresnelVector[2] = fp;

        _fresnelVector[3] = 0.0;

        context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 10, _fresnelVector);



        // vc11: Refraction ratios [0.87, 0.88, 0.89, 1.0]

        var rVal:Dynamic = params.ratios.value;

        if (Std.isOfType(rVal, Array)) {

            var arr:Array<Dynamic> = cast rVal;

            _ratiosVector[0] = arr.length > 0 ? arr[0] : 0.87;

            _ratiosVector[1] = arr.length > 1 ? arr[1] : 0.88;

            _ratiosVector[2] = arr.length > 2 ? arr[2] : 0.89;

            _ratiosVector[3] = arr.length > 3 ? arr[3] : 1.0;

        } else if (rVal != null && Reflect.hasField(rVal, "x")) {

            _ratiosVector[0] = Reflect.field(rVal, "x");

            _ratiosVector[1] = Reflect.field(rVal, "y");

            _ratiosVector[2] = Reflect.field(rVal, "z");

            _ratiosVector[3] = 1.0;

        }

        context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 11, _ratiosVector);



        // fc0: Color modulation [r, g, b, a]

        var cVal:Dynamic = params.color.value;

        if (Std.isOfType(cVal, Array)) {

            var arr:Array<Dynamic> = cast cVal;

            _chromaticColorVector[0] = arr.length > 0 ? arr[0] : 0.9;

            _chromaticColorVector[1] = arr.length > 1 ? arr[1] : 0.8;

            _chromaticColorVector[2] = arr.length > 2 ? arr[2] : 0.7;

            _chromaticColorVector[3] = arr.length > 3 ? arr[3] : 0.7;

        } else if (cVal != null && Reflect.hasField(cVal, "x")) {

            _chromaticColorVector[0] = Reflect.field(cVal, "x");

            _chromaticColorVector[1] = Reflect.field(cVal, "y");

            _chromaticColorVector[2] = Reflect.field(cVal, "z");

            _chromaticColorVector[3] = Reflect.hasField(cVal, "w") ? Reflect.field(cVal, "w") : 0.7;

        }

        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _chromaticColorVector);



        // fc1: Helpers [1.0, 0.0, 0.0, 0.0]

        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, _fc1Vector);



        Device3D.drawCalls++;

        Device3D.triangles += surface.numTriangles;

        context.drawTriangles(surface.indexBuffer, 0, surface.numTriangles);

    }



    private function buildDepthShader(context:Context3D):Program3D {

        var vSource = 

            "m44 op, va0, vc0\n" +

            "m44 vt0, va0, vc4\n" +

            "sub vt1.x, vt0.z, vc8.x\n" +

            "mul vt1.x, vt1.x, vc8.y\n" +

            "mov v0, vt1.xxxx\n";



        var fSource = 

            "sat ft0, v0\n" +

            "mov oc, ft0\n";



        var assembler = new AGALMiniAssembler();

        return assembler.assemble2(context, 1, vSource, fSource);

    }



    private function drawDepth(mesh:Mesh3D, surface:Surface3D, camera:Camera3D):Void {

        var context = Device3D.context;

        if (context == null || surface == null) return;



        if (_depthProgram == null) {

            _depthProgram = buildDepthShader(context);

            if (_depthProgram == null) return;

        }



        surface.upload(context);

        if (surface.vertexBuffer == null || surface.indexBuffer == null) return;



        Device3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);

        Device3D.setDepthTest(true, Context3DCompareMode.LESS_EQUAL);

        Device3D.setCulling(twoSided ? Context3DTriangleFace.NONE : cullFace);



        Device3D.setProgram(_depthProgram);

        Device3D.setVertexBuffers(surface.vertexBuffer, surface);



        if (mesh != null) {

            _depthMvp.copyFrom(mesh.world);

            if (camera != null) _depthMvp.append(camera.viewProjection);

            _depthWorldView.copyFrom(mesh.world);

            if (camera != null) _depthWorldView.append(camera.view);

        } else {

            _depthMvp.identity();

            _depthWorldView.identity();

        }



        context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, _depthMvp, true);

        context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 4, _depthWorldView, true);



        var near:Float = 100.0;

        var far:Float = 500.0;

        if (params != null && params.nearFar != null && params.nearFar.value != null) {

            var nf:Dynamic = params.nearFar.value;

            try {

                if (nf.length > 0) near = nf[0];

                if (nf.length > 1) far = nf[1];

            } catch (e:Dynamic) {

                if (Reflect.hasField(nf, "x")) {

                    near = Reflect.field(nf, "x");

                    if (Reflect.hasField(nf, "y")) far = Reflect.field(nf, "y");

                }

            }

        }

        var range:Float = (far - near);

        if (Math.abs(range) < 0.0001) range = 1.0;

        _depthNearFar[0] = near;

        _depthNearFar[1] = 1.0 / range;

        _depthNearFar[2] = 0.0;

        _depthNearFar[3] = 1.0;

        context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 8, _depthNearFar);



        Device3D.drawCalls++;

        Device3D.triangles += surface.numTriangles;

        context.drawTriangles(surface.indexBuffer, 0, surface.numTriangles);

        Device3D.currentMesh = null;

    }



    private function buildDofBlurHShader(context:Context3D):Program3D {

        var vSource = 

            "m44 op, va0, vc0\n" +

            "mov v0, va1\n";



        var fSource = 

            "tex ft0, v0, fs0 <2d,linear,mipnone,clamp>\n" +

            "mul ft0.xyz, ft0.xyz, fc0.xxx\n" +

            "add ft1, v0, fc1\n" +

            "tex ft2, ft1, fs0 <2d,linear,mipnone,clamp>\n" +

            "sub ft1, v0, fc1\n" +

            "tex ft3, ft1, fs0 <2d,linear,mipnone,clamp>\n" +

            "add ft2.xyz, ft2.xyz, ft3.xyz\n" +

            "mul ft2.xyz, ft2.xyz, fc0.yyy\n" +

            "add ft0.xyz, ft0.xyz, ft2.xyz\n" +

            "add ft1, v0, fc2\n" +

            "tex ft2, ft1, fs0 <2d,linear,mipnone,clamp>\n" +

            "sub ft1, v0, fc2\n" +

            "tex ft3, ft1, fs0 <2d,linear,mipnone,clamp>\n" +

            "add ft2.xyz, ft2.xyz, ft3.xyz\n" +

            "mul ft2.xyz, ft2.xyz, fc0.zzz\n" +

            "add ft0.xyz, ft0.xyz, ft2.xyz\n" +

            "mov ft0.w, fc0.www\n" +

            "mov oc, ft0\n";



        var assembler = new AGALMiniAssembler();

        return assembler.assemble2(context, 1, vSource, fSource);

    }



    private function buildDofCompositeShader(context:Context3D):Program3D {

        var vSource = 

            "m44 op, va0, vc0\n" +

            "mov v0, va1\n";



        var fSource = 

            "tex ft0, v0, fs0 <2d,linear,mipnone,clamp>\n" +

            "mul ft0.xyz, ft0.xyz, fc0.xxx\n" +

            "add ft1, v0, fc1\n" +

            "tex ft2, ft1, fs0 <2d,linear,mipnone,clamp>\n" +

            "sub ft1, v0, fc1\n" +

            "tex ft3, ft1, fs0 <2d,linear,mipnone,clamp>\n" +

            "add ft2.xyz, ft2.xyz, ft3.xyz\n" +

            "mul ft2.xyz, ft2.xyz, fc0.yyy\n" +

            "add ft0.xyz, ft0.xyz, ft2.xyz\n" +

            "add ft1, v0, fc2\n" +

            "tex ft2, ft1, fs0 <2d,linear,mipnone,clamp>\n" +

            "sub ft1, v0, fc2\n" +

            "tex ft3, ft1, fs0 <2d,linear,mipnone,clamp>\n" +

            "add ft2.xyz, ft2.xyz, ft3.xyz\n" +

            "mul ft2.xyz, ft2.xyz, fc0.zzz\n" +

            "add ft0.xyz, ft0.xyz, ft2.xyz\n" +

            "tex ft1, v0, fs1 <2d,linear,mipnone,clamp>\n" +

            "mul ft1.w, ft1.w, fc3.x\n" +

            "sat ft1.w, ft1.w\n" +

            "mul ft0.xyz, ft0.xyz, ft1.www\n" +

            "mov ft0.w, ft1.w\n" +

            "mov oc, ft0\n";



        var assembler = new AGALMiniAssembler();

        return assembler.assemble2(context, 1, vSource, fSource);

    }



    private function drawDof(mesh:Mesh3D, surface:Surface3D, camera:Camera3D):Void {

        var context = Device3D.context;

        if (context == null || surface == null) return;



        if (_dofBlurHProgram == null) {

            _dofBlurHProgram = buildDofBlurHShader(context);

            if (_dofBlurHProgram == null) return;

        }

        if (_dofCompositeProgram == null) {

            _dofCompositeProgram = buildDofCompositeShader(context);

            if (_dofCompositeProgram == null) return;

        }



        surface.upload(context);

        if (surface.vertexBuffer == null || surface.indexBuffer == null) return;



        var sceneTex:Texture3D = null;

        if (params != null && params.sceneTexture != null && params.sceneTexture.value != null && Std.isOfType(params.sceneTexture.value, Texture3D)) {

            sceneTex = cast params.sceneTexture.value;

        }

        var depthTex:Texture3D = null;

        if (params != null && params.depthTexture != null && params.depthTexture.value != null && Std.isOfType(params.depthTexture.value, Texture3D)) {

            depthTex = cast params.depthTexture.value;

        }



        if (sceneTex == null || depthTex == null) return;

        if (sceneTex.texture == null || depthTex.texture == null) return;



        var w:Float = sceneTex.width > 0 ? sceneTex.width : 512.0;

        var h:Float = sceneTex.height > 0 ? sceneTex.height : 256.0;



        if (_dofBlurHTex == null) {

            _dofBlurHTex = new Texture3D(new openfl.geom.Point(w, h), true);

        }

        if (_dofBlurHTex.scene == null || _dofBlurHTex.texture == null) {

            _dofBlurHTex.upload(Device3D.scene);

        }

        if (_dofBlurHTex.texture == null) return;



        if (mesh != null) {

            _dofMvp.copyFrom(mesh.world);

        } else {

            _dofMvp.identity();

        }



        _dofWeights[0] = 0.2270270270;

        _dofWeights[1] = 0.3162162162;

        _dofWeights[2] = 0.0702702703;

        _dofWeights[3] = 1.0;



        var blurScale:Float = 1.5;

        var dx = (1.0 / 512.0) * blurScale;

        var dy = (1.0 / 256.0) * (blurScale * 0.5);



        // --- PASS 0: Horizontal Blur to _dofBlurHTex ---

        context.setRenderToTexture(_dofBlurHTex.texture, true);

        context.clear(0, 0, 0, 0);



        Device3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);

        Device3D.setDepthTest(false, Context3DCompareMode.ALWAYS);

        Device3D.setCulling(Context3DTriangleFace.NONE);



        Device3D.setProgram(_dofBlurHProgram);

        Device3D.setVertexBuffers(surface.vertexBuffer, surface);



        context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, _dofMvp, true);

        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _dofWeights);



        _dofOffset1[0] = 1.3846153846 * dx; _dofOffset1[1] = 0.0; _dofOffset1[2] = 0.0; _dofOffset1[3] = 0.0;

        _dofOffset2[0] = 3.2307692308 * dx; _dofOffset2[1] = 0.0; _dofOffset2[2] = 0.0; _dofOffset2[3] = 0.0;

        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, _dofOffset1);

        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, _dofOffset2);



        context.setTextureAt(0, sceneTex.texture);



        Device3D.drawCalls++;

        Device3D.triangles += surface.numTriangles;

        context.drawTriangles(surface.indexBuffer, 0, surface.numTriangles);



        context.setTextureAt(0, null);



        // --- PASS 1: Vertical Blur + Depth Mask to BackBuffer ---

        context.setRenderToBackBuffer();



        Device3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);

        Device3D.setDepthTest(false, Context3DCompareMode.ALWAYS);

        Device3D.setCulling(Context3DTriangleFace.NONE);



        Device3D.setProgram(_dofCompositeProgram);

        Device3D.setVertexBuffers(surface.vertexBuffer, surface);



        context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, _dofMvp, true);

        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _dofWeights);



        _dofOffset1[0] = 0.0; _dofOffset1[1] = 1.3846153846 * dy; _dofOffset1[2] = 0.0; _dofOffset1[3] = 0.0;

        _dofOffset2[0] = 0.0; _dofOffset2[1] = 3.2307692308 * dy; _dofOffset2[2] = 0.0; _dofOffset2[3] = 0.0;

        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, _dofOffset1);

        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, _dofOffset2);



        var att = getParamFloat(params.attenuation, 1.0);

        _dofParams[0] = att; _dofParams[1] = 0.0; _dofParams[2] = 0.0; _dofParams[3] = 0.0;

        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 3, _dofParams);



        context.setTextureAt(0, _dofBlurHTex.texture);

        context.setTextureAt(1, depthTex.texture);



        Device3D.drawCalls++;

        Device3D.triangles += surface.numTriangles;

        context.drawTriangles(surface.indexBuffer, 0, surface.numTriangles);



        context.setTextureAt(0, null);

        context.setTextureAt(1, null);

        Device3D.currentMesh = null;

    }



    override public function clone():Shader3D {

        var mat = new FLSLMaterial(name, source, techniqueName);

        mat.params = this.params;

        mat.isChromaticRefraction = this.isChromaticRefraction;

        mat.isBloom = this.isBloom;

        mat.isColorMatrix = this.isColorMatrix;

        mat.isDepth = this.isDepth;

        mat.isDof = this.isDof;

        return mat;

    }



    private function buildNegativeShader(context:Context3D):Program3D {

        var vSource = "m44 op, va0, vc0\nmov v0, va1\n";

        var fSource = "tex ft0, v0, fs0 <2d,linear,mipnone,clamp>\nsub ft0.xyz, fc0.xxx, ft0.xyz\nmov ft0.w, fc0.x\nmov oc, ft0\n";

        var assembler = new AGALMiniAssembler(); return assembler.assemble2(context, 1, vSource, fSource);

    }



    private function drawNegative(mesh:Mesh3D, surface:Surface3D, camera:Camera3D):Void {

        var context = Device3D.context;

        if (context == null || surface == null) return;

        if (_negativeProgram == null) _negativeProgram = buildNegativeShader(context);

        if (_negativeProgram == null) return;



        surface.upload(context);

        if (surface.vertexBuffer == null || surface.indexBuffer == null) return;



        Device3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);

        Device3D.setDepthTest(false, Context3DCompareMode.ALWAYS);

        Device3D.setCulling(Context3DTriangleFace.NONE);

        Device3D.setProgram(_negativeProgram);

        Device3D.setVertexBuffers(surface.vertexBuffer, surface);



        if (mesh != null) _postMvp.copyFrom(mesh.world); else _postMvp.identity();

        context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, _postMvp, true);

        _postConst0[0] = 1.0; _postConst0[1] = 1.0; _postConst0[2] = 1.0; _postConst0[3] = 1.0;

        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _postConst0);



        var tex = (_targetTex != null) ? _targetTex.texture : null;

        if (tex != null) context.setTextureAt(0, tex);



        Device3D.drawCalls++;

        Device3D.triangles += surface.numTriangles;

        context.drawTriangles(surface.indexBuffer, 0, surface.numTriangles);

        context.setTextureAt(0, null);

        Device3D.currentMesh = null;

    }



    private function buildPosterizeShader(context:Context3D):Program3D {

        var vSource = "m44 op, va0, vc0\nmov v0, va1\n";

        var fSource = "tex ft0, v0, fs0 <2d,linear,mipnone,clamp>\nmul ft0.xyz, ft0.xyz, fc0.xxx\nfrc ft1.xyz, ft0.xyz\nsub ft0.xyz, ft0.xyz, ft1.xyz\nmul ft0.xyz, ft0.xyz, fc0.yyy\nmov ft0.w, fc0.w\nmov oc, ft0\n";

        var assembler = new AGALMiniAssembler(); return assembler.assemble2(context, 1, vSource, fSource);

    }



    private function drawPosterize(mesh:Mesh3D, surface:Surface3D, camera:Camera3D):Void {

        var context = Device3D.context;

        if (context == null || surface == null) return;

        if (_posterizeProgram == null) _posterizeProgram = buildPosterizeShader(context);

        if (_posterizeProgram == null) return;



        surface.upload(context);

        if (surface.vertexBuffer == null || surface.indexBuffer == null) return;



        Device3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);

        Device3D.setDepthTest(false, Context3DCompareMode.ALWAYS);

        Device3D.setCulling(Context3DTriangleFace.NONE);

        Device3D.setProgram(_posterizeProgram);

        Device3D.setVertexBuffers(surface.vertexBuffer, surface);



        if (mesh != null) _postMvp.copyFrom(mesh.world); else _postMvp.identity();

        context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, _postMvp, true);



        var numC = (params != null) ? getParamFloat(params.numColors, 8.0) : 8.0;

        if (Math.isNaN(numC) || numC <= 1.0) numC = 8.0;

        _postConst0[0] = numC; _postConst0[1] = 1.0 / numC; _postConst0[2] = 0.0; _postConst0[3] = 1.0;

        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _postConst0);



        var tex = (_targetTex != null) ? _targetTex.texture : null;

        if (tex != null) context.setTextureAt(0, tex);



        Device3D.drawCalls++;

        Device3D.triangles += surface.numTriangles;

        context.drawTriangles(surface.indexBuffer, 0, surface.numTriangles);

        context.setTextureAt(0, null);

        Device3D.currentMesh = null;

    }



    private function buildDreamShader(context:Context3D):Program3D {

        var vSource = "m44 op, va0, vc0\nmov v0, va1\n";

        var fSource = "tex ft0, v0, fs0 <2d,linear,mipnone,clamp>\n" +

            "add ft1, v0, fc0.xxxx\ntex ft2, ft1, fs0 <2d,linear,mipnone,clamp>\nadd ft0, ft0, ft2\n" +

            "sub ft1, v0, fc0.xxxx\ntex ft2, ft1, fs0 <2d,linear,mipnone,clamp>\nadd ft0, ft0, ft2\n" +

            "add ft1, v0, fc0.yyyy\ntex ft2, ft1, fs0 <2d,linear,mipnone,clamp>\nadd ft0, ft0, ft2\n" +

            "sub ft1, v0, fc0.yyyy\ntex ft2, ft1, fs0 <2d,linear,mipnone,clamp>\nadd ft0, ft0, ft2\n" +

            "add ft1, v0, fc0.zzzz\ntex ft2, ft1, fs0 <2d,linear,mipnone,clamp>\nadd ft0, ft0, ft2\n" +

            "sub ft1, v0, fc0.zzzz\ntex ft2, ft1, fs0 <2d,linear,mipnone,clamp>\nadd ft0, ft0, ft2\n" +

            "add ft1, v0, fc0.wwww\ntex ft2, ft1, fs0 <2d,linear,mipnone,clamp>\nadd ft0, ft0, ft2\n" +

            "sub ft1, v0, fc0.wwww\ntex ft2, ft1, fs0 <2d,linear,mipnone,clamp>\nadd ft0, ft0, ft2\n" +

            "add ft1, v0, fc1.xxxx\ntex ft2, ft1, fs0 <2d,linear,mipnone,clamp>\nadd ft0, ft0, ft2\n" +

            "sub ft1, v0, fc1.xxxx\ntex ft2, ft1, fs0 <2d,linear,mipnone,clamp>\nadd ft0, ft0, ft2\n" +

            "add ft1, v0, fc1.yyyy\ntex ft2, ft1, fs0 <2d,linear,mipnone,clamp>\nadd ft0, ft0, ft2\n" +

            "sub ft1, v0, fc1.yyyy\ntex ft2, ft1, fs0 <2d,linear,mipnone,clamp>\nadd ft0, ft0, ft2\n" +

            "dp3 ft1.x, ft0.xyz, fc2.xyz\n" +

            "mul ft0.xyz, ft1.xxx, fc2.www\n" +

            "mov ft0.w, fc1.w\n" +

            "mov oc, ft0\n";

        var assembler = new AGALMiniAssembler(); return assembler.assemble2(context, 1, vSource, fSource);

    }



    private function drawDream(mesh:Mesh3D, surface:Surface3D, camera:Camera3D):Void {

        var context = Device3D.context;

        if (context == null || surface == null) return;

        if (_dreamProgram == null) _dreamProgram = buildDreamShader(context);

        if (_dreamProgram == null) return;



        surface.upload(context);

        if (surface.vertexBuffer == null || surface.indexBuffer == null) return;



        Device3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);

        Device3D.setDepthTest(false, Context3DCompareMode.ALWAYS);

        Device3D.setCulling(Context3DTriangleFace.NONE);

        Device3D.setProgram(_dreamProgram);

        Device3D.setVertexBuffers(surface.vertexBuffer, surface);



        if (mesh != null) _postMvp.copyFrom(mesh.world); else _postMvp.identity();

        context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, _postMvp, true);

        _postConst0[0] = 0.001; _postConst0[1] = 0.003; _postConst0[2] = 0.005; _postConst0[3] = 0.007;

        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _postConst0);

        _postConst1[0] = 0.009; _postConst1[1] = 0.011; _postConst1[2] = 0.0; _postConst1[3] = 1.0;

        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, _postConst1);

        _postConst2[0] = 0.3333333; _postConst2[1] = 0.3333333; _postConst2[2] = 0.3333333; _postConst2[3] = 1.0 / 9.5;

        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, _postConst2);



        var tex = (_targetTex != null) ? _targetTex.texture : null;

        if (tex != null) context.setTextureAt(0, tex);



        Device3D.drawCalls++;

        Device3D.triangles += surface.numTriangles;

        context.drawTriangles(surface.indexBuffer, 0, surface.numTriangles);

        context.setTextureAt(0, null);

        Device3D.currentMesh = null;

    }




    private function buildNightVisionShader(context:Context3D):Program3D {
        var vSource = "m44 op, va0, vc0\nmov v0, va1\n";
        var fSource = 
            "tex ft0, v0, fs0 <2d,linear,mipnone,clamp>\n" +
            "dp3 ft1.x, ft0, fc0\n" +
            "mov ft0.xyz, ft1.xxx\n" +
            "mul ft0.xyz, ft0.xyz, fc1.xyz\n" +
            "sat ft0.xyz, ft0.xyz\n" +
            "mul ft2.xy, v0.xy, fc2.xy\n" +
            "add ft2.xy, ft2.xy, fc2.zw\n" +
            "tex ft3, ft2, fs1 <2d,linear,mipnone,repeat>\n" +
            "mul ft0.xyz, ft0.xyz, ft3.xyz\n" +
            "mov ft0.w, fc1.w\n" +
            "mov oc, ft0\n";
        var assembler = new AGALMiniAssembler();
        return assembler.assemble2(context, 1, vSource, fSource);
    }

    private function drawNightVision(mesh:Mesh3D, surface:Surface3D, camera:Camera3D):Void {
        var context = Device3D.context;
        if (context == null || surface == null) return;
        if (_nightVisionProgram == null) _nightVisionProgram = buildNightVisionShader(context);
        if (_nightVisionProgram == null) return;

        surface.upload(context);
        if (surface.vertexBuffer == null || surface.indexBuffer == null) return;

        if (_nightVisionNoiseTex == null) {
            _nightVisionNoiseTex = new Texture3D("noise.png", true);
        }
        if (_nightVisionNoiseTex.texture == null) {
            _nightVisionNoiseTex.upload(flare.system.Device3D.scene);
        }

        Device3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
        Device3D.setDepthTest(false, Context3DCompareMode.ALWAYS);
        Device3D.setCulling(Context3DTriangleFace.NONE);
        Device3D.setProgram(_nightVisionProgram);
        Device3D.setVertexBuffers(surface.vertexBuffer, surface);

        if (mesh != null) _postMvp.copyFrom(mesh.world); else _postMvp.identity();
        context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, _postMvp, true);

        // fc0: Luminance weights dot(0.30, 0.59, 0.11, 0.0)
        _postConst0[0] = 0.30; _postConst0[1] = 0.59; _postConst0[2] = 0.11; _postConst0[3] = 0.0;
        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _postConst0);

        // fc1: Phosphor color tint (default: 0.1, 1.55, 0.2, 1.0)
        _postConst1[0] = 0.1; _postConst1[1] = 1.55; _postConst1[2] = 0.2; _postConst1[3] = 1.0;
        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, _postConst1);

        // fc2: Noise scale (5.0, 5.0) and random offset (random.x, random.y)
        _postConst2[0] = 5.0;
        _postConst2[1] = 5.0;
        _postConst2[2] = (flare.system.Device3D.random != null && flare.system.Device3D.random.length > 0) ? flare.system.Device3D.random[0] : Math.random();
        _postConst2[3] = (flare.system.Device3D.random != null && flare.system.Device3D.random.length > 1) ? flare.system.Device3D.random[1] : Math.random();
        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, _postConst2);

        var tex = (_targetTex != null) ? _targetTex.texture : null;
        if (tex != null) context.setTextureAt(0, tex);
        if (_nightVisionNoiseTex != null && _nightVisionNoiseTex.texture != null) {
            context.setTextureAt(1, _nightVisionNoiseTex.texture);
        }

        Device3D.drawCalls++;
        Device3D.triangles += surface.numTriangles;
        context.drawTriangles(surface.indexBuffer, 0, surface.numTriangles);
        context.setTextureAt(0, null);
        context.setTextureAt(1, null);
        Device3D.currentMesh = null;
    }

}
