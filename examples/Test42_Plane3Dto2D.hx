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
import openfl.display.*;
import openfl.events.*;

/**
 * This example shows how to convert 3D units to 2D pixel units relative to any camera.
 * @author Ariel Nehmad
 */
class Test42_Plane3Dto2D extends Sprite 
{
	private var scene:Scene3D;
	private var plane:Plane;
	private var planePixelsHeight:Int;
	private var planePixelsWidth:Int;
	private var _renderFrames:Int = 0;

	public function new() 
	{
		super();
		scene = new Scene3D( this );
		scene.camera = new Camera3D( "", 90 );
		scene.autoResize = true;
		
		planePixelsWidth = 450;
		planePixelsHeight = 350;
		
		plane = new Plane( "plane", planePixelsWidth, planePixelsHeight );
		scene.addChild( plane );
		
		scene.addEventListener( Scene3D.POSTRENDER_EVENT, postRenderEvent );

		if (stage != null) init();
		else
			addEventListener( Event.ADDED_TO_STAGE, init );
	}
	
	private function init( e:Event = null ):Void
	{
		removeEventListener( Event.ADDED_TO_STAGE, init );
		
		stage.addEventListener( Event.RESIZE, resizeStageEvent );
		resizeStageEvent();
	}
	
	private function resizeStageEvent( e:Event = null ):Void 
	{
		// this is the magic distance from the plane to the camera.
		// here we are just moving the plane far from the camera, but is the same thing moving the camera backward
		// using a negative value.
		if (stage != null && scene.camera != null) {
			scene.camera.z = -0.5 / scene.camera.zoom * stage.stageWidth;
			
			// just draws the rectangle on the screen to compare against the 3d plane.
			graphics.clear();
			graphics.lineStyle( 2, 0xff0000 );
			graphics.drawRect( stage.stageWidth * 0.5 - planePixelsWidth * 0.5, 
							   stage.stageHeight * 0.5 - planePixelsHeight * 0.5, 
							   planePixelsWidth, 
							   planePixelsHeight);
		}
	}

	private function postRenderEvent(e:Event):Void 
	{
		#if sys
		var isAuto = (Sys.getEnv("AUTO_EXIT") != null && StringTools.trim(Sys.getEnv("AUTO_EXIT")) == "1")
			|| (Sys.args().indexOf("--auto-exit") != -1)
			|| (Sys.args().indexOf("auto") != -1)
			|| sys.FileSystem.exists("auto_exit.flag");
		if (isAuto) {
			_renderFrames++;
			if (_renderFrames >= 15) {
				saveScreenshot("test42.png");
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
			var b = new openfl.display.BitmapData(w, h, false, 0x000000);
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
		} catch (e:Dynamic) {
			trace("Failed to save screenshot: " + e);
		}
	}
}
