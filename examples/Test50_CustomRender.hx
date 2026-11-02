package examples;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.display3D.Context3DTriangleFace;
import openfl.display3D.Context3DCompareMode;
import openfl.display3D.Context3DBlendFactor;
import flare.basic.*;
import flare.core.*;
import flare.loaders.*;
import flare.system.*;

/**
 * @author Ariel Nehmad
 */
class Test50_CustomRender extends Sprite 
{
	private var scene:Scene3D;
	private var _renderFrames:Int = 0;
	private var _isLoaded:Bool = false;
	
	public function new() 
	{
		super();
		scene = new Viewer3D( this, null, 0.4 );
		scene.autoResize = true;
		
		// external loading.
		scene.addChildFromFile( "chess.zf3d" );
		scene.skipFrames = false;
		scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
		scene.addEventListener( Scene3D.RENDER_EVENT, renderEvent );
	}

	private function completeEvent(e:Event):Void 
	{
		_isLoaded = true;
	}
	
	private function renderEvent(e:Event):Void 
	{
		// prevents the default engine rendering.
		e.preventDefault();
		
		if (scene.context == null) return;
		
		var easy:Bool = true;
		
		// you can optionally use your own states.
		Device3D.ignoreStates = true;
		scene.context.setCulling( Context3DTriangleFace.BACK );
		scene.context.setDepthTest( true, Context3DCompareMode.LESS_EQUAL );
		scene.context.setBlendFactors( Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO );
		
		if ( easy ) scene.render( scene.camera );
		else
		{
			// setup some global matrices and constants configurations.
			scene.setupFrame( scene.camera );
			// go through each object to draw one by one.
			for (p in scene.renderList ) p.draw(false);
			// release GPU states.
			scene.endFrame();
		}
		
		Device3D.ignoreStates = false;

		#if sys
		var isAuto = (Sys.getEnv("AUTO_EXIT") != null && StringTools.trim(Sys.getEnv("AUTO_EXIT")) == "1")
			|| (Sys.args().indexOf("--auto-exit") != -1)
			|| (Sys.args().indexOf("auto") != -1)
			|| sys.FileSystem.exists("auto_exit.flag");
		if (isAuto && _isLoaded) {
			_renderFrames++;
			if (_renderFrames >= 20) {
				saveScreenshot("test50.png");
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
