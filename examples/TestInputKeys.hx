import flare.system.Input3D;
import openfl.events.KeyboardEvent;

class TestInputKeys {
    static function main() {
        Sys.println("Testing Input3D Key Mapping...");

        // Simulate Stage and event dispatch by reflecting into onKeyDown/onKeyUp or using Stage
        var stage:Dynamic = new openfl.events.EventDispatcher();
        Input3D.init(stage);

        // 1. Press 'A' key (keyCode 65, charCode 97)
        stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 97, 65));
        var aDown = Input3D.keyDown(Input3D.A);
        var numpad1Hit = Input3D.keyHit(Input3D.NUMPAD_1);
        Sys.println("Press A -> keyDown(A)=" + aDown + ", keyHit(NUMPAD_1)=" + numpad1Hit);

        if (!aDown) {
            Sys.println("FAIL: Key A was not recognized as keyDown(A)");
            Sys.exit(1);
        }
        if (numpad1Hit) {
            Sys.println("FAIL: Key A falsely triggered NUMPAD_1!");
            Sys.exit(1);
        }

        stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_UP, true, false, 97, 65));
        Input3D.update();

        // 2. Press 'D' key (keyCode 68, charCode 100)
        stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 100, 68));
        var dDown = Input3D.keyDown(Input3D.D);
        var numpad4Hit = Input3D.keyHit(Input3D.NUMPAD_4);
        Sys.println("Press D -> keyDown(D)=" + dDown + ", keyHit(NUMPAD_4)=" + numpad4Hit);

        if (!dDown) {
            Sys.println("FAIL: Key D was not recognized as keyDown(D)");
            Sys.exit(1);
        }
        if (numpad4Hit) {
            Sys.println("FAIL: Key D falsely triggered NUMPAD_4!");
            Sys.exit(1);
        }

        stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_UP, true, false, 100, 68));
        Input3D.update();

        // 3. Press numeric key '1' (keyCode 49, charCode 49)
        stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 49, 49));
        var num1Hit = Input3D.keyHit(Input3D.NUMBER_1);
        Sys.println("Press NUMBER_1 -> keyHit(NUMBER_1)=" + num1Hit);

        if (!num1Hit) {
            Sys.println("FAIL: NUMBER_1 was not triggered!");
            Sys.exit(1);
        }

        stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_UP, true, false, 49, 49));
        Input3D.update();

        // 4. Press numeric key 'NUMPAD_1' (keyCode 97, charCode 0)
        stage.dispatchEvent(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, 97));
        var np1Hit = Input3D.keyHit(Input3D.NUMPAD_1);
        var aDownDuringNumpad = Input3D.keyDown(Input3D.A);
        Sys.println("Press NUMPAD_1 -> keyHit(NUMPAD_1)=" + np1Hit + ", keyDown(A)=" + aDownDuringNumpad);

        if (!np1Hit) {
            Sys.println("FAIL: NUMPAD_1 was not triggered!");
            Sys.exit(1);
        }
        if (aDownDuringNumpad) {
            Sys.println("FAIL: NUMPAD_1 falsely triggered Key A!");
            Sys.exit(1);
        }

        Sys.println("==================================================");
        Sys.println("ALL INPUT KEY TESTS PASSED 100%!");
        Sys.println("==================================================");
        Sys.exit(0);
    }
}
