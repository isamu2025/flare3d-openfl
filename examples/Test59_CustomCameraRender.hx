package examples;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.Rectangle;
import openfl.display3D.Context3DClearMask;
import flare.basic.Scene3D;
import flare.basic.Viewer3D;
import flare.core.Camera3D;

/**
 * @author Ariel Nehmad
 */
class Test59_CustomCameraRender extends Sprite 
{
	private var scene:Scene3D;
	private var secondCamera:Camera3D;
	private var _renderFrames:Int = 0;
	private var _isLoaded:Bool = false;
	
	public function new() 
	{
		super();
		scene = new Viewer3D( this, null, 0.4 );
		scene.autoResize = true;
		
		// creates the second camera.
		secondCamera = new Camera3D( "second camera", 60 );
		secondCamera.setPosition( 50, 100, -150 );
		secondCamera.lookAt( 0, 0, 0 );
		secondCamera.viewPort = new Rectangle( 20, 20, 250, 150 );
		
		// external loading.
		scene.addChildFromFile( "chess.zf3d" );
		scene.skipFrames = false;
		scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
	}
	
	private function completeEvent(e:Event):Void 
	{
		_isLoaded = true;
		scene.addEventListener( Scene3D.POSTRENDER_EVENT, postRenderEvent );
	}
	
	private function postRenderEvent(e:Event):Void 
	{
		graphics.clear();
		graphics.lineStyle( 1, 0xff0000 );
		graphics.drawRect( 20, 20, 250, 150 );
		
		// we need to clear depth in order to draw the second camera on top.
		scene.context.clear( 0, 0, 0, 0, 1, 0, Context3DClearMask.DEPTH );			
		scene.setupFrame( secondCamera );
		var desk = scene.getChildByName( "Desk" );
		if (desk != null) desk.draw();
		
		#if sys
		var isAuto = (Sys.getEnv("AUTO_EXIT") != null && StringTools.trim(Sys.getEnv("AUTO_EXIT")) == "1")
			|| (Sys.args().indexOf("--auto-exit") != -1)
			|| (Sys.args().indexOf("auto") != -1)
			|| sys.FileSystem.exists("auto_exit.flag");
		if (isAuto && _isLoaded) {
			_renderFrames++;
			if (_renderFrames >= 20) {
				saveScreenshot("test59.png");
				Sys.exit(0);
			}
		}
		#end
	}

	private function saveScreenshot(filename:String):Void 
	{
		try {
			var w = stage != null ? stage.stageWidth : 800;
			var h = stage != null ? stage.stageHeight : 450;
			if (w <= 0) w = 800;
			if (h <= 0) h = 450;
			var b = new openfl.display.BitmapData(w, h, false, 0x505050);
			if (scene != null && scene.context != null) {
				scene.context.drawToBitmapData(b);
			}
			b.draw(this);
			var pngBytes = b.encode(b.rect, new openfl.display.PNGEncoderOptions());
			if (pngBytes != null) {
				#if sys
				sys.io.File.saveBytes(filename, pngBytes);
				try { sys.io.File.saveBytes("../../" + filename, pngBytes); } catch (e:Dynamic) {}
				#end
			}
		} catch (e:Dynamic) {}
	}
}
