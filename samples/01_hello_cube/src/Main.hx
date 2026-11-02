package;

import openfl.display.Sprite;
import openfl.events.Event;
import flare.basic.Viewer3D;
import flare.primitives.Box;
import flare.materials.Shader3D;
import flare.materials.filters.ColorFilter;

class Main extends Sprite {
    public function new() {
        super();

        var scene = new Viewer3D(this);
        scene.clearColor = 0x202025;

        var mat = new Shader3D("cubeMat", [new ColorFilter(0x00aaff)]);
        var box = new Box("testBox", 80, 80, 80, 1, mat);
        scene.addChild(box);

        addEventListener(Event.ENTER_FRAME, function(e:Event) {
            box.rotateY(1.0);
            box.rotateX(0.5);
        });
    }
}
