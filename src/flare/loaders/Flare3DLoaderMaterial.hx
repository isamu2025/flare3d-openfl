package flare.loaders;

import flare.materials.Material3D;
import flare.materials.Shader3D;
import flare.materials.filters.ColorFilter;
import flare.materials.filters.TextureMapFilter;
import flare.system.Library3D;

/**
 * Flare3DLoaderMaterial constructs materials for loaded F3D chunks.
 */
class Flare3DLoaderMaterial {
    public static function color(byteArray:Chunk, library:Library3D):Material3D {
        var mat = new Shader3D("colorMaterial");
        var c = byteArray.readColor();
        mat.addFilter(new ColorFilter(c));
        return mat;
    }

    public static function environment(byteArray:Chunk, resources:Library3D):Material3D {
        var mat = new Shader3D("environmentMaterial");
        mat.addFilter(new ColorFilter(0x888888));
        return mat;
    }

    public static function flatColor(byteArray:Chunk, library:Library3D):Material3D {
        var mat = new Shader3D("flatColorMaterial");
        var c = byteArray.readColor();
        mat.addFilter(new ColorFilter(c));
        return mat;
    }

    public static function multimaterial(byteArray:Chunk, resources:Library3D):Material3D {
        return new Shader3D("multiMaterial");
    }

    public static function planar(byteArray:Chunk, resources:Library3D):Material3D {
        return new Shader3D("planarMaterial");
    }

    public static function shadedColor(byteArray:Chunk, library:Library3D):Material3D {
        var mat = new Shader3D("shadedColorMaterial");
        var c = byteArray.readColor();
        mat.addFilter(new ColorFilter(c));
        return mat;
    }

    public static function standard(byteArray:Chunk, library:Library3D):Material3D {
        var mat = new Shader3D("standardMaterial");
        mat.addFilter(new ColorFilter(0xCCCCCC));
        return mat;
    }

    public static function texture(byteArray:Chunk, library:Library3D):Material3D {
        var mat = new Shader3D("textureMaterial");
        var texName = byteArray.readString();
        var tex = library != null ? library.getTexture(texName) : null;
        if (tex != null) {
            mat.addFilter(new TextureMapFilter(tex));
        }
        return mat;
    }

    public static function undefinedColor(byteArray:Chunk, library:Library3D):Material3D {
        var mat = new Shader3D("undefinedMaterial");
        mat.addFilter(new ColorFilter(0x888888));
        return mat;
    }

    public static function wireframe(byteArray:Chunk, library:Library3D):Material3D {
        var mat = new Shader3D("wireframeMaterial");
        mat.addFilter(new ColorFilter(0x00FF00));
        return mat;
    }
}
