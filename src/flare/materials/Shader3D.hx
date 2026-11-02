package flare.materials;

import openfl.Vector;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DBlendFactor;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Context3DVertexBufferFormat;
import openfl.display3D.Program3D;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import openfl.utils.AGALMiniAssembler;
import flare.core.Camera3D;
import flare.core.Mesh3D;
import flare.core.Surface3D;
import flare.core.Texture3D;
import flare.materials.filters.AlphaMaskFilter;
import flare.materials.filters.ColorFilter;
import flare.materials.filters.EnvironmentMapFilter;
import flare.materials.filters.Filter3D;
import flare.materials.filters.LightFilter;
import flare.materials.filters.SpecularFilter;
import flare.materials.filters.SpecularMapFilter;
import flare.materials.filters.TextureMapFilter;
import flare.system.Device3D;

class LightScoreItem {
    public var light:flare.core.Light3D;
    public var score:Float;
    public function new() {
        this.score = 0.0;
    }
}

/**
 * Shader3D generates and executes AGAL vertex and fragment shaders from modular filters.
 */
class Shader3D extends Material3D {
    public static var VERTEX_SKIN:Dynamic = null;
    public static var VERTEX_NORMAL:Dynamic = null;
    public var filters(get, set):Array<Filter3D>;
    private var _filters:Array<Filter3D> = [];

    public var enableLights:Bool = true;
    public var program:Program3D;

    public var texFilters:Array<TextureMapFilter> = [];
    public var colorFilter:ColorFilter;
    public var lightFilter:LightFilter;
    public var envFilter:EnvironmentMapFilter;
    public var specularFilter:SpecularFilter;
    public var specularMapFilter:SpecularMapFilter;
    public var alphaMaskFilter:AlphaMaskFilter;
    public var vertexColorFilter:flare.materials.filters.VertexColorFilter;
    public var normalMapFilter:flare.materials.filters.NormalMapFilter;
    public var cubeMapFilter:flare.materials.filters.CubeMapFilter;
    public var lightMapFilter:flare.materials.filters.LightMapFilter;
    public var edgeFilter:flare.materials.filters.EdgeFilter;
    public var flslFilter:flare.flsl.FLSLFilter;
    public var outlineProgram:Program3D;
    private var _outlineParams:Vector<Float> = new Vector<Float>(4);
    private var _outlineColor:Vector<Float> = new Vector<Float>(4);
    private var _lastLightMap:flare.core.Texture3D;
    private var _cubeMapParams:openfl.Vector<Float> = new openfl.Vector<Float>(4);
    private var _rotateConsts:openfl.Vector<Float> = openfl.Vector.ofArray([1.0, 0.0, 0.0, 0.5]);

    public function hasScreenProjTexture():Bool {
        return flslFilter != null && (flslFilter.isScreenProj || (flslFilter.name == "screenProj" || (flslFilter.source != null && Std.string(flslFilter.source).indexOf("screenProj") != -1)));
    }

    public function hasRotateTexture():Bool {
        return flslFilter != null && !hasScreenProjTexture() && (flslFilter.isRotateTexture || (flslFilter.name == "rotateTexture" || (flslFilter.source != null && Std.string(flslFilter.source).indexOf("rotate") != -1)));
    }

    public var programLit:Program3D;
    public var programUnlit:Program3D;

    private static var _helperConsts:Vector<Float> = new Vector<Float>(4);
    private static var _pointPosVector:Vector<Float> = new Vector<Float>(4);
    private static var _pointColorVector:Vector<Float> = new Vector<Float>(4);

    private static var _lastLightingFrame:Int = -1;
    private static var _lastLightingTech:String = null;
    private static var _lastLightingProgram:Program3D = null;
    private static var _globalLightingData:Vector<Float> = new Vector<Float>(12); // fc1, fc2, fc3 (3 registers)
    private static var _pointLightsData:Vector<Float> = new Vector<Float>(32);    // fc10..fc17 (8 registers: 4 point lights)
    private static var _scorePool:Array<LightScoreItem> = [];
    private static var _scoreItems:Array<LightScoreItem> = [];
    private static var _lastMeshProgram:Program3D = null;
    private static var _lastCamera:flare.core.Camera3D = null;

    private var _cachedActiveLight:flare.core.Light3D;
    private var _mvp:Matrix3D = new Matrix3D();
    private var _worldView:Matrix3D = new Matrix3D();

    private var _colorVector:Vector<Float> = new Vector<Float>(4);
    private var _lightDirVector:Vector<Float> = new Vector<Float>(4);
    private var _lightColorVector:Vector<Float> = new Vector<Float>(4);
    private var _ambientVector:Vector<Float> = new Vector<Float>(4);
    private var _texParams:Vector<Float> = new Vector<Float>(4);
    private var _envParams:Vector<Float> = new Vector<Float>(4);
    private var _maskParams:Vector<Float> = new Vector<Float>(4);
    private var _specParams:Vector<Float> = new Vector<Float>(4);
    private var _specLevel:Vector<Float> = new Vector<Float>(4);
    private var _sphereConst:Vector<Float> = new Vector<Float>(4);
    private var _normalParams:Vector<Float> = new Vector<Float>(4);
    private var _normalUpParams:Vector<Float> = new Vector<Float>(4);
    private var _specMapParams:Vector<Float> = new Vector<Float>(4);
    private var _texCoordParams:Vector<Float> = new Vector<Float>(4);
    private var _eyePosVector:Vector<Float> = new Vector<Float>(4);
    private var _lastTexture0:flare.core.Texture3D = null;

    public function new(name:String = "shader", filters:Array<Filter3D> = null, enableLights:Bool = true, transform:Dynamic = null) {
        super(name);
        this.enableLights = enableLights;
        this.filters = filters != null ? filters : [];
    }

    private inline function get_filters():Array<Filter3D> {
        return _filters;
    }

    private function set_filters(value:Array<Filter3D>):Array<Filter3D> {
        _filters = value != null ? value : [];
        updateFilterRefs();
        program = null;
        return _filters;
    }

