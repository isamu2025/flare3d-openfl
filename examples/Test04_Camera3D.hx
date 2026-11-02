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
	 * The camera and pivot utils. Press UP; DOWN; LEFT and RIGHT to move the car.
	 * 
	 * @author Ariel Nehamd
	 */
	class Test04_Camera3D extends Sprite
	{
		private var scene:Scene3D;
		private var car:Pivot3D;
		private var axis:Pivot3D;
		private var floor:Pivot3D;
		
		public function new() 
		{
			super();
			// stage configuration.
			if (stage != null) { stage.scaleMode = StageScaleMode.NO_SCALE; stage.align = StageAlign.TOP_LEFT; }
			
			// creates a new 3d scene.
			scene = new Scene3D( this );
			
			// see comments on test02.
			scene.camera = new Camera3D( "myOwnCamera" );
			scene.camera.setPosition( -20, 20, -20 );
			scene.camera.lookAt( 0, 0, 0 );
			
			// add global scene progress and complete events.
			scene.addEventListener( Scene3D.PROGRESS_EVENT, progressEvent );
			scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
			
			// loads the objects.
			car = scene.addChildFromFile( "car.f3d" );
			axis = scene.addChildFromFile( "axis.f3d" );
			floor = scene.addChildFromFile( "plane.f3d" );
			
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
			scene.addEventListener( Scene3D.UPDATE_EVENT, updateEvent );
		}
		
		private function updateEvent(e:Event):Void 
		{
			// translates the car locally. Whatever the rotation is, the car always will move forward.
			if ( Input3D.keyDown( Input3D.UP ) ) car.translateZ( 1 );
			if ( Input3D.keyDown( Input3D.DOWN ) ) car.translateZ( -1 );
			
			// rotate the car over the y-up axis.
			if ( Input3D.keyDown( Input3D.LEFT ) ) car.rotateY( -3 );
			if ( Input3D.keyDown( Input3D.RIGHT ) ) car.rotateY( 3 );
			
			// this is an easy way to implement a camara that follows the car.
			// this two methods help us to set the position and orienttion of the certain object relative to another.
			// we want to set the position of the camera back to the car, and a bit on top of it, but always relative to the car.
			// the optional 'smooth' parameter is an interpolation value between the last position and the new position we want to move.
			// applying it every frame, we get a similar tween effect, but only works because we are updateing the camera position every frame.
			// if we not set any smooth value (or set to 1), we'll get a rigid movement.
			Pivot3DUtils.setPositionWithReference( scene.camera, 0, 20, -30, car, 0.025 );
			
			// the next line, point the camera to relative center of the car, that is his (0,0,0).
			// but wathever the camera position is, it always will point to the center (or required values) of the car.
			Pivot3DUtils.lookAtWithReference( scene.camera, 0, 0, 0, car );
		}
	}
