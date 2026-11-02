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
	import flare.system.*;
	import flare.utils.*;
	import openfl.display.*;
	import openfl.events.*;
	
	// [SWF metadata]
	
	/**
	 * Access to the objects of the hierarchy, moving objects, applying transformations.
	 * And applying some crazy factors. Move the car using the UP, DOWN, LEFT and RIGHT keys.
	 * 
	 * @author Ariel Nehamd
	 */
	class Test05_Movements extends Sprite
	{
		private var scene:Scene3D;
		
		private var car:Pivot3D;
		private var carSpeed:Float = 0;
		private var carRotation:Float = 0;
		
		private var whell1:Pivot3D;
		private var whell2:Pivot3D;
		private var whell3:Pivot3D;
		private var whell4:Pivot3D;
		private var whellRotation:Float = 0;
		
		public function new() 
		{
			super();
			// stage configuration.
			if (stage != null) { stage.scaleMode = StageScaleMode.NO_SCALE; stage.align = StageAlign.TOP_LEFT; }
			
			// creates a new 3d scene.
			scene = new Scene3D( this );
			scene.camera = new Camera3D( "myOwnCamera" );
			scene.camera.setPosition( 0, 20, -10 );
			scene.camera.lookAt( 0, 0, 0 );
			
			// add global scene progress and complete events.
			scene.addEventListener( Scene3D.PROGRESS_EVENT, progressEvent );
			scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
			
			// loads the objects.
			car = scene.addChildFromFile( "car.f3d" );
			
			scene.addChildFromFile( "plane.f3d" );
			
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
			
			// this stops the car animation.
			car.stop();
			
			// get access to the front whells.
			whell1 = car.getChildByName( "AXTruck-FLWheel" );
			whell2 = car.getChildByName( "AXTruck-FLWheel001" );
			
			// get access to the back whells.
			whell3 = car.getChildByName( "AXTruck-BLWheel" );
			whell4 = car.getChildByName( "AXTruck-BLWheel001" );
			
			// start to update the scene.
			scene.addEventListener( Scene3D.UPDATE_EVENT, updateEvent );
		}
		
		private function updateEvent(e:Event):Void 
		{
			// translates the car locally. Whatever the rotation is, the car always will move forward.
			if ( Input3D.keyDown( Input3D.UP ) ) carSpeed += 0.1;
			if ( Input3D.keyDown( Input3D.DOWN ) ) carSpeed -= 0.1;
			
			// rotate the car over the y-up axis.
			if ( Input3D.keyDown( Input3D.LEFT ) ) carRotation -= 6;
			if ( Input3D.keyDown( Input3D.RIGHT ) ) carRotation += 6;
			
			// apply some factor to reduce the speed and rotations gradually.
			carSpeed *= 0.9;
			carRotation *= 0.9;
			
			// increment the rotation along the 'x' axis.
			// we uses this, becase we are using absolute rotations for the whell1 and whell2.
			whellRotation += carSpeed * 10;
			
			// for thr front whells, we use absolute rotations.
			whell1.setRotation( whellRotation, carRotation, 0 );
			whell2.setRotation( whellRotation, carRotation, 0 );
			
			// for the back whells we can just rotate them locally.
			whell3.rotateX( carSpeed * 8 );
			whell4.rotateX( carSpeed * 8 );
			
			// rotate the car locally acording the car rotation speed and car speed.
			// and apply some factor to reduce the rotation.
			car.rotateY( carRotation * carSpeed / 20 );
			
			// translate the car along his local z/front direction.
			car.translateZ( carSpeed );
			
			// setup the camera, see Test04.
			Pivot3DUtils.setPositionWithReference( scene.camera, 0, 10, -10, car, 0.2 );
			Pivot3DUtils.lookAtWithReference( scene.camera, 0, 5, 0, car );
		}
	}