    public function updateFilterRefs():Void {
        texFilters = [];
        colorFilter = null;
        lightFilter = null;
        envFilter = null;
        specularFilter = null;
        specularMapFilter = null;
        alphaMaskFilter = null;
        vertexColorFilter = null;
        normalMapFilter = null;
        cubeMapFilter = null;
        lightMapFilter = null;
        edgeFilter = null;
        flslFilter = null;
        if (_filters != null) {
            for (f in _filters) {
                if (Std.isOfType(f, TextureMapFilter)) texFilters.push(cast f);
                else if (Std.isOfType(f, ColorFilter)) colorFilter = cast f;
                else if (Std.isOfType(f, LightFilter)) lightFilter = cast f;
                else if (Std.isOfType(f, EnvironmentMapFilter)) envFilter = cast f;
                else if (Std.isOfType(f, SpecularMapFilter)) specularMapFilter = cast f;
                else if (Std.isOfType(f, SpecularFilter)) specularFilter = cast f;
                else if (Std.isOfType(f, AlphaMaskFilter)) alphaMaskFilter = cast f;
                else if (Std.isOfType(f, flare.materials.filters.VertexColorFilter)) vertexColorFilter = cast f;
                else if (Std.isOfType(f, flare.materials.filters.NormalMapFilter)) normalMapFilter = cast f;
                else if (Std.isOfType(f, flare.materials.filters.CubeMapFilter)) cubeMapFilter = cast f;
                else if (Std.isOfType(f, flare.materials.filters.ReflectionMapFilter)) {
                    var rmf:flare.materials.filters.ReflectionMapFilter = cast f;
                    if (rmf.texture != null && rmf.texture.type == Texture3D.TYPE_CUBE) {
                        cubeMapFilter = new flare.materials.filters.CubeMapFilter(rmf.texture, rmf.level, rmf.blendMode);
                    } else if (rmf.texture != null) {
                        envFilter = new flare.materials.filters.EnvironmentMapFilter(rmf.texture, rmf.blendMode);
                    }
                }
                else if (Std.isOfType(f, flare.materials.filters.LightMapFilter)) lightMapFilter = cast f;
                else if (Std.isOfType(f, flare.materials.filters.EdgeFilter)) edgeFilter = cast f;
                else if (Std.isOfType(f, flare.flsl.FLSLFilter)) {
                    flslFilter = cast f;
                    if (flslFilter.edgeFilter != null) edgeFilter = flslFilter.edgeFilter;
                }
            }
        }
    }

    public function addFilter(filter:Filter3D):Filter3D {
        if (_filters == null) _filters = [];
        _filters.push(filter);
        updateFilterRefs();
        program = null;
        return filter;
    }

    public function update():Void {
        build();
    }

    public function build(context:Context3D = null):Void {
        if (context == null) context = Device3D.context;
        if (context == null) return;

        updateFilterRefs();
        programLit = buildShader(context, true);
        programUnlit = buildShader(context, false);
        program = programLit != null ? programLit : programUnlit;

        if (edgeFilter != null) {
            var vOutlineAgal = 
                "dp3 vt1.x, va2.xyz, va2.xyz\n" +
                "rsq vt1.x, vt1.x\n" +
                "mul vt1.xyz, va2.xyz, vt1.xxx\n" +
                "mul vt0.xyz, vt1.xyz, vc4.xxx\n" +
                "add vt0.xyz, va0.xyz, vt0.xyz\n" +
                "mov vt0.w, va0.w\n" +
                "m44 vt2, vt0, vc0\n" +
                "mul vt1.x, vt2.w, vc4.w\n" +
                "add vt2.z, vt2.z, vt1.x\n" +
                "mov op, vt2\n";
            var fOutlineAgal = "mov oc, fc0\n";

            try {
                var vAssembler = new AGALMiniAssembler();
                vAssembler.assemble(Context3DProgramType.VERTEX, vOutlineAgal);
                var fAssembler = new AGALMiniAssembler();
                fAssembler.assemble(Context3DProgramType.FRAGMENT, fOutlineAgal);

                if (outlineProgram != null) outlineProgram.dispose();
                outlineProgram = context.createProgram();
                outlineProgram.upload(vAssembler.agalcode, fAssembler.agalcode);
            } catch (e:Dynamic) {
                trace("[Shader3D] Failed to compile outlineProgram: " + e);
            }
        } else if (outlineProgram != null) {
            outlineProgram.dispose();
            outlineProgram = null;
        }
    }

