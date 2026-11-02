package examples;

import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.ProgressEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;
import flare.basic.Scene3D;
import flare.basic.Viewer3D;
import flare.core.Camera3D;
import flare.loaders.Flare3DLoader;
import flare.system.Input3D;

/**
 * @author Ariel Nehmad
 */
class Test58_LoadingAndDisposingModels extends Sprite 
{
	private var scene:Scene3D;
	private var current:Flare3DLoader;
	private var info:TextField;
	private var _autoStep:Int = 0;
	private var _autoFrames:Int = 0;
	
	public function new() 
	{
		super();
		scene = new Viewer3D( this );
		scene.autoResize = true;
		scene.camera = new Camera3D();
		scene.camera.setPosition( 100, 150, -200 );
		scene.camera.lookAt( 0, 0, 0 );
		scene.addEventListener( Scene3D.UPDATE_EVENT, updateEvent );
		scene.addEventListener( Scene3D.POSTRENDER_EVENT, postRenderEvent );
		
		info = new TextField();
		info.selectable = false;
		info.defaultTextFormat = new TextFormat( "tahoma", 18, 0xffffff, true );
		info.autoSize = "left";
		info.text = "Press 1, 2 or 3 to load each model.";
		addChild( info );

		#if sys
		var isAuto = (Sys.getEnv("AUTO_EXIT") != null && StringTools.trim(Sys.getEnv("AUTO_EXIT")) == "1")
			|| (Sys.args().indexOf("--auto-exit") != -1)
			|| (Sys.args().indexOf("auto") != -1)
			|| sys.FileSystem.exists("auto_exit.flag");
		if (isAuto) {
			// Start automated sequence: load Vaca first
			loadNewModel( "Vaca", "vaca.zf3d" );
		}
		#end
	}
	
	private function updateEvent(e:Event):Void 
	{
		if ( Input3D.keyHit( Input3D.NUMBER_1 ) )
			loadNewModel( "Vaca", "vaca.zf3d" );
		if ( Input3D.keyHit( Input3D.NUMBER_2 ) )
			loadNewModel( "Planet", "planet.zf3d" );
		if ( Input3D.keyHit( Input3D.NUMBER_3 ) )
			loadNewModel( "Chess", "chess.zf3d" );
	}
	
	private function loadNewModel( name:String, url:String ):Void
	{
		if (current != null) {
			current.close();
			current.dispose();
		}
		
		current = new Flare3DLoader( url );
		current.name = name;
		current.addEventListener( ProgressEvent.PROGRESS, progressEvent );
		current.load();
		current.parent = scene;
		
		info.text = "Loading model: " + current.name;
	}
	
	private function progressEvent(e:ProgressEvent):Void 
	{
		info.text = Std.int( e.bytesLoaded * 100 / (e.bytesTotal > 0 ? e.bytesTotal : 1) ) + "% of model: " + current.name;
	}

	private function postRenderEvent(e:Event):Void 
	{
		#if sys
		var isAuto = (Sys.getEnv("AUTO_EXIT") != null && StringTools.trim(Sys.getEnv("AUTO_EXIT")) == "1")
			|| (Sys.args().indexOf("--auto-exit") != -1)
			|| (Sys.args().indexOf("auto") != -1)
			|| sys.FileSystem.exists("auto_exit.flag");
		if (isAuto) {
			_autoFrames++;
			if (_autoStep == 0) {
				if (_autoFrames == 3) {
					saveScreenshot("test58_vaca_frame0.png");
				} else if (_autoFrames == 12) {
					saveScreenshot("test58_vaca_frame10.png");
				} else if (_autoFrames == 22) {
					saveScreenshot("test58_vaca_frame20.png");
				} else if (_autoFrames >= 30) {
					// Step 1: Dispose Vaca and load Planet
					_autoStep = 1;
					_autoFrames = 0;
					loadNewModel( "Planet", "planet.zf3d" );
				}
			} else if (_autoStep == 1 && _autoFrames >= 20) {
				saveScreenshot("test58_planet.png");
				// Step 2: Dispose Planet and load Chess
				_autoStep = 2;
				_autoFrames = 0;
				loadNewModel( "Chess", "chess.zf3d" );
			} else if (_autoStep == 2 && _autoFrames >= 20) {
				saveScreenshot("test58_chess.png");
				saveScreenshot("test58.png");
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
