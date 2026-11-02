package examples;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.Vector3D;
import openfl.geom.Point;
import flare.basic.*;
import flare.core.*;
import flare.primitives.*;
import flare.system.*;

/**
 * @author Ariel Nehmad
 */
class Test48_Particles extends Sprite 
{
	private var scene:Scene3D;
	private var particles:Particles3D;
	private var cloned:Particles3D;
	private var _renderFrames:Int = 0;
	
	public function new() 
	{
		super();
		scene = new Viewer3D( this );
		scene.camera.setPosition( 0, 100, -120 );
		scene.camera.lookAt( 0, 0, 0 );
		scene.autoResize = true;
		scene.skipFrames = false;
		
		particles = new Particles3D();
		particles.texture = new Texture3D( "smoke_particle.png" );
		particles.parent = scene;
		particles.setColors( [0xffffff, 0xff0000], [0, 255] );
		particles.randomSpin = 20;
		particles.endSize = new Point();
		particles.worldPositions = true;
		particles.worldVelocities = true;
		particles.addChild( new Cube("", 5, 5, 5 ) );
		
		cloned = cast(particles.clone(), Particles3D);
		cloned.setColors( [0xffff00], [0] );
		cloned.blendMode = Particles3D.BLEND_SCREEN;
		cloned.duration = 0.5;
		cloned.loops = 1;
		cloned.randomVelocity = 100;
		cloned.velocity = new Vector3D( 0, 100, 0 );
		cloned.gravity = new Vector3D( 0, -50, 0 );
		cloned.delay = 0.5;
		cloned.x = -50;
		cloned.parent = scene;
		
		scene.addEventListener( Scene3D.UPDATE_EVENT, updateEvent );
		scene.addEventListener( Scene3D.POSTRENDER_EVENT, postRenderEvent );
	}
	
	private function updateEvent(e:Event):Void 
	{
		if ( Input3D.keyHit( Input3D.SPACE ) )
			cloned.start();
			
		if ( Input3D.keyHit( Input3D.P ) )
			if ( !particles.paused )
				particles.pause();
			else
				particles.resume();
			
		if ( Input3D.keyDown( Input3D.A ) )
			cloned.x -= 3;
		if ( Input3D.keyDown( Input3D.D ) )
			cloned.x += 3;
		if ( Input3D.keyDown( Input3D.W ) )
			cloned.z += 3;
		if ( Input3D.keyDown( Input3D.S ) )
			cloned.z -= 3;
			
		if ( Input3D.keyDown( Input3D.LEFT ) )
			particles.x -= 3;
		if ( Input3D.keyDown( Input3D.RIGHT ) )
			particles.x += 3;
		if ( Input3D.keyDown( Input3D.UP ) )
			particles.z += 3;
		if ( Input3D.keyDown( Input3D.DOWN ) )
			particles.z -= 3;
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
			if (_renderFrames == 5) {
				cloned.start();
			}
			if (_renderFrames >= 45) {
				saveScreenshot("test48.png");
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