    private function buildShader(context:Context3D, withLights:Bool):Program3D {
        var hasVertexColor = vertexColorFilter != null;
        var hasNormalMap = normalMapFilter != null && (normalMapFilter.normalMap != null || normalMapFilter.texture != null);
        var hasTexture = texFilters.length > 0;
        var hasSecondTexture = texFilters.length > 1;
        var hasEnv = envFilter != null && envFilter.texture != null;
        var hasSpecularMap = specularMapFilter != null && (specularMapFilter.specularMap != null || specularMapFilter.texture != null);
        var hasSpecular = specularFilter != null || hasSpecularMap;
        var hasAlphaMask = alphaMaskFilter != null;
        var hasColor = colorFilter != null;
        var hasLightMap = lightMapFilter != null && lightMapFilter.texture != null;

        var sceneLights = (Device3D.scene != null) ? Device3D.scene.lights : null;
        var activeCubeMap = (cubeMapFilter != null && cubeMapFilter.cubeMap != null) ? cubeMapFilter.cubeMap : 
                            ((lightFilter != null && lightFilter.cubeMap != null) ? lightFilter.cubeMap : 
                            ((sceneLights != null) ? sceneLights.cubeMap : null));
        var hasCubeMap = activeCubeMap != null;
        var hasLightMap = lightMapFilter != null && lightMapFilter.texture != null;
        var hasRotate = hasRotateTexture();
        var hasScreenProj = hasScreenProjTexture();
        var hasLight = withLights && enableLights && (lightFilter != null || hasSpecular || hasNormalMap || hasCubeMap || hasLightMap || (hasTexture && !hasEnv));

        var nextSampler = 0;
        var screenProjSampler = hasScreenProj ? ("fs" + (nextSampler++)) : null;
        var rotSampler = hasRotate ? ("fs" + (nextSampler++)) : null;
        var diffSampler = hasTexture ? ("fs" + (nextSampler++)) : null;
        var secondSampler = hasSecondTexture ? ("fs" + (nextSampler++)) : null;
        var normSampler = hasNormalMap ? ("fs" + (nextSampler++)) : null;
        var envSampler = hasEnv ? ("fs" + (nextSampler++)) : null;
        var specSampler = hasSpecularMap ? ("fs" + (nextSampler++)) : null;
        var cubeSampler = hasCubeMap ? ("fs" + (nextSampler++)) : null;
        var lightMapSampler = hasLightMap ? ("fs" + (nextSampler++)) : null;

        // 1. Vertex Shader (AGAL)
        var vSource = 
            "m44 op, va0, vc0\n" +         // Model-View-Projection screen transform
            "mul vt0.xy, va1.xy, vc15.xy\n" + // UV repeat scale (vc15.xy)
            "add v0.xy, vt0.xy, vc15.zw\n" +  // UV offset (vc15.zw)
            "mov v0.zw, va1.zw\n" +
            "m44 v2, va0, vc4\n" +         // transform vertex position by World matrix into world space
            (hasLight || hasEnv ? "m33 v1.xyz, va2.xyz, vc4\n" : "") + // transform normal by World 3x3 rotation if lit
            "mov v1.w, va0.w\n";

        if (hasScreenProj) {
            // pass clip space coordinates for screen projective texture mapping
            vSource += "m44 v3, va0, vc0\n";
        }

        if (hasRotate) {
            // vc16 = [cos, sin, -sin, 0.5]
            // v3 = rotated UV (iuv)
            vSource +=
                "sub vt0.xy, va1.xy, vc16.ww\n" +
                "mul vt1.x, vt0.x, vc16.x\n" +
                "mul vt1.y, vt0.y, vc16.z\n" +
                "add vt2.x, vt1.x, vt1.y\n" +
                "mul vt1.x, vt0.x, vc16.y\n" +
                "mul vt1.y, vt0.y, vc16.x\n" +
                "add vt2.y, vt1.x, vt1.y\n" +
                "add v3.xy, vt2.xy, vc16.ww\n" +
                "mov v3.zw, va1.zw\n";
        }

        if (hasVertexColor) {
            vSource += "mov v4, va3\n";    // pass vertex color to fragment shader
        }

        if (hasLightMap) {
            vSource += "mov v7, va3\n";    // pass lightmap UV (UV2) to fragment shader
        }

        if (hasNormalMap) {
            // vc13 = [repeatX, repeatY, 0, 0]
            vSource += 
                "mul v5.xy, va1.xy, vc13.xy\n" +
                "mov v5.zw, va0.ww\n";
        }

        if (hasSpecularMap) {
            // vc14 = [repeatX, repeatY, 0, 0]
            vSource += 
                "mul v6.xy, va1.xy, vc14.xy\n" +
                "mov v6.zw, va1.zw\n";
        }

        if (hasEnv) {
            // Calculate sphere map UV in vertex shader from normal in view space
            // vc8 = ModelView matrix 3x3
            // vc12 = [0.5, -0.5, 0.5, 0.5]
            vSource +=
                "m33 vt0.xyz, va2.xyz, vc8\n" +
                "mul vt1.xy, vt0.xy, vc12.xy\n" +
                "add v3.xy, vt1.xy, vc12.zw\n" +
                "mov v3.zw, va0.ww\n";
        }

        // 2. Fragment Shader (AGAL)
        var fSource = "";

        // Base color ft0
        if (hasScreenProj) {
            fSource +=
                "div ft0.xy, v3.xy, v3.ww\n" +
                "mul ft0.xy, ft0.xy, fc16.xy\n" +
                "add ft0.xy, ft0.xy, fc16.zw\n" +
                "tex ft0, ft0.xy, " + screenProjSampler + " <2d,linear,mipnone,clamp>\n";
            if (hasTexture) {
                fSource += "tex ft1, v0, " + diffSampler + " <2d,linear,mipnone,repeat>\n";
                fSource += "mul ft0.xyz, ft0.xyz, ft1.xyz\n";
            }
        } else if (hasRotate) {
            fSource += "tex ft0, v3, " + rotSampler + " <2d,linear,mipnone,clamp>\n";
            if (hasTexture) {
                fSource += "tex ft1, v0, " + diffSampler + " <2d,linear,mipnone,repeat>\n";
                fSource += "mul ft0.xyz, ft0.xyz, ft1.xyz\n";
            }
        } else if (hasTexture) {
            fSource += "tex ft0, v0, " + diffSampler + " <2d,linear,mipnone,repeat>\n";
            if (hasSecondTexture) {
                // Secondary texture with alpha blend over primary
                fSource += 
                    "tex ft1, v0, " + secondSampler + " <2d,linear,mipnone,repeat>\n" +
                    "sub ft2.xyz, ft1.xyz, ft0.xyz\n" +
                    "mul ft2.xyz, ft2.xyz, ft1.www\n" +
                    "add ft0.xyz, ft0.xyz, ft2.xyz\n" +
                    "max ft0.w, ft0.w, ft1.w\n";
            }
        } else if (hasColor) {
            fSource += "mov ft0, fc0\n";
        } else {
            fSource += "mov ft0, fc0\n";
        }

        // VertexColorFilter modulation
        if (hasVertexColor) {
            fSource += "mul ft0, ft0, v4\n";
        }

        // LightMap handled in direct sun lighting pass

        // Environment Map Filter
        if (hasEnv) {
            var isEnvMultiply = (envFilter != null && (envFilter.blendMode == BlendMode.MULTIPLY || envFilter.blendMode == "multiply"));
            var envUvReg = "v3";
            if (hasNormalMap) {
                // Perturb environment reflection UV by normal map disturbance
                fSource += 
                    "tex ft2, v5, " + normSampler + " <2d,linear,mipnone,repeat>\n" +
                    "sub ft2.xyz, ft2.xyz, fc4.zzz\n" + // ft2 - 0.5
                    "mul ft2.xy, ft2.xy, fc4.zzz\n" +   // scale disturbance by 0.5
                    "add ft3.xy, v3.xy, ft2.xy\n";     // perturbed reflection UV
                envUvReg = "ft3";
            }
            if (!hasTexture) {
                // Glass / Helmet reflection without diffuse map
                fSource += 
                    "tex ft0, " + envUvReg + ", " + envSampler + " <2d,linear,mipnone,repeat>\n" +
                    "mul ft0.xyz, ft0.xyz, fc5.xxx\n"; // multiply by intensity
            } else {
                if (isEnvMultiply) {
                    fSource += 
                        "tex ft1, " + envUvReg + ", " + envSampler + " <2d,linear,mipnone,repeat>\n" +
                        "mul ft1.xyz, ft1.xyz, fc5.xxx\n" +
                        "mul ft0.xyz, ft0.xyz, ft1.xyz\n"; // multiplicative reflection
                } else {
                    fSource += 
                        "tex ft1, " + envUvReg + ", " + envSampler + " <2d,linear,mipnone,repeat>\n" +
                        "mul ft1.xyz, ft1.xyz, fc5.xxx\n" +
                        "add ft0.xyz, ft0.xyz, ft1.xyz\n"; // additive reflection
                }
            }
        }

        // ColorFilter tinting
        if (hasColor && hasTexture) {
            fSource += 
                "mul ft0.xyz, ft0.xyz, fc0.xyz\n" +
                "mul ft0.w, ft0.w, fc0.w\n";
        }

        // Primary texture alpha modifier
        fSource += "mul ft0.w, ft0.w, fc4.x\n";

        // Alpha Mask Filter
        if (hasAlphaMask) {
            fSource += 
                "sub ft3.w, ft0.w, fc6.x\n" +
                "kil ft3.w\n";
        }

        // Lighting
        if (hasLight) {
            // Normalize interpolated world normal
            fSource += "nrm ft3.xyz, v1.xyz\n";

            if (hasNormalMap) {
                // Sample tangent/normal map and construct orthonormal surface tangent basis:
                // Tangent T = cross((0, 1, 0), N) + cross((0, 0, 1), N) -> robust for any normal including horizontal plane (0, 1, 0)
                fSource += 
                    "tex ft2, v5, " + normSampler + " <2d,linear,mipnone,repeat>\n" +
                    "sub ft2.xyz, ft2.xyz, fc4.zzz\n" + // ft2 - 0.5
                    "add ft2.xyz, ft2.xyz, ft2.xyz\n" + // * 2 -> [-1, 1]
                    "crs ft4.xyz, fc9.yxy, ft3.xyz\n" + // cross((0,1,0), N)
                    "crs ft5.xyz, fc9.yyx, ft3.xyz\n" + // cross((0,0,1), N)
                    "add ft4.xyz, ft4.xyz, ft5.xyz\n" +
                    "nrm ft4.xyz, ft4.xyz\n" +          // T
                    "crs ft5.xyz, ft3.xyz, ft4.xyz\n" + // B = cross(N, T)
                    "nrm ft5.xyz, ft5.xyz\n" +          // B
                    "mul ft4.xyz, ft4.xyz, ft2.xxx\n" +
                    "mul ft5.xyz, ft5.xyz, ft2.yyy\n" +
                    "add ft4.xyz, ft4.xyz, ft5.xyz\n" +
                    "mul ft4.xyz, ft4.xyz, fc19.www\n" +
                    "add ft3.xyz, ft3.xyz, ft4.xyz\n" +
                    "nrm ft3.xyz, ft3.xyz\n";
            }

            // Primary Sun Directional Light (fc1, fc2) with standard Lambert diffuse + Ambient (fc3)
            if (hasLightMap) {
                fSource += 
                    "dp3 ft1.x, ft3.xyz, fc1.xyz\n" +   // N dot L_sun
                    "max ft1.x, ft1.x, fc9.y\n" +       // clamp to >= 0
                    "mul ft2.xyz, fc2.xyz, ft1.xxx\n" + // diffuse = sunColor * NdotL
                    "tex ft7, v7, " + lightMapSampler + " <2d,linear,mipnone,clamp>\n" +
                    "mul ft2.xyz, ft2.xyz, ft7.xyz\n" + // mask direct sun by shadowmap
                    "add ft2.xyz, ft2.xyz, fc3.xyz\n";  // add ambient
            } else {
                fSource += 
                    "dp3 ft1.x, ft3.xyz, fc1.xyz\n" +   // N dot L_sun
                    "max ft1.x, ft1.x, fc9.y\n" +       // clamp to >= 0
                    "mul ft2.xyz, fc2.xyz, ft1.xxx\n" + // diffuse = sunColor * NdotL
                    "add ft2.xyz, ft2.xyz, fc3.xyz\n";  // add ambient
            }

            if (hasSpecular || hasCubeMap) {
                fSource += 
                    "mov ft1.xyz, fc9.yyy\n" +                  // clear specular accumulator to 0
                    "sub ft6.xyz, fc6.xyz, v2.xyz\n" +          // V = camPos - worldPos
                    "nrm ft6.xyz, ft6.xyz\n";                   // normalize V
            }

            // Up to 4 closest active point lights (fc10..fc17)
            for (k in 0...4) {
                var pPos = "fc" + (10 + 2 * k);
                var pCol = "fc" + (11 + 2 * k);
                fSource += 
                    "sub ft4.xyz, " + pPos + ".xyz, v2.xyz\n" + // L = lightPos - worldPos
                    "dp3 ft5.x, ft4.xyz, ft4.xyz\n" +           // distSq
                    "sqt ft5.y, ft5.x\n" +                      // dist
                    "max ft5.y, ft5.y, fc9.z\n" +               // clamp dist >= 0.001
                    "mul ft5.z, ft5.y, " + pPos + ".w\n" +      // distNorm = dist / radius
                    "sub ft5.w, fc9.x, ft5.z\n" +               // 1.0 - distNorm (linear)
                    "max ft5.w, ft5.w, fc9.y\n" +               // clamp >= 0
                    "mul ft5.z, ft5.w, ft5.w\n" +               // quadratic = linear * linear
                    "sub ft5.z, ft5.z, ft5.w\n" +               // quadratic - linear
                    "mul ft5.z, ft5.z, fc9.w\n" +               // blend factor by technique mode
                    "add ft5.w, ft5.w, ft5.z\n" +               // final attenuation
                    "div ft4.xyz, ft4.xyz, ft5.yyy\n" +         // normalize L
                    "dp3 ft4.w, ft3.xyz, ft4.xyz\n";           // N dot L

                if (hasSpecular) {
                    fSource += 
                        "add ft7.xyz, ft4.xyz, ft6.xyz\n" +     // H = L + V
                        "nrm ft7.xyz, ft7.xyz\n" +             // normalize H
                        "dp3 ft7.w, ft3.xyz, ft7.xyz\n" +       // N dot H
                        "max ft7.w, ft7.w, fc9.y\n" +           // clamp >= 0
                        "pow ft7.w, ft7.w, fc7.w\n" +           // pow(NdotH, power)
                        "mul ft7.w, ft7.w, ft5.w\n" +           // atten
                        "mul ft7.w, ft7.w, fc8.x\n" +           // level
                        "mul ft7.xyz, " + pCol + ".xyz, ft7.www\n" + // specColor = lightColor * factor
                        "add ft1.xyz, ft1.xyz, ft7.xyz\n";      // accumulate
                }

                fSource += 
                    "max ft4.w, ft4.w, fc9.y\n" +               // clamp >= 0
                    "mul ft4.w, ft4.w, ft5.w\n" +               // factor = atten * NdotL
                    "mul ft4.xyz, " + pCol + ".xyz, ft4.www\n" + // color * factor
                    "add ft2.xyz, ft2.xyz, ft4.xyz\n";          // accumulate
            }

            // CubeMap reflection lighting (R = 2 * (N . V) * N - V)
            if (hasCubeMap) {
                fSource += 
                    "dp3 ft7.x, ft3.xyz, ft6.xyz\n" +           // N dot V
                    "add ft7.y, ft7.x, ft7.x\n" +               // 2 * (N dot V)
                    "mul ft7.xyz, ft3.xyz, ft7.yyy\n" +         // 2 * (N dot V) * N
                    "sub ft7.xyz, ft7.xyz, ft6.xyz\n" +         // R = 2*(N.V)*N - V
                    "tex ft4, ft7.xyz, " + cubeSampler + " <cube,linear,mipnone,clamp>\n" +
                    "mul ft4.xyz, ft4.xyz, fc18.xxx\n";         // reflection * level
            }

            if (hasSpecular) {
                fSource += 
                    "dp3 ft5.x, ft3.xyz, fc7.xyz\n" +
                    "max ft5.x, ft5.x, fc9.y\n" +
                    "pow ft5.x, ft5.x, fc7.w\n" +
                    "mul ft5.xyz, fc8.yzw, ft5.xxx\n" +
                    "mul ft5.xyz, ft5.xyz, fc8.xxx\n" +
                    "add ft5.xyz, ft5.xyz, ft1.xyz\n";

                if (hasSpecularMap) {
                    // Sample specular color map and modulate specular reflection
                    fSource += 
                        "tex ft7, v6, " + specSampler + " <2d,linear,mipnone,repeat>\n" +
                        "mul ft5.xyz, ft5.xyz, ft7.xyz\n";
                }
            }

            fSource += "mul ft0.xyz, ft0.xyz, ft2.xyz\n";
            if (hasCubeMap) {
                fSource += "add ft0.xyz, ft0.xyz, ft4.xyz\n";
            }
            if (hasSpecular) {
                fSource += "add ft0.xyz, ft0.xyz, ft5.xyz\n";
            }
        }

        // For non-transparent opaque materials, enforce solid alpha = 1.0 using fc4.w
        if (!transparent) {
            fSource += "mov ft0.w, fc4.w\n";
        }

        fSource += "sat ft0.xyz, ft0.xyz\n";
        fSource += "mov oc, ft0\n";

        var assembler = new AGALMiniAssembler();
        return assembler.assemble2(context, 1, vSource, fSource);
    }

