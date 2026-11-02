package flare.materials;

import openfl.utils.ByteArray;

/**
 * FLSLMaterial provides compatibility with Flare3D Shader Language compiled programs and custom AGAL shaders.
 */
class FLSLMaterial extends flare.flsl.FLSLMaterial {
    public function new(name:String = "flslMat", source:Dynamic = null, technique:String = null, compileAll:Bool = false) {
        super(name, source, technique, compileAll);
    }
}
