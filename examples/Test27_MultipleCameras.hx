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
	import openfl.geom.*;
	
	// [SWF metadata]
	
	/**
	 * Multiple cameras test.
	 * 
	 * @author Ariel Nehmad
	 */
	class Test27_MultipleCameras extends Sprite 
	{
		private var scene:Scene3D;
		private var secondCamera:Camera3D;
		private var model:Pivot3D;
		
		public function new() 
		{
			super();
			if (stage != null) {
				stage.align = StageAlign.TOP_LEFT;
				stage.scaleMode = StageScaleMode.NO_SCALE;
				stage.addEventListener( Event.RESIZE, resizeStageEvent );
			} else {
				addEventListener( Event.ADDED_TO_STAGE, onAddedToStage );
			}
			
			scene = new Viewer3D(this);
			scene.camera = new Camera3D( "mainCamera" );
			scene.camera.setPosition( 0, 100, -100 );
			scene.camera.lookAt( 0, 40, 0 );
			
			model = scene.addChildFromFile( "map.f3d" );
			
			// creates the second camera.
			secondCamera = new Camera3D( "second camera", 60 );
			secondCamera.viewPort = new Rectangle( 20, 20, 250, 150 );
			
			// we need to draw the caemra in postRender event because the render method will
			// also dispatch the render event.
			scene.addEventListener( Scene3D.POSTRENDER_EVENT, postRenderEvent );
			scene.addEventListener( Scene3D.UPDATE_EVENT, updateEvent );
		}
		
		private function onAddedToStage(e:Event):Void 
		{
			removeEventListener( Event.ADDED_TO_STAGE, onAddedToStage );
			if (stage != null) {
				stage.align = StageAlign.TOP_LEFT;
				stage.scaleMode = StageScaleMode.NO_SCALE;
				stage.addEventListener( Event.RESIZE, resizeStageEvent );
			}
		}
		
		private function resizeStageEvent(e:Event):Void 
		{
			if (stage != null) {
				scene.setViewport( 0, 0, stage.stageWidth, stage.stageHeight );
			}
		}
		
		private function updateEvent(e:Event):Void 
		{
			// just for fun :)
			secondCamera.setPosition( 0, 40, 0 );
			secondCamera.rotateY( 0.5 );
		}
		
		private function postRenderEvent(e:Event):Void 
		{
			graphics.clear();
			graphics.lineStyle( 1, 0xff0000 );
			graphics.drawRect( 20, 20, 250, 150 );
			
			// here we draw the other cameras.
			scene.render( secondCamera, true );
		}
	}