    override public function draw(mesh:Mesh3D, surface:Surface3D, camera:Camera3D):Void {
        var context = Device3D.context;
        if (context == null || surface == null) return;

        if (program == null) {
            build(context);
            if (program == null) return;
        }

        surface.upload(context);
        if (surface.vertexBuffer == null || surface.indexBuffer == null) return;

        var isAdditive = (sourceFactor == Context3DBlendFactor.ONE && destFactor == Context3DBlendFactor.ONE);
        var hasAlpha = transparent && (sourceFactor == Context3DBlendFactor.SOURCE_ALPHA || (texFilters.length > 0 && texFilters[0].alpha < 0.999));
        if (isAdditive) {
            Device3D.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ONE);
            Device3D.setDepthTest(false, depthCompare);
        } else if (hasAlpha) {
            Device3D.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
            Device3D.setDepthTest(depthWrite, depthCompare);
        } else {
            Device3D.setBlendFactors(sourceFactor, destFactor);
            Device3D.setDepthTest(depthWrite, depthCompare);
        }
        Device3D.setCulling(twoSided ? openfl.display3D.Context3DTriangleFace.NONE : cullFace);

        var hasEnv = envFilter != null && envFilter.texture != null;
        var sceneLights = (Device3D.scene != null) ? Device3D.scene.lights : null;
        var activeCubeMap = (cubeMapFilter != null && cubeMapFilter.cubeMap != null) ? cubeMapFilter.cubeMap : 
                            ((lightFilter != null && lightFilter.cubeMap != null) ? lightFilter.cubeMap : 
                            ((sceneLights != null) ? sceneLights.cubeMap : null));
        var hasCubeMap = activeCubeMap != null;
        var hasLightMap = lightMapFilter != null && lightMapFilter.texture != null;
        var tech = (sceneLights != null && sceneLights.techniqueName != null) ? sceneLights.techniqueName : 
                   ((lightFilter != null && lightFilter.techniqueName != null) ? lightFilter.techniqueName : LightFilter.SAMPLED);
        var isLit = enableLights && (lightFilter != null || normalMapFilter != null || specularFilter != null || specularMapFilter != null || hasCubeMap || hasLightMap || !hasEnv) && (tech != LightFilter.NO_LIGHTS || hasCubeMap || hasLightMap);

