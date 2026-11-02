package examples;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;
import openfl.geom.Vector3D;
import openfl.geom.Matrix3D;
import openfl.geom.Rectangle;
import openfl.Lib;
import openfl.Lib.getTimer;
import openfl.net.URLRequest;
import flare.basic.*;
import flare.core.*;
import flare.materials.*;
import flare.materials.filters.*;
import flare.primitives.*;
import flare.collisions.*;
import flare.loaders.*;
import flare.system.*;
import flare.events.*;
import flare.physics.*;
import flare.physics.colliders.*;
import flare.modifiers.*;
import flare.flsl.*;
import flare.utils.*;
import openfl.display.*;
import openfl.display3D.*;
import openfl.geom.*;
import openfl.utils.*;

/**
 * Test40_RenderToBitmapData
 * Demonstrates:
 * 1. Desert mountains SkyBox background (skybox2b.png)
 * 2. Chessboard in main scene
 * 3. Teapot rendered offscreen to BitmapData with transparency using secondCamera
 * 4. 200x200 rotating teapot floating above the main scene at x = 300
 *
 * @author Ariel Nehmad
 */
class Test40_RenderToBitmapData extends Sprite 
{
	private var scene:Scene3D;
	private var teapot:Pivot3D;
	private var chess:Pivot3D;
	
	private var secondCamera:Camera3D;
	
	private var bmp:BitmapData;
	private var _renderFrames:Int = 0;
	private var _isLoaded:Bool = false;
	
	public function new() 
	{
		super();
		scene = new Viewer3D( this, null, 0.3 );
		scene.antialias = 2;
		scene.autoResize = true;
		scene.registerClass( ZF3DLoader );
		scene.addEventListener( Scene3D.PROGRESS_EVENT, progressEvent );
		scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
		scene.addChild( new SkyBox( "skybox2b.png", SkyBox.HORIZONTAL_CROSS, scene ) );
		
		chess = scene.addChildFromFile( "chess2.zf3d" );
		teapot = scene.addChildFromFile( "teapot2.zf3d" );
		
		secondCamera = new Camera3D( "secondCamera" );
		secondCamera.viewPort = new Rectangle( 0, 0, 200, 200 );
		secondCamera.z = -100;
		
		bmp = new BitmapData( 200, 200, true, 0x00000000 );
		
		addChild( new Bitmap( bmp ) ).x = 300;
	}
	
	private function progressEvent(e:Event):Void 
	{
		//trace( scene.loadProgress );
	}
	
	private function completeEvent(e:Event):Void 
	{
		trace( "complete" );
		
		teapot.parent = null;
		_isLoaded = true;
		
		scene.addEventListener( Scene3D.RENDER_EVENT, renderEvent );
		scene.addEventListener( Scene3D.POSTRENDER_EVENT, postRenderEvent );
	}
	
	private function renderEvent(e:Event):Void 
	{
		teapot.rotateY( -0.5 );
		
		// if you want to draw with alpha.
		scene.clearColor.setTo( 0, 0, 0 );
		scene.clearColor.w = 0;
		
		// render to bitmap data.
		scene.setupFrame( secondCamera );
		teapot.draw();
		scene.context.drawToBitmapData( bmp );
		
		// clear the frame and setup to draw the main camera frame.
		scene.context.clear();
		scene.setupFrame( scene.camera );
	}

	private function postRenderEvent(e:Event):Void 
	{
		#if sys
		var isAuto = (Sys.getEnv("AUTO_EXIT") != null && StringTools.trim(Sys.getEnv("AUTO_EXIT")) == "1")
			|| (Sys.args().indexOf("--auto-exit") != -1)
			|| (Sys.args().indexOf("auto") != -1)
			|| sys.FileSystem.exists("auto_exit.flag");
		if (isAuto) {
			if (_isLoaded) {
				_renderFrames++;
				if (_renderFrames == 15) {
					saveScreenshot("test40.png");
					Sys.exit(0);
				}
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
			// Composite the 2D floating PIP teapot bitmap onto the backbuffer screenshot
			if (bmp != null) {
				b.copyPixels(bmp, bmp.rect, new Point(300, 0), null, null, true);
				var bmpPng = bmp.encode(bmp.rect, new openfl.display.PNGEncoderOptions());
				if (bmpPng != null) {
					#if sys
					sys.io.File.saveBytes('test40_bmp_raw.png', bmpPng);
					try { sys.io.File.saveBytes('C:/Users/ISAMU/.gemini/antigravity/brain/89de7aff-2951-43d1-91cb-f8ef02f8709c/test40_bmp_raw.png', bmpPng); } catch (e:Dynamic) {}
					#end
				}
			}
			var pngBytes = b.encode(b.rect, new openfl.display.PNGEncoderOptions());
			if (pngBytes != null) {
				#if sys
				sys.io.File.saveBytes(filename, pngBytes);
				try { sys.io.File.saveBytes("C:/Users/ISAMU/.gemini/antigravity/brain/89de7aff-2951-43d1-91cb-f8ef02f8709c/test40_rendered_current.png", pngBytes); } catch (e:Dynamic) {}
				try { sys.io.File.saveBytes("../../" + filename, pngBytes); } catch (e:Dynamic) {}
				try { sys.io.File.saveBytes("../../../" + filename, pngBytes); } catch (e:Dynamic) {}
				#end
			}
		} catch (e:Dynamic) {
			trace("Failed to save screenshot: " + e);
		}
	}
}
