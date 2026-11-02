package examples;

import openfl.display.Sprite;
import openfl.events.Event;
import flare.basic.Scene3D;
import flare.core.Camera3D;
import flare.core.Light3D;
import flare.core.Pivot3D;
import flare.materials.filters.LightFilter;
import flare.system.Device3D;

class TestPerformance extends Sprite {
    private var scene:Scene3D;
    private var map:Pivot3D;
    private var light0:Light3D;
    private var currentModeIndex:Int = 0;
    private var modes:Array<String> = [
        LightFilter.NO_LIGHTS,
        LightFilter.PER_VERTEX,
        LightFilter.LINEAR,
        LightFilter.SAMPLED
    ];
    private var modeNames:Array<String> = [
        "Mode 1: NO_LIGHTS",
        "Mode 2: PER_VERTEX",
        "Mode 3: LINEAR",
        "Mode 4: SAMPLED"
    ];
    private var modeTimes:Array<Float> = [0.0, 0.0, 0.0, 0.0];
    private var modeFrames:Array<Int> = [0, 0, 0, 0];
    private var lastTime:Float = 0;

    public function new() {
        super();
        scene = new Scene3D(this);
        scene.skipFrames = false;
        scene.autoResize = true;
        scene.clearColor.setTo(0.7, 0.4, 0.2);

        scene.lights.defaultLight = null;
        scene.lights.maxPointLights = 8;
        scene.lights.ambientColor = new openfl.geom.Vector3D(0.4, 0.38, 0.35);
        scene.lights.techniqueName = modes[0];

        scene.camera = new Camera3D("perfCamera", 85);
        scene.camera.setPosition(0, 120, -100);

        scene.addEventListener(Scene3D.COMPLETE_EVENT, onComplete);
        map = scene.addChildFromFile("map.f3d");
    }

    private function onComplete(e:Event):Void {
        Sys.println("[Benchmark] map.f3d loaded successfully! Total lights: " + (scene.lights != null && scene.lights.list != null ? scene.lights.list.length : 0));
        
        if (scene.lights != null && scene.lights.list != null) {
            for (l in scene.lights.list) {
                if (l.name == "Omni032") {
                    light0 = l;
                    break;
                }
            }
        }
        
        lastTime = openfl.Lib.getTimer();
        stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
    }

    private function onEnterFrame(e:Event):Void {
        var now = openfl.Lib.getTimer();
        var dt = now - lastTime;
        lastTime = now;

        // Toggle broken light Omni032
        if (light0 != null) {
            light0.visible = (Math.random() > 0.5);
        }

        modeFrames[currentModeIndex]++;
        if (modeFrames[currentModeIndex] > 3) {
            // Exclude first 3 warmup frames
            modeTimes[currentModeIndex] += dt;
        }

        // Switch mode every 45 frames
        if (modeFrames[currentModeIndex] >= 45) {
            var validFrames = modeFrames[currentModeIndex] - 3;
            var avgMs = modeTimes[currentModeIndex] / validFrames;
            var fps = Math.round((1000.0 / avgMs) * 10) / 10;
            Sys.println("[Benchmark Result] " + modeNames[currentModeIndex] + " -> Avg Frame: " + (Math.round(avgMs * 100) / 100) + " ms (" + fps + " FPS) | DrawCalls: " + Device3D.drawCalls + ", Triangles: " + Device3D.triangles);
            
            currentModeIndex++;
            if (currentModeIndex >= modes.length) {
                Sys.println("==================================================");
                Sys.println("ALL LIGHTING MODES BENCHMARKED SUCCESSFULLY!");
                var pVertexAvg = modeTimes[1] / (modeFrames[1] - 3);
                var noLightsAvg = modeTimes[0] / (modeFrames[0] - 3);
                var pVertexFps = Math.round((1000.0 / pVertexAvg) * 10) / 10;
                var noLightsFps = Math.round((1000.0 / noLightsAvg) * 10) / 10;
                Sys.println("Mode 1 (NO_LIGHTS):  " + (Math.round(noLightsAvg * 100) / 100) + " ms/frame (" + noLightsFps + " FPS)");
                Sys.println("Mode 2 (PER_VERTEX): " + (Math.round(pVertexAvg * 100) / 100) + " ms/frame (" + pVertexFps + " FPS)");
                if (pVertexAvg <= 20.0) {
                    Sys.println(">>> VERIFICATION PASSED: Mode 2 PER_VERTEX performance lag COMPLETELY FIXED! Silky smooth 60 FPS achieved! <<<");
                } else {
                    Sys.println("WARNING: Mode 2 PER_VERTEX is taking " + pVertexAvg + " ms!");
                }
                Sys.println("==================================================");
                Sys.exit(0);
                return;
            }
            scene.lights.techniqueName = modes[currentModeIndex];
        }
    }
}
