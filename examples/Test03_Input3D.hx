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
	import openfl.display.*;
	import openfl.events.*;
	
	// [SWF metadata]
	
	/**
	 * The Input3D Class. Press UP, DOWN, LEFT and RIGHT to move the car and 'R' to reset to the original position.
	 * 
	 * @author Ariel Nehamd
	 */
	class Test03_Input3D extends Sprite
	{
		private var scene:Scene3D;
		private var car:Pivot3D;
		private var axis:Pivot3D;
		
		public function new() 
		{
			super();
			// stage configuration.
			if (stage != null) { stage.scaleMode = StageScaleMode.NO_SCALE; stage.align = StageAlign.TOP_LEFT; }
			
			// creates a new 3d scene.
			scene = new Viewer3D( this );
			scene.camera = new Camera3D( "myOwnCamera" );
			scene.camera.setPosition( -20, 20, -20 );
			scene.camera.lookAt( 0, 0, 0 );
			
			// add global scene progress and complete events.
			scene.addEventListener( Scene3D.PROGRESS_EVENT, progressEvent );
			scene.addEventListener( Scene3D.COMPLETE_EVENT, completeEvent );
			
			// loads the objects.
			car = scene.addChildFromFile( "car.f3d" );
			axis = scene.addChildFromFile( "axis.f3d" );
			
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
			if ( Input3D.keyDown( Input3D.UP ) ) car.translateZ( 0.5 );
			if ( Input3D.keyDown( Input3D.DOWN ) ) car.translateZ( -0.5 );
			
			// rotate the car over the y-up axis.
			if ( Input3D.keyDown( Input3D.LEFT ) ) car.rotateY( -3 );
			if ( Input3D.keyDown( Input3D.RIGHT ) ) car.rotateY( 3 );
			
			// different from keyDown, keyHit returns 'true' only once,
			// after the key is pressed it will return 'false' until the key is released again.
			if ( Input3D.keyHit( Input3D.R ) )
			{
				// just reset the car position and rotation.
				car.setPosition( 0, 0, 0 );
				car.setRotation( 0, 0, 0 );
			}
		}
	}
