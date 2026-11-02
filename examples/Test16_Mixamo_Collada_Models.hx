package examples;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.geom.Vector3D;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFieldAutoSize;
import openfl.filters.DropShadowFilter;
import flare.basic.*;
import flare.core.*;
import flare.loaders.*;

/**
 * Mixamo Collada models test with 4 switchable characters.
 * Keys 1, 2, 3, 4 switch character model.
 * 
 * 1: Cartoon Female Walking (walking_1.dae)
 * 2: Golden Retriever Howling (howl_1.dae)
 * 3: Soldier Knocked Out (knocked_out_7.dae)
 * 4: Flying Dragon (aerial_dragon_attack_2.dae)
 * 
 * @author Ariel Nehmad
 */
class Test16_Mixamo_Collada_Models extends Sprite 
{
	private var scene:Scene3D;
	private var model:Pivot3D;
	private var currentCharacterIndex:Int = 0;
	private var _windowHooked:Bool = false;
	private var _autoCycle:Bool = false;
	private var _autoTimer:Int = 0;
	private var _infoText:TextField;
	
	private static var CHARACTERS:Array<{name:String, cnName:String, file:String, scale:Float, posY:Float}> = [
		{ name: "Cartoon Female Walking", cnName: "卡通女生行走 (Cartoon Female Walking)", file: "walking_1.dae", scale: 1.0, posY: 0.0 },
		{ name: "Golden Retriever Howling", cnName: "金毛寻回犬咆哮 (Golden Retriever Howling)", file: "howl_1.dae", scale: 1.0, posY: 0.0 },
		{ name: "Soldier Knocked Out", cnName: "倒地士兵 (Soldier Knocked Out)", file: "knocked_out_7.dae", scale: 1.0, posY: 0.0 },
		{ name: "Flying Dragon", cnName: "飞天巨龙 (Flying Dragon)", file: "aerial_dragon_attack_2.dae", scale: 0.25, posY: -100.0 }
	];
	
	public function new() 
	{
		super();
		// creates the scene.
		scene = new Viewer3D(this);
		var viewer:Viewer3D = cast scene;
		viewer.target = new Vector3D(0, 50, 0);
		scene.camera.setPosition(200, 200, -300);
		scene.camera.lookAt(0, 50, 0);
		viewer.syncOrbitFromCamera();
		
		#if sys
		try {
			var args = Sys.args();
			if (args != null && (args.indexOf("--test-auto") != -1 || args.indexOf("--auto") != -1)) {
				_autoCycle = true;
				flare.system.DebugLog.log("[Test16] Auto cycle mode enabled via CLI.");
			}
		} catch (e:Dynamic) {}
		#end
		
		if (stage != null || (openfl.Lib.current != null && openfl.Lib.current.stage != null)) {
			initStage();
		} else {
			addEventListener(Event.ADDED_TO_STAGE, function(e:Event) {
				initStage();
			});
		}
		
		selectCharacter(0);
	}

	private function initStage():Void 
	{
		flare.system.DebugLog.log("[Test16] initStage called!");
		var st = stage != null ? stage : (openfl.Lib.current != null ? openfl.Lib.current.stage : null);
		if (st != null) {
			st.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}
		scene.addEventListener(Scene3D.UPDATE_EVENT, onUpdate);

		var fontName:String = "_sans";
		#if sys
		try {
			var testPaths = [
				"C:/Windows/Fonts/simhei.ttf",
				"C:/Windows/Fonts/msyh.ttc",
				"C:/Windows/Fonts/simsun.ttc"
			];
			for (fp in testPaths) {
				if (sys.FileSystem.exists(fp)) {
					var font = openfl.text.Font.fromFile(fp);
					if (font != null) {
						openfl.text.Font.registerFont(font);
						fontName = font.fontName;
						break;
					}
				}
			}
		} catch (e:Dynamic) {}
		#end

		_infoText = new TextField();
		_infoText.defaultTextFormat = new TextFormat(fontName, 13, 0xffffff, true);
		_infoText.autoSize = TextFieldAutoSize.LEFT;
		_infoText.selectable = false;
		_infoText.mouseEnabled = false;
		_infoText.x = 15;
		_infoText.y = 15;
		_infoText.filters = [new DropShadowFilter(2, 45, 0x000000, 0.9, 4, 4)];
		addChild(_infoText);
		updateInfoText();
	}