        var activeProgram = (isLit && programLit != null) ? programLit : programUnlit;
        if (activeProgram == null) activeProgram = program;
        if (activeProgram == null) return;

        Device3D.setProgram(activeProgram);
        Device3D.setVertexBuffers(surface.vertexBuffer, surface);

        // Upload MVP matrix (vc0..vc3) & World matrix (vc4..vc7) cached per mesh and program
        if (Device3D.currentMesh != mesh || _lastMeshProgram != activeProgram || _lastCamera != camera) {
            _lastCamera = camera;
            Device3D.currentMesh = mesh;
            _lastMeshProgram = activeProgram;
            if (Std.isOfType(mesh, flare.primitives.Quad)) {
                _mvp.copyFrom(mesh.world);
            } else {
                _mvp.copyFrom(mesh.world);
                var vpMat = (Device3D.viewProj != null) ? Device3D.viewProj : camera.viewProjection;
                _mvp.append(vpMat);
            }
            context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, _mvp, true);
            context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 4, mesh.world, true);
        }

        // vc15: Texture UV scale (repeatX, repeatY) and offset (offsetX, offsetY)
        var repX:Float = (texFilters.length > 0) ? texFilters[0].repeatX : 1.0;
        var repY:Float = (texFilters.length > 0) ? texFilters[0].repeatY : 1.0;
        var offX:Float = (texFilters.length > 0) ? texFilters[0].offsetX : 0.0;
        var offY:Float = (texFilters.length > 0) ? texFilters[0].offsetY : 0.0;
        _texCoordParams[0] = (repX != 0) ? repX : 1.0;
        _texCoordParams[1] = (repY != 0) ? repY : 1.0;
        _texCoordParams[2] = offX;
        _texCoordParams[3] = offY;
        context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 15, _texCoordParams);

        // Environment Map View-Space matrix (vc8..vc11) & Sphere consts (vc12)
        if (hasEnv) {
            _worldView.copyFrom(mesh.world);
            _worldView.append(camera.view);
            context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 8, _worldView, true);

            _sphereConst[0] = 0.5;
            _sphereConst[1] = -0.5;
            _sphereConst[2] = 0.5;
            _sphereConst[3] = 0.5;
            context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 12, _sphereConst);
        }

        // Lighting constants (fc1, fc2, fc3, fc9, fc10..fc21)
        if (isLit) {
            if (_lastLightingFrame != Device3D.frame || _lastLightingTech != tech || _lastLightingProgram != activeProgram) {
                _lastLightingFrame = Device3D.frame;
                _lastLightingTech = tech;
                _lastLightingProgram = activeProgram;

                // Mode-controlled attenuation: 1.0 for SAMPLED (quadratic), 0.0 for LINEAR, 2.0 for PER_VERTEX (contrast)
                _helperConsts[0] = 1.0;
                _helperConsts[1] = 0.0;
                _helperConsts[2] = 0.001;
                _helperConsts[3] = (tech == LightFilter.SAMPLED) ? 1.0 : (tech == LightFilter.PER_VERTEX ? 2.0 : 0.0);
                context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 9, _helperConsts, 1);

                var sunDirX:Float = 0.40;
                var sunDirY:Float = 0.70;
                var sunDirZ:Float = -0.55;

                var sunR:Float = 0.65;
                var sunG:Float = 0.65;
                var sunB:Float = 0.65;

                var ambR:Float = 0.22;
                var ambG:Float = 0.22;
                var ambB:Float = 0.22;
                if (sceneLights != null && sceneLights.ambientColor != null && Std.isOfType(sceneLights.ambientColor, openfl.geom.Vector3D)) {
                    var ac:openfl.geom.Vector3D = cast sceneLights.ambientColor;
                    ambR = ac.x;
                    ambG = ac.y;
                    ambB = ac.z;
                }

                var defLight = (sceneLights != null) ? sceneLights.defaultLight : null;
                var hasSunAllowed = (sceneLights == null || sceneLights.maxDirectionalLights > 0);
                var hasCustomSun = false;
                if (hasSunAllowed && sceneLights != null && sceneLights.list != null) {
                    for (l in sceneLights.list) {
                        if (l.visible && l.type == flare.core.Light3D.DIRECTIONAL && l.radius <= 0) {
                            hasCustomSun = true;
                            break;
                        }
                    }
                }

                if (!hasSunAllowed) {
                    sunR = 0.0;
                    sunG = 0.0;
                    sunB = 0.0;
                } else if (hasCustomSun) {
                    for (l in sceneLights.list) {
                        if (!l.visible) continue;
                        if (l.type == flare.core.Light3D.DIRECTIONAL) {
                            var lPos = l.getPosition(false);
                            var len = Math.sqrt(lPos.x * lPos.x + lPos.y * lPos.y + lPos.z * lPos.z);
                            if (len > 0.0001) {
                                sunDirX = lPos.x / len;
                                sunDirY = lPos.y / len;
                                sunDirZ = lPos.z / len;
                            }
                            var sMult = l.multiplier > 0 ? l.multiplier : 1.0;
                            sunR = l.color.x * sMult;
                            sunG = l.color.y * sMult;
                            sunB = l.color.z * sMult;
                            break;
                        }
                    }
                } else if (defLight != null && defLight.visible) {
                    var mult = defLight.multiplier > 0 ? defLight.multiplier : 1.0;
                    sunR = defLight.color.x * mult * 0.65;
                    sunG = defLight.color.y * mult * 0.65;
                    sunB = defLight.color.z * mult * 0.65;

                    if (Std.isOfType(Device3D.scene, flare.basic.Viewer3D)) {
                        // Fixed natural top-right key light to give 3D depth and shadows
                        sunDirX = 0.40;
                        sunDirY = 0.70;
                        sunDirZ = -0.55;
                        var sLen = Math.sqrt(sunDirX * sunDirX + sunDirY * sunDirY + sunDirZ * sunDirZ);
                        sunDirX /= sLen;
                        sunDirY /= sLen;
                        sunDirZ /= sLen;
                    } else {
                        // Standard Scene3D directional key light from top-left-front
                        sunDirX = -0.38;
                        sunDirY = 0.45;
                        sunDirZ = -0.805;
                        var sLen = Math.sqrt(sunDirX * sunDirX + sunDirY * sunDirY + sunDirZ * sunDirZ);
                        sunDirX /= sLen;
                        sunDirY /= sLen;
                        sunDirZ /= sLen;
                    }
                } else {
                    ambR = 0.22; ambG = 0.22; ambB = 0.22;
                    sunDirX = 0.40; sunDirY = 0.70; sunDirZ = -0.55;
                    var sLen = Math.sqrt(sunDirX * sunDirX + sunDirY * sunDirY + sunDirZ * sunDirZ);
                    sunDirX /= sLen;
                    sunDirY /= sLen;
                    sunDirZ /= sLen;
                    sunR = 0.65; sunG = 0.65; sunB = 0.65;
                }

                var refX = mesh.world.rawData[12];
                var refY = mesh.world.rawData[13];
                var refZ = mesh.world.rawData[14];

                var poolIdx = 0;
                _scoreItems.resize(0);

                if (sceneLights != null && sceneLights.list != null) {
                    for (l in sceneLights.list) {
                        if (!l.visible) continue;
                        if (l.type == flare.core.Light3D.DIRECTIONAL && l.radius <= 0) continue;

                        var lPos = l.getPosition(false);
                        var dx = lPos.x - refX;
                        var dy = lPos.y - refY;
                        var dz = lPos.z - refZ;
                        var dist = Math.sqrt(dx * dx + dy * dy + dz * dz);
                        var r = l.radius > 0 ? l.radius : 2000.0;
                        var mult = l.multiplier > 0 ? l.multiplier : 1.0;

                        var atten = 1.0 - (dist / r);
                        var score:Float = (atten > 0) ? (atten * mult) : (0.0001 / (1.0 + (dist - r) / r));

                        var item:LightScoreItem = null;
                        if (poolIdx < _scorePool.length) {
                            item = _scorePool[poolIdx];
                        } else {
                            item = new LightScoreItem();
                            _scorePool.push(item);
                        }
                        poolIdx++;
                        item.light = l;
                        item.score = score;
                        _scoreItems.push(item);
                    }
                }

                _scoreItems.sort(function(a, b) {
                    if (a.score > b.score) return -1;
                    if (a.score < b.score) return 1;
                    return 0;
                });

                _lightDirVector[0] = sunDirX;
                _lightDirVector[1] = sunDirY;
                _lightDirVector[2] = sunDirZ;
                _lightDirVector[3] = 0.0;

                // fc1: Sun Direction
                _globalLightingData[0] = sunDirX;
                _globalLightingData[1] = sunDirY;
                _globalLightingData[2] = sunDirZ;
                _globalLightingData[3] = 0.0;

                // fc2: Sun Color
                _globalLightingData[4] = sunR;
                _globalLightingData[5] = sunG;
                _globalLightingData[6] = sunB;
                _globalLightingData[7] = 1.0;

                // fc3: Ambient
                _globalLightingData[8] = ambR;
                _globalLightingData[9] = ambG;
                _globalLightingData[10] = ambB;
                _globalLightingData[11] = 1.0;

                context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, _globalLightingData, 3);

                // fc10..fc17: 4 point lights
                var maxPt = (sceneLights != null) ? sceneLights.maxPointLights : 4;
                var numCandidates = _scoreItems.length;
                for (k in 0...4) {
                    var pOffset = k * 8;
                    if (k < numCandidates && k < maxPt) {
                        var c = _scoreItems[k];
                        var l = c.light;
                        var lPos = l.getPosition(false);
                        var r = l.radius > 0 ? l.radius : 2000.0;
                        var mult = l.multiplier > 0 ? l.multiplier : 1.0;

                        _pointLightsData[pOffset + 0] = lPos.x;
                        _pointLightsData[pOffset + 1] = lPos.y;
                        _pointLightsData[pOffset + 2] = lPos.z;
                        _pointLightsData[pOffset + 3] = 1.0 / r;

                        _pointLightsData[pOffset + 4] = l.color.x * mult;
                        _pointLightsData[pOffset + 5] = l.color.y * mult;
                        _pointLightsData[pOffset + 6] = l.color.z * mult;
                        _pointLightsData[pOffset + 7] = 0.0;
                    } else {
                        _pointLightsData[pOffset + 0] = 0.0;
                        _pointLightsData[pOffset + 1] = 0.0;
                        _pointLightsData[pOffset + 2] = 0.0;
                        _pointLightsData[pOffset + 3] = 0.0;

                        _pointLightsData[pOffset + 4] = 0.0;
                        _pointLightsData[pOffset + 5] = 0.0;
                        _pointLightsData[pOffset + 6] = 0.0;
                        _pointLightsData[pOffset + 7] = 0.0;
                    }
                }
                context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 10, _pointLightsData, 8);
                if (Device3D.frame == 1) {
                    // trace("[Shader3D DEBUG] pt0: pos=(" + _pointLightsData[0] + "," + _pointLightsData[1] + "," + _pointLightsData[2] + ") 1/r=" + _pointLightsData[3] + " col=(" + _pointLightsData[4] + "," + _pointLightsData[5] + "," + _pointLightsData[6] + ")");
                }
            }
        }

        // Upload Fragment Constants & Textures (cached per material to eliminate thousands of redundant GPU state calls)
        var matChanged = (Device3D.currentMaterial != this);
        if (matChanged || colorFilter != null) {
            Device3D.currentMaterial = this;

            // fc0: ColorFilter
            if (colorFilter != null) {
                _colorVector[0] = colorFilter.r;
                _colorVector[1] = colorFilter.g;
                _colorVector[2] = colorFilter.b;
                _colorVector[3] = colorFilter.alpha;
            } else {
                _colorVector[0] = 1.0;
                _colorVector[1] = 1.0;
                _colorVector[2] = 1.0;
                _colorVector[3] = 1.0;
            }
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _colorVector);
        }

        // fc4: Primary texture alpha and helper constants (x: texAlpha, y: 0.0, z: 0.5, w: 1.0)
        var texAlpha = (texFilters.length > 0) ? texFilters[0].alpha : 1.0;
        if (matChanged || _texParams[0] != texAlpha) {
            _texParams[0] = texAlpha;
            _texParams[1] = 0.0;
            _texParams[2] = 0.5;
            _texParams[3] = 1.0;
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 4, _texParams);
        }

        if (matChanged) {
            // fc5: Environment params
            if (hasEnv) {
                _envParams[0] = envFilter.alpha;
                _envParams[1] = 0.0;
                _envParams[2] = 0.0;
                _envParams[3] = 0.0;
                context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 5, _envParams);
            }

            // fc6: AlphaMask params
            if (alphaMaskFilter != null) {
                _maskParams[0] = alphaMaskFilter.threshold;
                _maskParams[1] = 0.0;
                _maskParams[2] = 0.0;
                _maskParams[3] = 0.0;
                context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 6, _maskParams);
            }
        }

        var hasRotate = hasRotateTexture();
        if (hasRotate) {
            var ang:Array<Float> = cast flslFilter.params.angles.value;
            if (ang != null && ang.length >= 3) {
                _rotateConsts[0] = ang[0];
                _rotateConsts[1] = ang[1];
                _rotateConsts[2] = ang[2];
                _rotateConsts[3] = 0.5;
            }
            context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 16, _rotateConsts);
        }

        var hasScreenProj = hasScreenProjTexture();
        if (hasScreenProj) {
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 16, openfl.Vector.ofArray([0.5, -0.5, 0.5, 0.5]));
        }

        var curTex0 = (hasRotate && flslFilter.params.texture.value != null) ? flslFilter.params.texture.value : ((hasScreenProj && flslFilter.params.texture.value != null) ? flslFilter.params.texture.value : ((texFilters.length > 0) ? texFilters[0].texture : null));
        var curLightMap = (lightMapFilter != null) ? lightMapFilter.texture : null;
        var tex0Changed = (curTex0 != _lastTexture0);
        var lmChanged = (curLightMap != _lastLightMap);
        if (matChanged || tex0Changed || lmChanged || hasRotate || hasScreenProj) {
            _lastTexture0 = curTex0;
            _lastLightMap = curLightMap;
            // Bind Textures
            var currentSampler = 0;
            if (hasScreenProj) {
                var projTex:flare.core.Texture3D = flslFilter.params.texture.value;
                if (projTex != null) {
                    projTex.wrapMode = flare.core.Texture3D.WRAP_CLAMP;
                    projTex.upload(context);
                    if (projTex.texture != null) {
                        Device3D.setTextureAt(currentSampler++, projTex.texture);
                    }
                }
            }
            if (hasRotate) {
                var rotTex:flare.core.Texture3D = flslFilter.params.texture.value;
                if (rotTex != null) {
                    rotTex.wrapMode = flare.core.Texture3D.WRAP_CLAMP;
                    rotTex.upload(context);
                    if (rotTex.texture != null) {
                        Device3D.setTextureAt(currentSampler++, rotTex.texture);
                    }
                }
            }
            if (texFilters.length > 0 && texFilters[0].texture != null) {
                texFilters[0].texture.upload(context);
                if (texFilters[0].texture.texture != null) {
                    Device3D.setTextureAt(currentSampler++, texFilters[0].texture.texture);
                }
            }
            if (texFilters.length > 1 && texFilters[1].texture != null) {
                texFilters[1].texture.upload(context);
                if (texFilters[1].texture.texture != null) {
                    Device3D.setTextureAt(currentSampler++, texFilters[1].texture.texture);
                }
            }
            if (normalMapFilter != null && normalMapFilter.normalMap != null) {
                normalMapFilter.normalMap.upload(context);
                if (normalMapFilter.normalMap.texture != null) {
                    Device3D.setTextureAt(currentSampler++, normalMapFilter.normalMap.texture);
                }
                _normalParams[0] = normalMapFilter.repeatX > 0 ? normalMapFilter.repeatX : 1.0;
                _normalParams[1] = normalMapFilter.repeatY > 0 ? normalMapFilter.repeatY : 1.0;
                _normalParams[2] = 0.0;
                _normalParams[3] = 0.0;
                context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 13, _normalParams);
                _normalUpParams[0] = 0.0;
                _normalUpParams[1] = 1.0;
                _normalUpParams[2] = 0.0;
                _normalUpParams[3] = 0.7;
                context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 19, _normalUpParams);
            }
            if (hasEnv && envFilter.texture != null) {
                envFilter.texture.upload(context);
                if (envFilter.texture.texture != null) {
                    Device3D.setTextureAt(currentSampler++, envFilter.texture.texture);
                }
            }
            if (specularMapFilter != null && (specularMapFilter.specularMap != null || specularMapFilter.texture != null)) {
                var sTex = specularMapFilter.specularMap != null ? specularMapFilter.specularMap : specularMapFilter.texture;
                sTex.upload(context);
                if (sTex.texture != null) {
                    Device3D.setTextureAt(currentSampler++, sTex.texture);
                }
                _specMapParams[0] = specularMapFilter.repeatX > 0 ? specularMapFilter.repeatX : 1.0;
                _specMapParams[1] = specularMapFilter.repeatY > 0 ? specularMapFilter.repeatY : 1.0;
                _specMapParams[2] = 0.0;
                _specMapParams[3] = 0.0;
                context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 14, _specMapParams);
            }
            if (hasCubeMap && activeCubeMap != null) {
                activeCubeMap.upload(context);
                if (activeCubeMap.texture != null) {
                    Device3D.setTextureAt(currentSampler++, activeCubeMap.texture);
                }
                var cubeLevel:Float = (cubeMapFilter != null) ? cubeMapFilter.level : 1.0;
                _cubeMapParams[0] = cubeLevel;
                _cubeMapParams[1] = 0.0;
                _cubeMapParams[2] = 0.0;
                _cubeMapParams[3] = 0.0;
                context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 18, _cubeMapParams);
            }
            if (hasLightMap && lightMapFilter.texture != null) {
                lightMapFilter.texture.upload(context);
                if (lightMapFilter.texture.texture != null) {
                    Device3D.setTextureAt(currentSampler++, lightMapFilter.texture.texture);
                }
            }
        }

        // Specular constants (fc6: camPos, fc7: sun half-vector & power, fc8: spec level & sun color)
        var hasSpecular = (specularFilter != null || (specularMapFilter != null && (specularMapFilter.specularMap != null || specularMapFilter.texture != null)));
        if (hasSpecular || hasCubeMap) {
            var camPos = camera != null ? camera.getPosition(false) : new Vector3D(Device3D.camX, Device3D.camY, Device3D.camZ);
            _eyePosVector[0] = camPos.x;
            _eyePosVector[1] = camPos.y;
            _eyePosVector[2] = camPos.z;
            _eyePosVector[3] = 1.0;
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 6, _eyePosVector);

            if (hasSpecular) {
                var lx:Float = _lightDirVector[0];
                var ly:Float = _lightDirVector[1];
                var lz:Float = _lightDirVector[2];
                var specColR:Float = _globalLightingData[4];
                var specColG:Float = _globalLightingData[5];
                var specColB:Float = _globalLightingData[6];

            var meshPos = mesh.getPosition(false);
            var vx:Float = camPos.x - meshPos.x;
            var vy:Float = camPos.y - meshPos.y;
            var vz:Float = camPos.z - meshPos.z;
            var vLen:Float = Math.sqrt(vx * vx + vy * vy + vz * vz);
            if (vLen > 0.0001) { vx /= vLen; vy /= vLen; vz /= vLen; }
            else { vx = 0.0; vy = 0.0; vz = 1.0; }

            var hx:Float = lx + vx;
            var hy:Float = ly + vy;
            var hz:Float = lz + vz;
            var hLen:Float = Math.sqrt(hx * hx + hy * hy + hz * hz);
            if (hLen > 0.0001) { hx /= hLen; hy /= hLen; hz /= hLen; }
            else { hx = 0.0; hy = 1.0; hz = 0.0; }

            var specPower:Float = (specularFilter != null) ? specularFilter.power : (specularMapFilter != null ? specularMapFilter.power : 50.0);
            var specLevelVal:Float = (specularFilter != null) ? specularFilter.level : (specularMapFilter != null ? specularMapFilter.level : 1.0);

            _specParams[0] = hx;
            _specParams[1] = hy;
            _specParams[2] = hz;
            _specParams[3] = specPower;
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 7, _specParams);

            _specLevel[0] = specLevelVal;
            _specLevel[1] = specColR;
            _specLevel[2] = specColG;
            _specLevel[3] = specColB;
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 8, _specLevel);

            if (Device3D.frame == 1) {
                // trace("[Shader3D DEBUG] hasSpecular=" + hasSpecular + " mesh=" + mesh.name + " specPower=" + specPower + " specLevel=" + specLevelVal + " camPos=" + camPos + " meshPos=" + meshPos);
            }
        }
        }


        // Draw Call
        context.drawTriangles(surface.indexBuffer, surface.firstIndex, surface.numTriangles);

        Device3D.drawCalls++;
        Device3D.triangles += surface.numTriangles;

        // Draw Outline / Inverted Hull Pass (EdgeFilter / FLSLFilter)
        if (edgeFilter != null && outlineProgram != null) {
            Device3D.setProgram(outlineProgram);

            // Upload MVP matrix for outline program
            context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, _mvp, true);

            var edgeVal:Float = edgeFilter.edge > 0 ? edgeFilter.edge : 1.0;
            _outlineParams[0] = edgeVal;
            _outlineParams[1] = edgeVal;
            _outlineParams[2] = edgeVal;
            _outlineParams[3] = 0.003;
            context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, _outlineParams);

            if (edgeFilter.color != null) {
                _outlineColor[0] = edgeFilter.color[0];
                _outlineColor[1] = edgeFilter.color[1];
                _outlineColor[2] = edgeFilter.color[2];
                _outlineColor[3] = edgeFilter.color[3];
            } else {
                _outlineColor[0] = 1.0;
                _outlineColor[1] = 1.0;
                _outlineColor[2] = 1.0;
                _outlineColor[3] = 1.0;
            }
            context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _outlineColor);

            Device3D.setCulling(openfl.display3D.Context3DTriangleFace.FRONT);
            Device3D.setDepthTest(false, openfl.display3D.Context3DCompareMode.LESS);

            context.drawTriangles(surface.indexBuffer, surface.firstIndex, surface.numTriangles);

            // Restore culling and depth
            Device3D.setCulling(twoSided ? openfl.display3D.Context3DTriangleFace.NONE : cullFace);
            Device3D.setDepthTest(depthWrite, depthCompare);
            Device3D.currentProgram = null;

            Device3D.drawCalls++;
            Device3D.triangles += surface.numTriangles;
        }
    }

    override public function clone():Shader3D {
        var s = new Shader3D(name, _filters != null ? _filters.copy() : [], enableLights);
        s.sourceFactor = sourceFactor;
        s.destFactor = destFactor;
        s.depthWrite = depthWrite;
        s.depthCompare = depthCompare;
        s.twoSided = twoSided;
        s.cullFace = cullFace;
        s.transparent = transparent;
        return s;
    }

    override public function download():Void {
        dispose();
        programLit = null;
        programUnlit = null;
        outlineProgram = null;
    }

    override public function dispose():Void {
        if (program != null) {
            program.dispose();
            program = null;
        }
        if (outlineProgram != null) {
            outlineProgram.dispose();
            outlineProgram = null;
        }
    }
}
