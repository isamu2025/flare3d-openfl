package examples;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.Vector3D;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFieldAutoSize;
import openfl.filters.DropShadowFilter;
import flare.basic.*;
import flare.core.*;
import flare.loaders.*;

/**
 * Mixamo Collada models test: Embedding Collada file.
 * 
 * @author Ariel Nehmad
 */
class Test19_EmbedingColladaFile extends Sprite 
{
	private var scene:Scene3D;
	private var collada:ColladaLoader;
	private var _infoText:TextField;
	
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
		
		collada = new ColladaLoader("knocked_out_7.dae", null, scene, "textures/", false, "back");
		collada.setRotation(0, 90, 0);
		collada.play(true);
		scene.addChild(collada);
		scene.addEventListener(Scene3D.COMPLETE_EVENT, completeEvent);
		scene.library.push(collada);

		initUI();
	}

	private function initUI():Void 
	{
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
		_infoText.x = 16;
		_infoText.y = 16;
		_infoText.filters = [new DropShadowFilter(2, 45, 0x000000, 0.9, 4, 4)];
		addChild(_infoText);

		_infoText.text = "Test19_EmbedingColladaFile | 士兵骨骼模型\n" +
			"嵌入式 Mixamo Collada (DAE) 资产解析 | 骨骼层级蒙皮与被击倒动作循环播放\n" +
			"状态：士兵模型 knocked_out_7.dae 解析完成，动作循环播放中\n" +
			"操作：按住鼠标左键拖拽旋转 3D 视角，滚轮缩放";
	}
	
	private function completeEvent(e:Event):Void 
	{
		trace("[Test19_EmbedingColladaFile] loaded");
	}
}