	private function updateInfoText():Void 
	{
		if (_infoText == null) return;
		var str = "按键盘数字键 [1 / 2 / 3 / 4] 切换角色动作 (可按住鼠标左键拖拽旋转视角)\nKeys [1 / 2 / 3 / 4] switch character (Drag mouse to orbit view):\n";
		for (i in 0...CHARACTERS.length) {
			var c = CHARACTERS[i];
			var active = (i == currentCharacterIndex) ? " > " : "   ";
			str += active + "[" + (i + 1) + "] " + c.cnName + "\n";
		}
		_infoText.text = str;
	}

	private function onUpdate(e:Event):Void 
	{
		#if lime
		if (!_windowHooked) {
			var st = stage != null ? stage : (openfl.Lib.current != null ? openfl.Lib.current.stage : null);
			if (st != null && st.window != null) {
				_windowHooked = true;
				flare.system.DebugLog.log("[Test16] Hooked Lime window.onKeyDown!");
				st.window.onKeyDown.add(function(keyCode:lime.ui.KeyCode, modifier:lime.ui.KeyModifier) {
					flare.system.DebugLog.log("[Test16] Lime onKeyDown: " + keyCode);
					if (keyCode == lime.ui.KeyCode.NUMBER_1 || keyCode == lime.ui.KeyCode.NUMPAD_1) selectCharacter(0);
					else if (keyCode == lime.ui.KeyCode.NUMBER_2 || keyCode == lime.ui.KeyCode.NUMPAD_2) selectCharacter(1);
					else if (keyCode == lime.ui.KeyCode.NUMBER_3 || keyCode == lime.ui.KeyCode.NUMPAD_3) selectCharacter(2);
					else if (keyCode == lime.ui.KeyCode.NUMBER_4 || keyCode == lime.ui.KeyCode.NUMPAD_4) selectCharacter(3);
				});
			}
		}
		#end

		// Input3D check
		if (flare.system.Input3D.keyHit(flare.system.Input3D.NUMBER_1) || flare.system.Input3D.keyHit(flare.system.Input3D.NUMPAD_1)) {
			selectCharacter(0);
		} else if (flare.system.Input3D.keyHit(flare.system.Input3D.NUMBER_2) || flare.system.Input3D.keyHit(flare.system.Input3D.NUMPAD_2)) {
			selectCharacter(1);
		} else if (flare.system.Input3D.keyHit(flare.system.Input3D.NUMBER_3) || flare.system.Input3D.keyHit(flare.system.Input3D.NUMPAD_3)) {
			selectCharacter(2);
		} else if (flare.system.Input3D.keyHit(flare.system.Input3D.NUMBER_4) || flare.system.Input3D.keyHit(flare.system.Input3D.NUMPAD_4)) {
			selectCharacter(3);
		}

		// Auto cycle for headless automated testing
		if (_autoCycle) {
			_autoTimer++;
			if (_autoTimer >= 120) { // ~2 seconds at 60fps
				_autoTimer = 0;
				selectCharacter((currentCharacterIndex + 1) % CHARACTERS.length);
			}
		}
	}
	
	public function selectCharacter(index:Int):Void 
	{
		if (index < 0 || index >= CHARACTERS.length) return;
		
		if (model != null) {
			scene.removeChild(model);
			model.dispose();
			model = null;
		}
		
		currentCharacterIndex = index;
		var charInfo = CHARACTERS[index];
		flare.system.DebugLog.log("[Test16] selectCharacter: " + index + " (" + charInfo.name + ") file=" + charInfo.file);
		
		model = scene.addChildFromFile( charInfo.file, null, ColladaLoader );
		model.setScale( charInfo.scale, charInfo.scale, charInfo.scale );
		model.setPosition( 0, charInfo.posY, 0 );
		model.setRotation( 0, 90, 0 );
		model.play(true);

		updateInfoText();
	}
	
	private function onKeyDown(e:KeyboardEvent):Void 
	{
		var code = e.keyCode;
		var char = e.charCode;
		flare.system.DebugLog.log("[Test16] onKeyDown: keyCode=" + code + " charCode=" + char);
		if (code == 49 || char == 49 || code == 97) selectCharacter(0);       // '1'
		else if (code == 50 || char == 50 || code == 98) selectCharacter(1);  // '2'
		else if (code == 51 || char == 51 || code == 99) selectCharacter(2);  // '3'
		else if (code == 52 || char == 52 || code == 100) selectCharacter(3); // '4'
	}
}
