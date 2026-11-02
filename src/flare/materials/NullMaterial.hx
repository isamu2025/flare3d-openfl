package flare.materials;

import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import flare.core.Texture3D;
import flare.materials.filters.TextureMapFilter;

/**
 * NullMaterial represents a placeholder or pass-through checkerboard debug material.
 * Alternates between magenta (#ff00ff) and half-magenta (#800080) in a 10x10 grid.
 */
class NullMaterial extends Shader3D {
    public var programs:Array<Dynamic>;

    public function new(name:String = "nullMaterial") {
        super(name);
        programs = [];

        var bmd = new BitmapData(200, 200, false, 0xff000000);
        var cellSize = 20;
        for (gy in 0...10) {
            for (gx in 0...10) {
                var col:Int = ((gx + gy) % 2 == 0) ? 0xffff00ff : 0xff800080;
                bmd.fillRect(new Rectangle(gx * cellSize, gy * cellSize, cellSize, cellSize), col);
            }
        }

        var tex = new Texture3D(bmd, false);
        tex.filterMode = Texture3D.FILTER_NEAREST;
        tex.mipMode = Texture3D.MIP_NONE;
        addFilter(new TextureMapFilter(tex));
        enableLights = false;
        twoSided = true;
    }
}
