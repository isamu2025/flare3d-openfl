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
	import openfl.display.*;
	import openfl.events.*;
	
	// [SWF metadata]
	
	/**
	 * The basics 2. Drag to look around.
	 * 
	 * @author Ariel Nehamd
	 */
	class Test02_The_Basics2 extends Sprite
	{
		private var scene:Scene3D;
		private var car:Pivot3D;
		private var axis:Pivot3D;
		
		public function new() 
		{
			super();
			// stage configuration.
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			// creates a new 3d scene.
			scene = new Viewer3D( this );
			
			// if we do not create a camera, flare3d will use the first camera that his found on loaded files. 
			// if the camera is loaded with a loaded object, usually will be parented to that model (it may contain animations, 
			// or references to another objects to), and if we try to move the object, the camera wiil move with the object too, an you will
			// see nothing moving. To prevent this, we simply can create and manage an own camera.
			scene.camera = new Camera3D( "myOwnCamera" );
			
			// we can manipulate the camera just like any 3d object.
			scene.camera.setPosition( 0, 10, -20 );
			scene.camera.lookAt( 0, 0, 0 );
			
			// add global scene progress and complete events.
			scene.addEventListener( Scene3D.PROGRESS_EVENT, progressEvent );
			scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
			
			// loads the objects.
			car = scene.addChildFromFile( "car.f3d" );
			axis = scene.addChildFromFile( "axis.f3d" );
			
			// the previous addChildFromFile method returns an empty 3d obejct (Pivot3D), and all the content will be loaded inside.
			// while the content is loading, we can not access to the inside objects, but we can apply
			// some transformation such as position, scale or rotation to the empty container.
			// so, we can do this here before the axis model is loaded.
			axis.setScale( 0.5, 0.5, 0.5 );
			
			// this prevents to flare3d to start render before the objects are completly loaded.
			scene.pause();
		}
		
		private function progressEvent(e:Event):Void 
		{
			// gets the global loading progress.
			trace( scene.loadProgress );
		}
		
		private function completeEvent(e:Event):Void 
		{
			// once the scene has been loaded, resume the render.
			scene.resume();
			if (car != null) car.play(true);
			
			// start to update the scene.
			// the update event is like the enterFrame of Flare3D, but it is synchronized with the time
			// and it is dispatched constantly at scene.frameRate property. (by default is 45).
			scene.addEventListener( Scene3D.UPDATE_EVENT, updateEvent );
		}
		
		private function updateEvent(e:Event):Void 
		{
			// simply rotate the model on 'y/up' axis every frame.
			car.rotateY(2);
		}
	}
