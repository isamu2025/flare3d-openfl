package examples;

import openfl.display.Sprite;
import openfl.display.StageScaleMode;
import openfl.display.StageAlign;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFieldAutoSize;
import openfl.filters.DropShadowFilter;
import openfl.geom.Vector3D;
import flare.basic.*;
import flare.system.*;
import flare.core.*;
import examples.mesh.*;

/**
 * High performance rendering of 10,000+ batched cubes rotating in 3D space.
 * 
 * @author Ariel Nehmad
 */
class Test18_CubeMesh extends Sprite
{
	private var scene:Scene3D;
	private var cubes:CubesMesh;
	private var count:Float = 0;
	private var info:TextField;
	
	public function new() 
	{
		super();
		if (stage != null) stage.scaleMode = StageScaleMode.NO_SCALE;
		if (stage != null) stage.align = StageAlign.TOP_LEFT;
		
		scene = new Viewer3D( this );
		var viewer:Viewer3D = cast scene;
		viewer.target = new Vector3D(0, 0, 0);
		scene.camera.setPosition( 0, 0, -1300 );			
		scene.camera.lookAt( 0, 0, 0 );
		viewer.syncOrbitFromCamera();
		
		cubes = new CubesMesh();
		
		var total:Int = 10000;
		for (i in 0...total)
		{
			var x:Float = Math.random() * 1000 - 500;
			var y:Float = Math.random() * 1000 - 500;
			var z:Float = Math.random() * 1000 - 500;
			var color:Float = Math.random() * 0.99 + 0.01;				
			cubes.addCube( x, y, z, 6, color );
		}

		scene.addChild( cubes );
		
		if (stage != null || (openfl.Lib.current != null && openfl.Lib.current.stage != null)) {
			initUI();
		} else {
			addEventListener(Event.ADDED_TO_STAGE, function(e:Event) {
				initUI();
			});
		}
		
		scene.addEventListener( Scene3D.UPDATE_EVENT, updateEvent );
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

		info = new TextField();
		info.defaultTextFormat = new TextFormat(fontName, 13, 0x00ffcc, true);
		info.autoSize = TextFieldAutoSize.LEFT;
		info.selectable = false;
		info.mouseEnabled = false;
		info.x = 15;
		info.y = 15;
		info.filters = [new DropShadowFilter(2, 45, 0x000000, 0.9, 4, 4)];
		info.text = "Test18_CubeMesh | 万只立方体极速批处理 (10,000+ 动态旋转小立方体)\n可按住鼠标左键拖拽旋转 3D 视角，滚轮缩放";
		addChild(info);
	}
	
	private function updateEvent(e:Event):Void 
	{
		if ( !Input3D.mouseDown )
		{
			count++;
			cubes.rotateX( 0.2 );
			cubes.rotateZ( 0.22 );
			scene.camera.translateZ( Math.sin( count / 150 ) * 5 );
		}
	}
}
