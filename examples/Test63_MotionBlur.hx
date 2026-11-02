package examples;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.Rectangle;
import flare.basic.*;
import flare.core.*;
import flare.flsl.*;

/**
 * @author Ariel Nehmad
 */
class Test63_MotionBlur extends Sprite 
{
	private var scene:Scene3D;
	private var blur:FLSLMaterial;
	private var bufferA:Texture3D;
	private var bufferB:Texture3D;
	private var bufferCount:Int = 0;
	private var _renderFrames:Int = 0;
	
	public function new() 
	{
		super();
		scene = new Viewer3D( this, null, 0.25 );
		scene.autoResize = true;
		scene.addEventListener( Scene3D.RENDER_EVENT, renderEvent );
		scene.addChildFromFile( "planet.zf3d" );
		
		blur = new FLSLMaterial( "blur", "blurQuad.flsl.compiled" );
		
		bufferA = new Texture3D( new Rectangle( 0, 0, 1024, 512 ) );
		bufferA.upload( scene );
		bufferB = new Texture3D( new Rectangle( 0, 0, 1024, 512 ) );
		bufferB.upload( scene );
	}
	
	private function renderEvent(e:Event):Void 
	{
		e.preventDefault();

		if (bufferA.texture == null) bufferA.upload(scene);
		if (bufferB.texture == null) bufferB.upload(scene);
		
		var front:Texture3D;
		var back:Texture3D;
		
		if ( bufferCount++ % 2 == 0 ) {
			front = bufferA;
			back = bufferB;
		} else {
			front = bufferB;
			back = bufferA;
		}
		
		scene.context.setRenderToTexture( front.texture, true );
		scene.context.clear( 0.2, 0.3, 0.4 );
		scene.render();
		
		blur.params.texture.value = back;
		blur.params.alpha.value[0] = 0.8; // <-- higer values results in more blur (0 to 1);
		scene.drawQuadTexture( null, 0, 0, stage.stageWidth, stage.stageHeight, blur );
		
		blur.params.texture.value = front;
		blur.params.alpha.value[0] = 1;
		scene.context.setRenderToBackBuffer();
		scene.drawQuadTexture( null, 0, 0, stage.stageWidth, stage.stageHeight, blur );

		if (_renderFrames < 3) {
			trace("Frame: " + _renderFrames + " front.tex=" + front.texture + " back.tex=" + back.texture);
		}

		#if sys
		var isAuto = (Sys.getEnv("AUTO_EXIT") != null && StringTools.trim(Sys.getEnv("AUTO_EXIT")) == "1")
			|| (Sys.args().indexOf("--auto-exit") != -1)
			|| (Sys.args().indexOf("auto") != -1)
			|| sys.FileSystem.exists("auto_exit.flag");
		if (isAuto) {
			_renderFrames++;
			if (_renderFrames >= 15) {
				saveScreenshot("test63.png");
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
				#end
			}
		} catch (e:Dynamic) {
			trace("Error saving screenshot: " + e);
		}
	}
}
