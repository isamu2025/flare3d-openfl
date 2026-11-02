package examples;

import openfl.display.Sprite;
import openfl.events.Event;
import flare.basic.Scene3D;
import flare.basic.Viewer3D;
import flare.core.Camera3D;
import flare.core.Pivot3D;
import flare.system.Input3D;

/**
 * Clones! The attack of the cloned cows.
 * 
 * @author Ariel Nehmad
 */
class Test07_Clones extends Sprite 
{
	private var scene:Scene3D;		
	private var model:Pivot3D;
	
	public function new() 
	{
		super();
		flare.system.DebugLog.log("[Test07_Clones] new() started");
		// creates and load the scene.
		scene = new Viewer3D( this );
		scene.autoResize = true;
		scene.skipFrames = false;
		scene.pause();
		
		scene.addEventListener( Scene3D.PROGRESS_EVENT, progressEvent );
		scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
		
		model = scene.addChildFromFile( "vaca.zf3d" );
	}
	
	private function progressEvent(e:Event):Void 
	{
		trace( scene.loadProgress );
	}
	
	private function completeEvent(e:Event):Void 
	{
		trace( "complete" );
		
		var count:Int = 20;
		
		for (h in 0...count)
		{
			for (v in 0...count)
			{
				var space:Float = 240;
				var cloned:Pivot3D = model.clone();
				cloned.x = h * space - space * count / 2;
				cloned.z = v * space - space * count / 2;
				// when some models share the same frame, it could be much faster.
				// also sorting skinned models into layers could optimize the render and reuse information.
				// this is the worst case, when all models have different and random frames and frameRates.
				cloned.frameSpeed = Math.random() + 0.5;
				// this is the same as scene.addChild();
				cloned.parent = scene;
			}
		}
		
		// camera position and orientation.
		scene.camera = new Camera3D( "CloneViewCamera", 45 );
		scene.camera.setPosition( 1000, 1000, 1000 );
		scene.camera.lookAt( 0, 0, 0 );
		scene.camera.far = 15000;
		if (Std.isOfType(scene, Viewer3D)) {
			var v:Viewer3D = cast scene;
			v.target.setTo(0, 0, 0);
			v.syncOrbitFromCamera();
		}
		
		scene.play();
		
		// remove the original and father of all clones.
		scene.removeChild( model );			
		scene.addEventListener( Scene3D.UPDATE_EVENT, updateEvent );
		scene.resume();
	}
	
	private function updateEvent(e:Event):Void 
	{
		if ( Input3D.keyHit( Input3D.P ) ) scene.play();
		if ( Input3D.keyHit( Input3D.S ) ) scene.stop();
	}		
}
