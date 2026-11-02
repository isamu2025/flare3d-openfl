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

import flare.basic.*;
	import flare.core.*;
	import flare.loaders.*;
	import flare.system.*;
	import openfl.display.*;
	import openfl.events.*;
	
	// [SWF metadata]
	
	/**
	 * The basics, easy! Drag to look around.
	 * 
	 * @author Ariel Nehamd
	 */
	class Test01_The_Basics1 extends Sprite
	{
		private var scene:Scene3D;
		private var car:Pivot3D;
		private var axis:Pivot3D;
		
		public function new() 
		{
			super();
			// creates a new 3d scene.
			scene = new Viewer3D( this );
			scene.autoResize = true;
			
			// add global scene progress and complete events.
			scene.addEventListener( Scene3D.PROGRESS_EVENT, progressEvent );
			scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
			
			// loads the objects.
			car = scene.addChildFromFile( "car.f3d" );
			axis = scene.addChildFromFile( "axis.f3d" );
		}
		
		private function progressEvent(e:Event):Void 
		{
			// gets the global loading progress.
			trace( scene.loadProgress );
		}
		
		private function completeEvent(e:Event):Void 
		{
			trace( "complete!" );
			
			// just scale the model.
			if (axis != null) {
				axis.setScale( 0.5, 0.5, 0.5 );
			}
			if (car != null) {
				car.play(true);
			}
		}
	}
